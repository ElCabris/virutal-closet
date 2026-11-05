import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/garment.dart';
import '../models/outfit.dart';

String? firestoreIso(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  return value.toString();
}

Future<Garment> garmentFromDoc(
  DocumentSnapshot<Map<String, dynamic>> doc,
) async {
  final data = doc.data() ?? {};
  final raw = (data['images'] as List<dynamic>? ?? const [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList()
    ..sort(
      (a, b) => ((a['position'] as num?) ?? 0)
          .compareTo((b['position'] as num?) ?? 0),
    );

  final urls = <String>[];
  for (final image in raw) {
    final path = image['path'] as String?;
    if (path == null || path.isEmpty) continue;
    try {
      urls.add(await FirebaseStorage.instance.ref(path).getDownloadURL());
    } catch (_) {
      // A missing object should not hide the rest of the garment.
    }
  }

  return Garment.fromJson({
    'id': doc.id,
    'user_id': data['userId'] as String? ??
        doc.reference.parent.parent?.id ??
        '',
    'name': data['name'],
    'category': data['category'],
    'brand': data['brand'],
    'color': data['color'],
    'season': data['season'],
    'occasion': data['occasion'],
    'price': data['price'],
    'currency': data['currency'],
    'image_urls': urls,
    'notes': data['notes'],
    'wear_count': data['wearCount'] ?? 0,
    'last_worn': firestoreIso(data['lastWorn']),
    'created_at': firestoreIso(data['createdAt']) ??
        DateTime.now().toIso8601String(),
  });
}

DateTime? firestoreDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

Outfit outfitFromDoc(
  DocumentSnapshot<Map<String, dynamic>> doc, {
  List<Garment> garments = const [],
}) {
  final data = doc.data() ?? {};
  return Outfit(
    id: doc.id,
    userId: data['userId'] as String? ??
        doc.reference.parent.parent?.id ??
        '',
    name: data['name'] as String? ?? '',
    garmentIds: List<String>.from(data['garmentIds'] ?? const []),
    garments: garments,
    occasion: data['occasion'] as String?,
    season: data['season'] as String?,
    imageUrl: data['imageUrl'] as String?,
    notes: data['notes'] as String?,
    wearCount: (data['wearCount'] as num?)?.toInt() ?? 0,
    lastWorn: firestoreDate(data['lastWorn']),
    createdAt: firestoreDate(data['createdAt']) ?? DateTime.now(),
  );
}
