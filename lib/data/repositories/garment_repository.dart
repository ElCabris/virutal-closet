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

  Future<List<Garment>> getGarments({String? category}) async {
    var query = _supabase
        .from(AppConstants.tableGarments)
        .select()
        .eq('user_id', _userId);

    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }

    final data = await query.order('created_at', ascending: false);
    return data.map((json) => Garment.fromJson(json)).toList();
  }

  Future<Garment> getGarment(String id) async {
    final data = await _supabase
        .from(AppConstants.tableGarments)
        .select()
        .eq('id', id)
        .single();
    return Garment.fromJson(data);
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
    File? imageFile,
  }) async {
    String? imageUrl;

    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile);
    }

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
      'image_url': imageUrl,
      'notes': notes,
      'wear_count': 0,
    };

    final result = await _supabase
        .from(AppConstants.tableGarments)
        .insert(data)
        .select()
        .single();

    return Garment.fromJson(result);
  }

  Future<Garment> updateGarment(String id, Map<String, dynamic> updates,
      {File? imageFile}) async {
    if (imageFile != null) {
      updates['image_url'] = await _uploadImage(imageFile);
    }

    final result = await _supabase
        .from(AppConstants.tableGarments)
        .update(updates)
        .eq('id', id)
        .eq('user_id', _userId)
        .select()
        .single();

    return Garment.fromJson(result);
  }

  Future<void> deleteGarment(String id) async {
    final garment = await getGarment(id);
    if (garment.imageUrl != null) {
      await _deleteImage(garment.imageUrl!);
    }

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

  Future<String> _uploadImage(File file) async {
    final fileName = '${_userId}/${_uuid.v4()}.jpg';
    await _supabase.storage
        .from(AppConstants.bucketGarments)
        .upload(fileName, file);
    return _supabase.storage
        .from(AppConstants.bucketGarments)
        .getPublicUrl(fileName);
  }

  Future<void> _deleteImage(String url) async {
    try {
      final uri = Uri.parse(url);
      final path = uri.pathSegments.skipWhile((s) => s != AppConstants.bucketGarments).skip(1).join('/');
      await _supabase.storage.from(AppConstants.bucketGarments).remove([path]);
    } catch (_) {}
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
        .select()
        .eq('user_id', _userId)
        .order('wear_count', ascending: true)
        .limit(limit);
    return data.map((json) => Garment.fromJson(json)).toList();
  }

  Future<List<Garment>> getMostWorn({int limit = 5}) async {
    final data = await _supabase
        .from(AppConstants.tableGarments)
        .select()
        .eq('user_id', _userId)
        .order('wear_count', ascending: false)
        .limit(limit);
    return data.map((json) => Garment.fromJson(json)).toList();
  }
}
