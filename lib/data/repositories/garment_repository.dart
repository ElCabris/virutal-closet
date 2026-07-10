import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/garment.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/file_utils.dart';

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
    String currency = AppConstants.defaultCurrency,
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
      'currency': currency,
      'notes': notes,
      'wear_count': 0,
    };

    await _supabase.from(AppConstants.tableGarments).insert(data);

    if (imageFiles.isNotEmpty) {
      try {
        await _uploadAndLinkImages(id, imageFiles);
      } catch (_) {
        // Compensating action: Storage and Postgres can't share a
        // transaction, so if attaching the requested photos fails we roll
        // back the garment row ourselves. Leaving it around would (a) be a
        // garment silently missing the photos the user asked for, and
        // (b) risk a duplicate garment if the caller retries the save.
        // The local files in imageFiles are left untouched here — they
        // were never durably persisted, so deleting them would be a real
        // data loss (the caller has nothing left to retry with).
        await _supabase.from(AppConstants.tableGarments).delete().eq('id', id);
        rethrow;
      }

      // The bytes are durably in Storage now, so the local working copies
      // (originals or background-removed versions) are disposable. This is
      // the only point where that's actually guaranteed, which is why
      // cleanup lives here rather than in the UI layer that picked them.
      for (final file in imageFiles) {
        await deleteFileQuietly(file);
      }
    }

    return getGarment(id);
  }

  Future<Garment> updateGarment(String id, Map<String, dynamic> updates) async {
    await _supabase
        .from(AppConstants.tableGarments)
        .update(updates)
        .eq('id', id)
        .eq('user_id', _userId);

    return getGarment(id);
  }

  Future<void> deleteGarment(String id) async {
    final images = await _supabase
        .from(AppConstants.tableGarmentImages)
        .select('storage_path')
        .eq('garment_id', id);
    final paths = images.map((row) => row['storage_path'] as String).toList();

    // Delete the DB row first (garment_images rows cascade automatically).
    // If the storage cleanup below fails, the worst case is an orphaned
    // file left in Storage — harmless and reclaimable later. Deleting
    // storage first would risk the opposite: a garment_images row that
    // still resolves to a now-missing file, which breaks the UI.
    await _supabase
        .from(AppConstants.tableGarments)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);

    if (paths.isNotEmpty) {
      await _supabase.storage.from(AppConstants.bucketGarments).remove(paths);
    }
  }

  Future<void> incrementWearCount(String id) async {
    final row = await _supabase
        .from(AppConstants.tableGarments)
        .select('wear_count')
        .eq('id', id)
        .single();
    await _supabase.from(AppConstants.tableGarments).update({
      'wear_count': (row['wear_count'] as int) + 1,
      'last_worn': DateTime.now().toIso8601String(),
    }).eq('id', id).eq('user_id', _userId);
  }

  /// Uploads [files] to Storage and links them to [garmentId] as a single
  /// batch insert (one INSERT statement is atomic: either every row is
  /// created or none is). Uploads run in parallel for speed; `Future.wait`
  /// preserves the input order in its result regardless of completion
  /// order, so `position` still reflects the order the user picked the
  /// photos in even though uploads may finish out of order. `uploaded`
  /// tracks paths as they complete (in completion order, which is fine — it
  /// is only used for best-effort cleanup) so that if any upload or the
  /// insert fails, whatever already made it to Storage is removed again
  /// instead of leaking unreferenced files.
  Future<void> _uploadAndLinkImages(String garmentId, List<File> files) async {
    final uploaded = <String>[];
    try {
      final paths = await Future.wait(files.map((file) async {
        final path = await _uploadImage(file);
        uploaded.add(path);
        return path;
      }));

      final rows = [
        for (var i = 0; i < paths.length; i++)
          {
            'garment_id': garmentId,
            'user_id': _userId,
            'storage_path': paths[i],
            'position': i,
          },
      ];
      await _supabase.from(AppConstants.tableGarmentImages).insert(rows);
    } catch (_) {
      if (uploaded.isNotEmpty) {
        try {
          await _supabase.storage
              .from(AppConstants.bucketGarments)
              .remove(uploaded);
        } catch (_) {
          // Best-effort only — a leaked file is preferable to masking the
          // original failure with a secondary one.
        }
      }
      rethrow;
    }
  }

  Future<String> _uploadImage(File file) async {
    final path = '$_userId/${_uuid.v4()}.jpg';
    await _supabase.storage.from(AppConstants.bucketGarments).upload(path, file);
    return path;
  }

  /// Returns a copy of [json] with the joined `garment_images` rows
  /// flattened into an ordered `image_urls` list, so [Garment.fromJson]
  /// can stay storage-agnostic. Never mutates the map or list it receives.
  Map<String, dynamic> _resolveImages(Map<String, dynamic> json) {
    final rawImages = json['garment_images'] as List<dynamic>? ?? const [];
    final images = rawImages.map((e) => e as Map<String, dynamic>).toList()
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

    return {
      ...json,
      'image_urls': [
        for (final img in images)
          _supabase.storage
              .from(AppConstants.bucketGarments)
              .getPublicUrl(img['storage_path'] as String),
      ],
    };
  }

  Future<Map<String, int>> getCategoryStats() async {
    final data = await _supabase
        .from(AppConstants.tableGarments)
        .select('category')
        .eq('user_id', _userId);

    final stats = <String, int>{};
    for (final row in data) {
      final category = row['category'] as String;
      stats[category] = (stats[category] ?? 0) + 1;
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
