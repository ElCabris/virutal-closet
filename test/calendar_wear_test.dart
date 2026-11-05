import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_closet/data/repositories/calendar_repository.dart';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'u';
}

class _FakeAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _FakeUser();
}

void main() {
  late FakeFirebaseFirestore db;
  late CalendarRepository repo;
  final day = DateTime(2026, 11, 3);
  final dayTs = Timestamp.fromDate(day);

  DocumentReference<Map<String, dynamic>> doc(String collection, String id) =>
      db.collection('users').doc('u').collection(collection).doc(id);

  Future<Map<String, dynamic>> read(String collection, String id) async =>
      (await doc(collection, id).get()).data()!;

  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = CalendarRepository(firestore: db, auth: _FakeAuth());
    await doc('garments', 'shirt').set({'wearCount': 2});
    await doc('garments', 'pants').set({'wearCount': 0});
    await doc('garments', 'shoes').set({'wearCount': 0});
    await doc('outfits', 'a').set({
      'wearCount': 0,
      'garmentIds': ['shirt', 'pants'],
    });
    await doc('outfits', 'b').set({
      'wearCount': 0,
      'garmentIds': ['shirt', 'shoes'],
    });
  });

  test('counts a wear on the outfit and its garments', () async {
    await repo.markWorn(date: day, outfitId: 'a');

    expect((await read('outfits', 'a'))['wearCount'], 1);
    expect((await read('outfits', 'a'))['lastWorn'], dayTs);
    expect((await read('garments', 'shirt'))['wearCount'], 3);
    expect((await read('garments', 'pants'))['wearCount'], 1);
    expect((await read('calendar', '2026-11-03'))['worn'], isTrue);
  });

  test('marking the same outfit twice counts once', () async {
    await repo.markWorn(date: day, outfitId: 'a');
    await repo.markWorn(date: day, outfitId: 'a');

    expect((await read('outfits', 'a'))['wearCount'], 1);
    expect((await read('garments', 'shirt'))['wearCount'], 3);
  });

  test('replacing the outfit moves the wear and handles shared garments',
      () async {
    await repo.markWorn(date: day, outfitId: 'a');
    await repo.markWorn(date: day, outfitId: 'b');

    expect((await read('outfits', 'a'))['wearCount'], 0);
    expect((await read('outfits', 'a'))['lastWorn'], isNull);
    expect((await read('outfits', 'b'))['wearCount'], 1);
    expect((await read('garments', 'shirt'))['wearCount'], 3);
    expect((await read('garments', 'pants'))['wearCount'], 0);
    expect((await read('garments', 'shoes'))['wearCount'], 1);
  });

  test('removing a worn entry restores counts and last worn', () async {
    final earlier = Timestamp.fromDate(DateTime(2026, 10, 1));
    await doc('garments', 'shirt').update({'lastWorn': earlier});

    await repo.markWorn(date: day, outfitId: 'a');
    await repo.removeEntryForDate(day);

    expect((await read('garments', 'shirt'))['wearCount'], 2);
    expect((await read('garments', 'shirt'))['lastWorn'], earlier);
    expect((await read('garments', 'pants'))['lastWorn'], isNull);
    expect((await read('outfits', 'a'))['wearCount'], 0);
    expect((await doc('calendar', '2026-11-03').get()).exists, isFalse);
  });

  test('a past wear does not move last worn backwards', () async {
    final later = Timestamp.fromDate(DateTime(2026, 11, 4));
    await doc('garments', 'shirt').update({'lastWorn': later});

    await repo.markWorn(date: day, outfitId: 'a');
    expect((await read('garments', 'shirt'))['lastWorn'], later);

    await repo.removeEntryForDate(day);
    expect((await read('garments', 'shirt'))['lastWorn'], later);
  });

  test('undoing uses the garments worn, even if the outfit changed', () async {
    await repo.markWorn(date: day, outfitId: 'a');
    await doc('outfits', 'a').update({
      'garmentIds': ['shoes'],
    });

    await repo.removeEntryForDate(day);

    expect((await read('garments', 'pants'))['wearCount'], 0);
    expect((await read('garments', 'shoes'))['wearCount'], 0);
  });

  test('skips garments that were deleted', () async {
    await doc('garments', 'pants').delete();

    await repo.markWorn(date: day, outfitId: 'a');

    expect((await read('garments', 'shirt'))['wearCount'], 3);
    expect((await doc('garments', 'pants').get()).exists, isFalse);
  });

  test('removing a planned entry does not touch counts', () async {
    await doc('calendar', '2026-11-03').set({'outfitId': 'a'});
    await repo.removeEntryForDate(day);

    expect((await read('garments', 'shirt'))['wearCount'], 2);
    expect((await read('outfits', 'a'))['wearCount'], 0);
  });
}
