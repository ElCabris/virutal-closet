import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firebase/mappers.dart';
import '../models/calendar_entry.dart';
import '../models/garment.dart';
import '../models/outfit.dart';

class CalendarRepository {
  CalendarRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _userId => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _calendar =>
      _db.collection('users').doc(_userId).collection('calendar');

  CollectionReference<Map<String, dynamic>> get _outfits =>
      _db.collection('users').doc(_userId).collection('outfits');

  CollectionReference<Map<String, dynamic>> get _garments =>
      _db.collection('users').doc(_userId).collection('garments');

  Future<List<CalendarEntry>> getEntriesForMonth(int year, int month) async {
    final start = _dateId(DateTime(year, month, 1));
    final end = _dateId(DateTime(year, month + 1, 0));
    final snap = await _calendar
        .orderBy(FieldPath.documentId)
        .startAt([start])
        .endAt([end])
        .get();
    return Future.wait(snap.docs.map(_entryFromDoc));
  }

  /// Number of days from today onwards that have an outfit assigned.
  Future<int> countUpcomingEntries() async {
    final snap = await _calendar
        .orderBy(FieldPath.documentId)
        .startAt([_dateId(DateTime.now())])
        .get();
    return snap.size;
  }

  Future<CalendarEntry?> getEntryForDate(DateTime date) async {
    final doc = await _calendar.doc(_dateId(date)).get();
    if (!doc.exists) return null;
    return _entryFromDoc(doc, includeGarments: true);
  }

