import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/repositories/garment_repository.dart';
import '../../data/repositories/outfit_repository.dart';
import '../../data/repositories/calendar_repository.dart';
import '../../data/datasources/ai_service.dart';
import '../../data/models/garment.dart';
import '../../data/models/outfit.dart';
import '../../data/models/calendar_entry.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final supabaseProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

final aiServiceProvider = Provider<AiService>(
  (_) => AiService(
    dotenv.env['AI_API_KEY'] ?? '',
    dotenv.env['AI_MODEL'] ?? '',
  ),
);

// ─── Repositories ─────────────────────────────────────────────────────────────

final garmentRepositoryProvider = Provider<GarmentRepository>(
  (ref) => GarmentRepository(ref.watch(supabaseProvider)),
);

final outfitRepositoryProvider = Provider<OutfitRepository>(
  (ref) => OutfitRepository(ref.watch(supabaseProvider)),
);

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => CalendarRepository(ref.watch(supabaseProvider)),
);

// ─── Auth ─────────────────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(supabaseProvider).auth.onAuthStateChange,
);

final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(supabaseProvider).auth.currentUser,
);

// ─── Garments ─────────────────────────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

final garmentsProvider = FutureProvider.autoDispose<List<Garment>>((ref) {
  final repo = ref.watch(garmentRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  return repo.getGarments(category: category == 'All' ? null : category);
});

final garmentProvider =
    FutureProvider.autoDispose.family<Garment, String>((ref, id) {
  return ref.watch(garmentRepositoryProvider).getGarment(id);
});

// ─── Outfits ──────────────────────────────────────────────────────────────────

final selectedOccasionProvider = StateProvider<String>((ref) => 'All');

final outfitsProvider = FutureProvider.autoDispose<List<Outfit>>((ref) {
  final repo = ref.watch(outfitRepositoryProvider);
  final occasion = ref.watch(selectedOccasionProvider);
  return repo.getOutfits(occasion: occasion == 'All' ? null : occasion);
});

final outfitProvider =
    FutureProvider.autoDispose.family<Outfit, String>((ref, id) {
  return ref.watch(outfitRepositoryProvider).getOutfit(id);
});

// ─── Calendar ─────────────────────────────────────────────────────────────────

final selectedMonthProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final calendarEntriesProvider =
    FutureProvider.autoDispose<List<CalendarEntry>>((ref) {
  final repo = ref.watch(calendarRepositoryProvider);
  final month = ref.watch(selectedMonthProvider);
  return repo.getEntriesForMonth(month.year, month.month);
});

final calendarEntryForDateProvider =
    FutureProvider.autoDispose.family<CalendarEntry?, DateTime>((ref, date) {
  return ref.watch(calendarRepositoryProvider).getEntryForDate(date);
});

// ─── AI Suggestions ───────────────────────────────────────────────────────────

class AiSuggestionParams {
  final String? occasion;
  final String? season;
  AiSuggestionParams({this.occasion, this.season});
}

final aiSuggestionsProvider = FutureProvider.autoDispose
    .family<List<OutfitSuggestion>, AiSuggestionParams>((ref, params) async {
  final garments =
      await ref.watch(garmentRepositoryProvider).getGarments();
  if (garments.isEmpty) return [];
  return ref.watch(aiServiceProvider).suggestOutfits(
        garments: garments,
        occasion: params.occasion,
        season: params.season,
        count: 3,
      );
});

// ─── Analytics ────────────────────────────────────────────────────────────────

final categoryStatsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) {
  return ref.watch(garmentRepositoryProvider).getCategoryStats();
});

final mostWornProvider = FutureProvider.autoDispose<List<Garment>>((ref) {
  return ref.watch(garmentRepositoryProvider).getMostWorn(limit: 5);
});

final leastWornProvider = FutureProvider.autoDispose<List<Garment>>((ref) {
  return ref.watch(garmentRepositoryProvider).getLeastWorn(limit: 5);
});
