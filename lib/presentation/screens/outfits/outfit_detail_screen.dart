import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/garment_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/outfit.dart';

class OutfitDetailScreen extends ConsumerWidget {
  const OutfitDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(outfitProvider(id)).when(
          loading: () => const Scaffold(body: LoadingIndicator()),
          error: (_, __) => Scaffold(
            appBar: AppBar(),
            body: const ErrorView(message: 'Outfit not found'),
          ),
          data: (outfit) => Scaffold(
            appBar: AppBar(
              title: Text(outfit.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit outfit',
                  onPressed: () => context.push('/outfits/$id/edit'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete outfit',
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSummary(context, outfit),
                if (outfit.notes != null) ...[
                  const SizedBox(height: 16),
                  Text(outfit.notes!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 24),
                Text('${outfit.garments.length} items',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildGarments(context, outfit),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.checkroom),
                  label: const Text('Log as Worn Today'),
                  onPressed: () => _logWornToday(context, ref),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildSummary(BuildContext context, Outfit outfit) {
    final facts = [
      if (outfit.occasion != null) outfit.occasion!,
      if (outfit.season != null) outfit.season!,
      'Worn ${outfit.wearCount} times',
      if (outfit.lastWorn != null) 'Last worn ${formatDate(outfit.lastWorn!)}',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final fact in facts)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Text(fact, style: Theme.of(context).textTheme.labelMedium),
          ),
      ],
    );
  }

  Widget _buildGarments(BuildContext context, Outfit outfit) {
    if (outfit.garments.isEmpty) {
      return const EmptyView(
        icon: Icons.checkroom_outlined,
        title: 'No garments left',
        subtitle: 'The garments in this outfit were deleted',
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: outfit.garments.length,
      itemBuilder: (_, i) => GarmentCard(
        garment: outfit.garments[i],
        index: i,
        onTap: () => context.push('/closet/${outfit.garments[i].id}'),
      ),
    );
  }

  Future<void> _logWornToday(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final calendar = ref.read(calendarRepositoryProvider);
    final today = DateTime.now();
    try {
      final entry = await calendar.getEntryForDate(today);
      if (entry != null && entry.outfitId == id && entry.worn) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Already logged for today')),
        );
        return;
      }
      if (entry != null && entry.outfitId != id && context.mounted) {
        final replace = await _confirmReplace(context, entry.outfit?.name);
        if (replace != true) return;
      }
      await calendar.markWorn(date: today, outfitId: id);
      ref.invalidate(outfitProvider(id));
      ref.invalidate(outfitsProvider);
      ref.invalidate(allGarmentsProvider);
      ref.invalidate(calendarEntriesProvider);
      ref.invalidate(calendarEntryForDateProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Logged as worn!')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<bool?> _confirmReplace(BuildContext context, String? otherName) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Replace today\'s outfit?'),
        content: Text(
          'Today already has ${otherName ?? 'another outfit'} on the calendar. '
          'Each day holds one outfit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Outfit'),
        content: const Text(
            'This outfit and its calendar entries will be removed. '
            'Your garments are not affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(outfitRepositoryProvider).deleteOutfit(id);
              ref.invalidate(outfitsProvider);
              ref.invalidate(calendarEntriesProvider);
              ref.invalidate(calendarEntryForDateProvider);
              if (context.mounted) context.pop();
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