  Future<CalendarEntry> setOutfitForDate({
    required DateTime date,
    required String outfitId,
    String? notes,
  }) async {
    final id = _dateId(date);
    final ref = _calendar.doc(id);
    final existing = await ref.get();
    if (existing.exists) {
      await ref.update({
        'outfitId': outfitId,
        'notes': notes,
      });
    } else {
      await ref.set({
        'userId': _userId,
        'outfitId': outfitId,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return (await getEntryForDate(date))!;
  }

  /// Records [outfitId] as worn on [date], counting a wear on the outfit and
  /// its garments. Does nothing if it is already recorded for that day; a
  /// different outfit worn that day is replaced and its wear undone.
  Future<void> markWorn({
    required DateTime date,
    required String outfitId,
  }) {
    final ref = _calendar.doc(_dateId(date));
    final day = _dayTimestamp(date);
    return _db.runTransaction((tx) async {
      final entrySnap = await tx.get(ref);
      final entry = entrySnap.data();
      if (entry?['worn'] == true && entry?['outfitId'] == outfitId) return;

      final outfitRef = _outfits.doc(outfitId);
      final outfitSnap = await tx.get(outfitRef);
      if (!outfitSnap.exists) {
        throw StateError('Outfit $outfitId was not found');
      }

      final ledger = _WearLedger(tx);
      await _undoWear(ledger, entry, day);
      final garmentIds =
          List<String>.from(outfitSnap.data()?['garmentIds'] ?? const []);
      final previousGarments = <String, Timestamp?>{};
      for (final id in garmentIds) {
        final state = await ledger.load(_garments.doc(id));
        if (state == null) continue;
        previousGarments[id] = state.lastWorn;
        state.addWear(day);
      }
      final outfitState = (await ledger.load(outfitRef))!;
      final previousOutfit = outfitState.lastWorn;
      outfitState.addWear(day);
      ledger.commit();

      final fields = <String, dynamic>{
        'outfitId': outfitId,
        'worn': true,
        // Lets the wear be undone exactly, even if the outfit changes later.
        'wear': {'outfit': previousOutfit, 'garments': previousGarments},
      };
      if (entrySnap.exists) {
        tx.update(ref, fields);
      } else {
        tx.set(ref, {
          ...fields,
          'userId': _userId,
          'notes': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Removes the day's entry, undoing its wear if it was recorded as worn.
  Future<void> removeEntryForDate(DateTime date) {
    final ref = _calendar.doc(_dateId(date));
    return _db.runTransaction((tx) async {
      final entry = (await tx.get(ref)).data();
      final ledger = _WearLedger(tx);
      await _undoWear(ledger, entry, _dayTimestamp(date));
      ledger.commit();
      tx.delete(ref);
    });
  }

  Future<void> _undoWear(
    _WearLedger ledger,
    Map<String, dynamic>? entry,
    Timestamp day,
  ) async {
    if (entry?['worn'] != true) return;
    final wear = Map<String, dynamic>.from(entry?['wear'] as Map? ?? const {});
    final garments = Map<String, dynamic>.from(wear['garments'] as Map? ?? const {});
    for (final item in garments.entries) {
      final state = await ledger.load(_garments.doc(item.key));
      state?.removeWear(day, previous: item.value as Timestamp?);
    }
    final outfitId = entry?['outfitId'] as String? ?? '';
    if (outfitId.isEmpty) return;
    final state = await ledger.load(_outfits.doc(outfitId));
    state?.removeWear(day, previous: wear['outfit'] as Timestamp?);
  }

  Timestamp _dayTimestamp(DateTime date) =>
      Timestamp.fromDate(DateTime(date.year, date.month, date.day));

  Future<CalendarEntry> _entryFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    bool includeGarments = false,
  }) async {
    final data = doc.data() ?? {};
    final outfitId = data['outfitId'] as String? ?? '';
    Outfit? outfit;
    if (outfitId.isNotEmpty) {
      final outfitDoc = await _outfits.doc(outfitId).get();
      if (outfitDoc.exists) {
        outfit = outfitFromDoc(
          outfitDoc,
          garments: includeGarments ? await _garmentsOf(outfitDoc) : const [],
        );
      }
    }
    final createdAt = firestoreDate(data['createdAt']) ?? DateTime.now();
    return CalendarEntry(
      id: doc.id,
      userId: data['userId'] as String? ?? _userId,
      outfitId: outfitId,
      outfit: outfit,
      date: DateTime.parse(doc.id),
      notes: data['notes'] as String?,
      worn: data['worn'] == true,
      createdAt: createdAt,
    );
  }

  Future<List<Garment>> _garmentsOf(
    DocumentSnapshot<Map<String, dynamic>> outfitDoc,
  ) async {
    final ids = List<String>.from(outfitDoc.data()?['garmentIds'] ?? const []);
    final docs = await Future.wait(ids.map((id) => _garments.doc(id).get()));
    return Future.wait(docs.where((d) => d.exists).map(garmentFromDoc));
  }

  String _dateId(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _WearState {
  _WearState(this.count, this.lastWorn);

  int count;
  Timestamp? lastWorn;

  void addWear(Timestamp day) {
    count++;
    final current = lastWorn;
    if (current == null || current.compareTo(day) < 0) lastWorn = day;
  }

  /// [previous] is what lastWorn was before the wear on [day]. A later wear
  /// makes lastWorn differ from [day], and then it must stay as it is.
  void removeWear(Timestamp day, {required Timestamp? previous}) {
    if (count > 0) count--;
    if (lastWorn == day) lastWorn = previous;
  }
}

/// Keeps the wear counters a transaction touches in memory and writes each
/// document once: a garment can belong to both the outfit being replaced and
/// the new one. Reads must happen before [commit], as Firestore requires.
class _WearLedger {
  _WearLedger(this._tx);

  final Transaction _tx;
  final _states = <DocumentReference<Map<String, dynamic>>, _WearState?>{};

  Future<_WearState?> load(DocumentReference<Map<String, dynamic>> ref) async {
    if (_states.containsKey(ref)) return _states[ref];
    final snap = await _tx.get(ref);
    final data = snap.data();
    return _states[ref] = snap.exists
        ? _WearState(
            (data?['wearCount'] as num?)?.toInt() ?? 0,
            data?['lastWorn'] as Timestamp?,
          )
        : null;
  }

  void commit() {
    _states.forEach((ref, state) {
      if (state == null) return;
      _tx.update(ref, {
        'wearCount': state.count,
        'lastWorn': state.lastWorn,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
