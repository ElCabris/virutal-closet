import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../firebase/mappers.dart';
import '../models/garment.dart';
import '../models/outfit.dart';

class OutfitRepository {
  OutfitRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  String get _userId => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _outfits =>
      _db.collection('users').doc(_userId).collection('outfits');

  CollectionReference<Map<String, dynamic>> get _garments =>
      _db.collection('users').doc(_userId).collection('garments');

  CollectionReference<Map<String, dynamic>> get _calendar =>
      _db.collection('users').doc(_userId).collection('calendar');

  Future<List<Outfit>> getOutfits({String? occasion}) async {
    final snap = await _outfits.orderBy('createdAt', descending: true).get();
    final wardrobe = await _wardrobeById();
    final outfits = snap.docs.map((doc) {
      final ids = List<String>.from(doc.data()['garmentIds'] ?? const []);
      return outfitFromDoc(
        doc,
        garments: [
          for (final id in ids)
            if (wardrobe.containsKey(id)) wardrobe[id]!,
        ],
      );
    }).toList();
    if (occasion == null || occasion == 'All') return outfits;
    return outfits.where((o) => o.occasion == occasion).toList();
  }

  Future<Outfit> getOutfit(String id) async {
    final doc = await _outfits.doc(id).get();
    if (!doc.exists) {
      throw StateError('Outfit $id was not found');
    }
    final wardrobe = await _wardrobeById();
    final ids = List<String>.from(doc.data()?['garmentIds'] ?? const []);
    return outfitFromDoc(
      doc,
      garments: [
        for (final garmentId in ids)
          if (wardrobe.containsKey(garmentId)) wardrobe[garmentId]!,
      ],
    );
  }

  Future<Outfit> createOutfit({
    required String name,
    required List<String> garmentIds,
    String? occasion,
    String? season,
    String? notes,
  }) async {
    final id = _uuid.v4();
    await _outfits.doc(id).set({
      'userId': _userId,
      'name': name,
      'garmentIds': garmentIds,
      'occasion': occasion,
      'season': season,
      'notes': notes,
      'wearCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return getOutfit(id);
  }

  Future<Outfit> updateOutfit(String id, Map<String, dynamic> updates) async {
    final mapped = <String, dynamic>{
      for (final entry in updates.entries)
        _fieldName(entry.key): entry.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _outfits.doc(id).update(mapped);
    return getOutfit(id);
  }

  Future<void> deleteOutfit(String id) async {
    final entries = await _calendar.where('outfitId', isEqualTo: id).get();
    final batch = _db.batch();
    for (final doc in entries.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_outfits.doc(id));
    await batch.commit();
  }

  Future<Map<String, Garment>> _wardrobeById() async {
    final snap = await _garments.get();
    final garments = await Future.wait(snap.docs.map(garmentFromDoc));
    return {for (final garment in garments) garment.id: garment};
  }

  String _fieldName(String key) {
    switch (key) {
      case 'garment_ids':
        return 'garmentIds';
      case 'wear_count':
        return 'wearCount';
      case 'last_worn':
        return 'lastWorn';
      case 'image_url':
        return 'imageUrl';
      default:
        return key;
    }
  }
}
