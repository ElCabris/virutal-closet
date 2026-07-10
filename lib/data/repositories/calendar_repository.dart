import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/calendar_entry.dart';
import '../models/outfit.dart';
import '../../core/constants/app_constants.dart';

class CalendarRepository {
  CalendarRepository(this._supabase);

  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  String get _userId => _supabase.auth.currentUser!.id;

  Future<List<CalendarEntry>> getEntriesForMonth(
      int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);

    final data = await _supabase
        .from(AppConstants.tableCalendarEntries)
        .select()
        .eq('user_id', _userId)
        .gte('date', start.toIso8601String().split('T')[0])
        .lte('date', end.toIso8601String().split('T')[0])
        .order('date');

    return Future.wait(
      data.map((json) => _hydrateEntry(CalendarEntry.fromJson(json))),
    );
  }

  Future<CalendarEntry?> getEntryForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final data = await _supabase
        .from(AppConstants.tableCalendarEntries)
        .select()
        .eq('user_id', _userId)
        .eq('date', dateStr)
        .maybeSingle();

    if (data == null) return null;
    return _hydrateEntry(CalendarEntry.fromJson(data));
  }

  Future<CalendarEntry> setOutfitForDate({
    required DateTime date,
    required String outfitId,
    String? notes,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final existing = await getEntryForDate(date);

    Map<String, dynamic> result;
    if (existing != null) {
      result = await _supabase
          .from(AppConstants.tableCalendarEntries)
          .update({'outfit_id': outfitId, 'notes': notes})
          .eq('id', existing.id)
          .select()
          .single();
    } else {
      result = await _supabase
          .from(AppConstants.tableCalendarEntries)
          .insert({
            'id': _uuid.v4(),
            'user_id': _userId,
            'outfit_id': outfitId,
            'date': dateStr,
            'notes': notes,
          })
          .select()
          .single();
    }

    return _hydrateEntry(CalendarEntry.fromJson(result));
  }

  Future<void> removeEntryForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    await _supabase
        .from(AppConstants.tableCalendarEntries)
        .delete()
        .eq('user_id', _userId)
        .eq('date', dateStr);
  }

  Future<CalendarEntry> _hydrateEntry(CalendarEntry entry) async {
    final outfitData = await _supabase
        .from(AppConstants.tableOutfits)
        .select()
        .eq('id', entry.outfitId)
        .maybeSingle();

    if (outfitData == null) return entry;

    return CalendarEntry(
      id: entry.id,
      userId: entry.userId,
      outfitId: entry.outfitId,
      outfit: Outfit.fromJson(outfitData),
      date: entry.date,
      notes: entry.notes,
      createdAt: entry.createdAt,
    );
  }
}
