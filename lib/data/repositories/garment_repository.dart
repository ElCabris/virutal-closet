import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/garment.dart';
import '../../core/constants/app_constants.dart';

class GarmentRepository {
  GarmentRepository(this._supabase);

  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  String get _userId => _supabase.auth.currentUser!.id;

  static const _garmentSelect = '*, garment_images(storage_path, position)';

  Future<List<Garment>> getGarments({String? category}) async {
    var query = _supabase
        .from(AppConstants.tableGarments)
        .select(_garmentSelect)
        .eq('user_id', _userId);

    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }

    final data = await query.order('created_at', ascending: false);
    return data.map((json) => Garment.fromJson(_resolveImages(json))).toList();
  }

  Future<Garment> getGarment(String id) async {
    final data = await _supabase
        .from(AppConstants.tableGarments)
        .select(_garmentSelect)
        .eq('id', id)
        .single();
    return Garment.fromJson(_resolveImages(data));
  }

  Future<Garment> createGarment({
    required String name,
    required String category,
    String? brand,
    String? color,
    String? season,
    String? occasion,
    double? price,
    String? notes,
    List<File> imageFiles = const [],
  }) async {
    final id = _uuid.v4();
    final data = {
      'id': id,
      'user_id': _userId,
      'name': name,
      'category': category,
      'brand': brand,
      'color': color,
      'season': season,
      'occasion': occasion,
      'price': price,
      'notes': notes,
      'wear_count': 0,
    };

    await _supabase.from(AppConstants.tableGarments).insert(data);

    if (imageFiles.isNotEmpty) {
      await _addImages(id, imageFiles);
    }

    return getGarment(id);
  }

  Future<Garment> updateGarment(String id, Map<String, dynamic> updates,
      {List<File> newImageFiles = const []}) async {
    if (updates.isNotEmpty) {
      await _supabase
          .from(AppConstants.tableGarments)
          .update(updates)
          .eq('id', id)
          .eq('user_id', _userId);
    }

    if (newImageFiles.isNotEmpty) {
      await _addImages(id, newImageFiles);
    }

    return getGarment(id);
  }

  Future<void> removeGarmentImage(String garmentId, String storagePath) async {
    await _supabase.storage
        .from(AppConstants.bucketGarments)
        .remove([storagePath]);
    await _supabase
        .from(AppConstants.tableGarmentImages)
        .delete()
        .eq('garment_id', garmentId)
        .eq('storage_path', storagePath);
  }

  Future<void> deleteGarment(String id) async {
    final images = await _supabase
        .from(AppConstants.tableGarmentImages)
        .select('storage_path')
        .eq('garment_id', id);
    final paths = images.map((row) => row['storage_path'] as String).toList();
    if (paths.isNotEmpty) {
      await _supabase.storage.from(AppConstants.bucketGarments).remove(paths);
    }

    // garment_images rows are removed automatically via ON DELETE CASCADE.
    await _supabase
        .from(AppConstants.tableGarments)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> incrementWearCount(String id) async {
    final garment = await getGarment(id);
    await _supabase.from(AppConstants.tableGarments).update({
      'wear_count': garment.wearCount + 1,
      'last_worn': DateTime.now().toIso8601String(),
    }).eq('id', id).eq('user_id', _userId);
  }

  Future<void> _addImages(String garmentId, List<File> files) async {
    final existing = await _supabase
        .from(AppConstants.tableGarmentImages)
        .select('id')
        .eq('garment_id', garmentId);
    final offset = existing.length;

    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < files.length; i++) {
      final path = await _uploadImage(files[i]);
      rows.add({
        'garment_id': garmentId,
        'user_id': _userId,
        'storage_path': path,
        'position': offset + i,
      });
    }
    await _supabase.from(AppConstants.tableGarmentImages).insert(rows);
  }

  Future<String> _uploadImage(File file) async {
    final path = '$_userId/${_uuid.v4()}.jpg';
    await _supabase.storage.from(AppConstants.bucketGarments).upload(path, file);
    return path;
  }

  /// Merges the joined `garment_images` rows into a single ordered
  /// `image_urls` list so [Garment.fromJson] can stay storage-agnostic.
  Map<String, dynamic> _resolveImages(Map<String, dynamic> json) {
    final images = (json['garment_images'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

    json['image_urls'] = images
        .map((img) => _supabase.storage
            .from(AppConstants.bucketGarments)
            .getPublicUrl(img['storage_path'] as String))
        .toList();
    return json;
  }

  Future<Map<String, int>> getCategoryStats() async {
    final garments = await getGarments();
    final stats = <String, int>{};
    for (final g in garments) {
      stats[g.category] = (stats[g.category] ?? 0) + 1;
    }
    return stats;
  }

  Future<List<Garment>> getLeastWorn({int limit = 5}) async {
    final data = await _supabase
        .from(AppConstants.tableGarments)
        .select(_garmentSelect)
        .eq('user_id', _userId)
        .order('wear_count', ascending: true)
        .limit(limit);
    return data.map((json) => Garment.fromJson(_resolveImages(json))).toList();
  }

  Future<List<Garment>> getMostWorn({int limit = 5}) async {
    final data = await _supabase
        .from(AppConstants.tableGarments)
        .select(_garmentSelect)
        .eq('user_id', _userId)
        .order('wear_count', ascending: false)
        .limit(limit);
    return data.map((json) => Garment.fromJson(_resolveImages(json))).toList();
  }
}
