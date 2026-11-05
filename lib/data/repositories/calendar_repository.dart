import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firebase/mappers.dart';
import '../models/calendar_entry.dart';
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
    return _entryFromDoc(doc);
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

  Future<void> removeEntryForDate(DateTime date) async {
    await _calendar.doc(_dateId(date)).delete();
  }

  Future<CalendarEntry> _entryFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data() ?? {};
    final outfitId = data['outfitId'] as String? ?? '';
    Outfit? outfit;
    if (outfitId.isNotEmpty) {
      final outfitDoc = await _outfits.doc(outfitId).get();
      if (outfitDoc.exists) outfit = outfitFromDoc(outfitDoc);
    }
    final createdAt = firestoreDate(data['createdAt']) ?? DateTime.now();
    return CalendarEntry(
      id: doc.id,
      userId: data['userId'] as String? ?? _userId,
      outfitId: outfitId,
      outfit: outfit,
      date: DateTime.parse(doc.id),
      notes: data['notes'] as String?,
      createdAt: createdAt,
    );
  }

  String _dateId(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
