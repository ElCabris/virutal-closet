import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/providers.dart';
import '../../widgets/outfit_card.dart';
import '../../widgets/category_filter.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class OutfitsScreen extends ConsumerStatefulWidget {
  const OutfitsScreen({super.key});

  @override
  ConsumerState<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends ConsumerState<OutfitsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 4),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MySavedOutfits(),
                  _AiSuggestions(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/outfits/builder'),
        child: const Icon(Icons.add),
      ).animate().scale(delay: 300.ms),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Text(
        'Outfits',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppColors.background,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'My Outfits'),
            Tab(text: 'AI Suggestions'),
          ],
        ),
      ),
    );
  }
}

class _MySavedOutfits extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfitsAsync = ref.watch(outfitsProvider);
    final selectedOccasion = ref.watch(selectedOccasionProvider);

    return Column(
      children: [
        const SizedBox(height: 12),
        CategoryFilter(
          categories: AppConstants.occasions,
          selected: selectedOccasion,
          onSelected: (o) =>
              ref.read(selectedOccasionProvider.notifier).state = o,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: outfitsAsync.when(
            loading: () => const LoadingIndicator(),
            error: (e, _) => ErrorView(
              message: 'Failed to load outfits',
              onRetry: () => ref.invalidate(outfitsProvider),
            ),
            data: (outfits) => outfits.isEmpty
                ? EmptyView(
                    icon: Icons.checkroom_outlined,
                    title: 'No outfits yet',
                    subtitle: 'Build your first outfit by combining\ngarments from your closet',
                    action: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Build Outfit'),
                      onPressed: () => context.push('/outfits/builder'),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: outfits.length,
                    itemBuilder: (_, i) => OutfitCard(
                      outfit: outfits[i],
                      index: i,
                      onTap: () => context.push('/outfits/${outfits[i].id}'),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _AiSuggestions extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AiSuggestions> createState() => _AiSuggestionsState();
}

class _AiSuggestionsState extends ConsumerState<_AiSuggestions> {
  String? _occasion;
  String? _season;

  @override
  Widget build(BuildContext context) {
    final params = AiSuggestionParams(occasion: _occasion, season: _season);
    final suggestionsAsync = ref.watch(aiSuggestionsProvider(params));

    return Column(
      children: [
        const SizedBox(height: 12),
        _buildFilters(),
        const SizedBox(height: 12),
        Expanded(
          child: suggestionsAsync.when(
            loading: () => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Curating your perfect outfits…',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            error: (e, _) => ErrorView(
              message: 'Could not generate suggestions.\nCheck your API key.',
              onRetry: () =>
                  ref.invalidate(aiSuggestionsProvider(params)),
            ),
            data: (suggestions) => suggestions.isEmpty
                ? EmptyView(
                    icon: Icons.auto_awesome_outlined,
                    title: 'No suggestions yet',
                    subtitle: 'Add garments to your closet\nto get AI outfit recommendations',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final s = suggestions[i];
                      return OutfitSuggestionCard(
                        name: s.name,
                        description: s.description,
                        occasion: s.occasion,
                        tip: s.tip,
                        garmentCount: s.garments.length,
                        index: i,
                        onSave: () => _saveOutfit(s.name, s.garments
                            .map((g) => g.id)
                            .toList(), s.occasion),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterChip('Occasion', _occasion, AppConstants.occasions, (v) {
            setState(() => _occasion = v);
          }),
          const SizedBox(width: 8),
          _filterChip('Season', _season, AppConstants.seasons, (v) {
            setState(() => _season = v);
          }),
          if (_occasion != null || _season != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() {
                _occasion = null;
                _season = null;
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? selected, List<String> options,
      ValueChanged<String?> onChanged) {
    return GestureDetector(
      onTap: () => _showFilterSheet(label, options, selected, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected != null
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected != null ? AppColors.primary : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected ?? label,
              style: TextStyle(
                color: selected != null
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontSize: 13,
                fontWeight:
                    selected != null ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: selected != null
                  ? AppColors.primary
                  : AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(String label, List<String> options, String? selected,
      ValueChanged<String?> onChanged) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(label,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            ...options.map((o) => ListTile(
                  title: Text(o),
                  trailing: selected == o
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    onChanged(selected == o ? null : o);
                    context.pop();
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _saveOutfit(
      String name, List<String> garmentIds, String occasion) async {
    try {
      await ref.read(outfitRepositoryProvider).createOutfit(
            name: name,
            garmentIds: garmentIds,
            occasion: occasion,
          );
      ref.invalidate(outfitsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outfit saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
