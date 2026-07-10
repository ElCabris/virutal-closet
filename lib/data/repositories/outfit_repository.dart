import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/outfit.dart';
import '../models/garment.dart';
import '../../core/constants/app_constants.dart';

class OutfitRepository {
  OutfitRepository(this._supabase);

  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  String get _userId => _supabase.auth.currentUser!.id;

  Future<List<Outfit>> getOutfits({String? occasion}) async {
    var query = _supabase
        .from(AppConstants.tableOutfits)
        .select()
        .eq('user_id', _userId);

    if (occasion != null && occasion != 'All') {
      query = query.eq('occasion', occasion);
    }

    final data = await query.order('created_at', ascending: false);
    final outfits = data.map((json) => Outfit.fromJson(json)).toList();

    // Hydrate garments for each outfit
    return Future.wait(outfits.map(_hydrateOutfit));
  }

  Future<Outfit> getOutfit(String id) async {
    final data = await _supabase
        .from(AppConstants.tableOutfits)
        .select()
        .eq('id', id)
        .single();
    return _hydrateOutfit(Outfit.fromJson(data));
  }

  Future<Outfit> createOutfit({
    required String name,
    required List<String> garmentIds,
    String? occasion,
    String? season,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final data = {
      'id': id,
      'user_id': _userId,
      'name': name,
      'garment_ids': garmentIds,
      'occasion': occasion,
      'season': season,
      'notes': notes,
      'wear_count': 0,
    };

    final result = await _supabase
        .from(AppConstants.tableOutfits)
        .insert(data)
        .select()
        .single();

    return _hydrateOutfit(Outfit.fromJson(result));
  }

  Future<Outfit> updateOutfit(String id, Map<String, dynamic> updates) async {
    final result = await _supabase
        .from(AppConstants.tableOutfits)
        .update(updates)
        .eq('id', id)
        .eq('user_id', _userId)
        .select()
        .single();

    return _hydrateOutfit(Outfit.fromJson(result));
  }

  Future<void> deleteOutfit(String id) async {
    await _supabase
        .from(AppConstants.tableOutfits)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> incrementWearCount(String id) async {
    final outfit = await getOutfit(id);
    await _supabase.from(AppConstants.tableOutfits).update({
      'wear_count': outfit.wearCount + 1,
      'last_worn': DateTime.now().toIso8601String(),
    }).eq('id', id).eq('user_id', _userId);

    // Also increment wear count for each garment
    for (final garmentId in outfit.garmentIds) {
      final garment = await _supabase
          .from(AppConstants.tableGarments)
          .select('wear_count')
          .eq('id', garmentId)
          .single();
      await _supabase.from(AppConstants.tableGarments).update({
        'wear_count': (garment['wear_count'] as int) + 1,
        'last_worn': DateTime.now().toIso8601String(),
      }).eq('id', garmentId);
    }
  }

  Future<Outfit> _hydrateOutfit(Outfit outfit) async {
    if (outfit.garmentIds.isEmpty) return outfit;

    final garmentData = await _supabase
        .from(AppConstants.tableGarments)
        .select()
        .inFilter('id', outfit.garmentIds);

    final garments =
        garmentData.map((json) => Garment.fromJson(json)).toList();
    return outfit.copyWith(garments: garments);
  }
}
