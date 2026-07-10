import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/providers.dart';
import '../../widgets/garment_card.dart';
import '../../widgets/category_filter.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/garment.dart';

class OutfitBuilderScreen extends ConsumerStatefulWidget {
  const OutfitBuilderScreen({super.key});

  @override
  ConsumerState<OutfitBuilderScreen> createState() =>
      _OutfitBuilderScreenState();
}

class _OutfitBuilderScreenState extends ConsumerState<OutfitBuilderScreen> {
  final _nameCtrl = TextEditingController();
  final Set<String> _selectedIds = {};
  String? _occasion;
  String? _season;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  List<Garment> _selectedGarments(List<Garment> all) =>
      all.where((g) => _selectedIds.contains(g.id)).toList();

  Future<void> _save(List<Garment> all) async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your outfit a name')),
      );
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one garment')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(outfitRepositoryProvider).createOutfit(
            name: _nameCtrl.text.trim(),
            garmentIds: _selectedIds.toList(),
            occasion: _occasion,
            season: _season,
          );
      ref.invalidate(outfitsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final garmentsAsync = ref.watch(garmentsProvider);
    final category = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Build Outfit'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          garmentsAsync.when(
            data: (garments) => TextButton(
              onPressed: _saving ? null : () => _save(garments),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Text('Save'),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTopSection(),
          const SizedBox(height: 4),
          CategoryFilter(
            categories: AppConstants.garmentCategories,
            selected: category,
            onSelected: (c) =>
                ref.read(selectedCategoryProvider.notifier).state = c,
          ),
          const SizedBox(height: 12),
          if (_selectedIds.isNotEmpty)
            garmentsAsync.when(
              data: (garments) =>
                  _buildSelectedPreview(_selectedGarments(garments)),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          Expanded(
            child: garmentsAsync.when(
              loading: () => const GarmentGridShimmer(),
              error: (e, _) => ErrorView(message: 'Failed to load garments'),
              data: (garments) => garments.isEmpty
                  ? const EmptyView(
                      icon: Icons.checkroom_outlined,
                      title: 'No garments yet',
                      subtitle: 'Add garments to your closet first',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: garments.length,
                      itemBuilder: (_, i) => GarmentCard(
                        garment: garments[i],
                        index: i,
                        selected: _selectedIds.contains(garments[i].id),
                        onTap: () => setState(() {
                          if (_selectedIds.contains(garments[i].id)) {
                            _selectedIds.remove(garments[i].id);
                          } else {
                            _selectedIds.add(garments[i].id);
                          }
                        }),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Outfit name',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dropdownChip(
                  'Occasion',
                  _occasion,
                  AppConstants.occasions,
                  (v) => setState(() => _occasion = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdownChip(
                  'Season',
                  _season,
                  AppConstants.seasons,
                  (v) => setState(() => _season = v),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _dropdownChip(String label, String? selected, List<String> options,
      ValueChanged<String?> onChanged) {
    return GestureDetector(
      onTap: () => _showSheet(label, options, selected, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected != null
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected != null ? AppColors.primary : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected ?? label,
                style: TextStyle(
                  color: selected != null
                      ? AppColors.primary
                      : AppColors.textDisabled,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 16, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }

  void _showSheet(String label, List<String> options, String? selected,
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
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
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

  Widget _buildSelectedPreview(List<Garment> selected) {
    return Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selected.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    selected[i].name.split(' ').first,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ),
          Text(
            '${selected.length} selected',
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }
}
