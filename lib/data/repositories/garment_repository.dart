import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/file_utils.dart';
import '../firebase/mappers.dart';
import '../models/garment.dart';

class GarmentRepository {
  GarmentRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  String get _userId => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _garments =>
      _db.collection('users').doc(_userId).collection('garments');

  Future<List<Garment>> getGarments({String? category}) async {
    final snap = await _garments.orderBy('createdAt', descending: true).get();
    final garments = await Future.wait(snap.docs.map(garmentFromDoc));
    if (category == null || category == 'All') return garments;
    return garments.where((g) => g.category == category).toList();
  }

  Future<Garment> getGarment(String id) async {
    final doc = await _garments.doc(id).get();
    if (!doc.exists) {
      throw StateError('Garment $id was not found');
    }
    return garmentFromDoc(doc);
  }

  Future<Garment> createGarment({
    required String name,
    required String category,
    String? brand,
    String? color,
    String? season,
    String? occasion,
    double? price,
    String currency = AppConstants.defaultCurrency,
    String? notes,
    List<File> imageFiles = const [],
  }) async {
    final id = _uuid.v4();
    final doc = _garments.doc(id);
    await doc.set({
      'userId': _userId,
      'name': name,
      'category': category,
      'brand': brand,
      'color': color,
      'season': season,
      'occasion': occasion,
      'price': price,
      'currency': currency,
      'notes': notes,
      'wearCount': 0,
      'images': <Map<String, dynamic>>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (imageFiles.isNotEmpty) {
      final uploaded = <String>[];
      try {
        final images = await Future.wait(imageFiles.map((file) async {
          final path = await _uploadImage(file);
          uploaded.add(path);
          return path;
        }));
        await doc.update({
          'images': [
            for (var i = 0; i < images.length; i++)
              {'path': images[i], 'position': i},
          ],
          'updatedAt': FieldValue.serverTimestamp(),
        });
        for (final file in imageFiles) {
          await deleteFileQuietly(file);
        }
      } catch (_) {
        await doc.delete();
        await _deleteStorage(uploaded);
        rethrow;
      }
    }

    return getGarment(id);
  }

  Future<Garment> updateGarment(String id, Map<String, dynamic> updates) async {
    final mapped = <String, dynamic>{
      for (final entry in updates.entries)
        if (entry.key != 'user_id' && entry.key != 'id')
          _fieldName(entry.key): entry.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _garments.doc(id).update(mapped);
    return getGarment(id);
  }

  /// Replaces the garment's photos with [keepUrls] (existing download URLs,
  /// in order) followed by [newFiles]. Photos left out are deleted from
  /// storage once the garment no longer references them.
  Future<void> updateGarmentImages(
    String id, {
    required List<String> keepUrls,
    List<File> newFiles = const [],
  }) async {
    final doc = _garments.doc(id);
    final previous = _imagePaths((await doc.get()).data());
    final kept = [
      for (final url in keepUrls) _storage.refFromURL(url).fullPath,
    ];

    final uploaded = <String>[];
    try {
      final added = await Future.wait(newFiles.map((file) async {
        final path = await _uploadImage(file);
        uploaded.add(path);
        return path;
      }));
      final paths = [...kept, ...added];
      await doc.update({
        'images': [
          for (var i = 0; i < paths.length; i++)
            {'path': paths[i], 'position': i},
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await _deleteStorage(uploaded);
      rethrow;
    }

    await _deleteStorage(
      previous.where((path) => !kept.contains(path)).toList(),
    );
    for (final file in newFiles) {
      await deleteFileQuietly(file);
    }
  }

  Future<void> deleteGarment(String id) async {
    final doc = await _garments.doc(id).get();
    final paths = _imagePaths(doc.data());
    await _garments.doc(id).delete();
    await _deleteStorage(paths);
  }

  Future<void> incrementWearCount(String id) async {
    final ref = _garments.doc(id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final count = (snap.data()?['wearCount'] as num?)?.toInt() ?? 0;
      tx.update(ref, {
        'wearCount': count + 1,
        'lastWorn': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<Map<String, int>> getCategoryStats() async {
    final garments = await getGarments();
    final stats = <String, int>{};
    for (final garment in garments) {
      stats[garment.category] = (stats[garment.category] ?? 0) + 1;
    }
    return stats;
  }

  Future<List<Garment>> getLeastWorn({int limit = 5}) async {
    final garments = await getGarments();
    garments.sort((a, b) => a.wearCount.compareTo(b.wearCount));
    return garments.take(limit).toList();
  }

  Future<List<Garment>> getMostWorn({int limit = 5}) async {
    final garments = await getGarments();
    garments.sort((a, b) => b.wearCount.compareTo(a.wearCount));
    return garments.take(limit).toList();
  }

  Future<String> _uploadImage(File file) async {
    final path = 'garments/$_userId/${_uuid.v4()}.jpg';
    await _storage.ref(path).putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
    return path;
  }

  Future<void> _deleteStorage(List<String> paths) async {
    for (final path in paths) {
      try {
        await _storage.ref(path).delete();
      } catch (_) {}
    }
  }

  List<String> _imagePaths(Map<String, dynamic>? data) {
    final raw = data?['images'] as List<dynamic>? ?? const [];
    return [
      for (final image in raw)
        if (image is Map && image['path'] is String) image['path'] as String,
    ];
  }

  String _fieldName(String key) {
    switch (key) {
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
