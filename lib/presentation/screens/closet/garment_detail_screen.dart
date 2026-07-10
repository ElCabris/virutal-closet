import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/providers.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

class GarmentDetailScreen extends ConsumerStatefulWidget {
  const GarmentDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<GarmentDetailScreen> createState() =>
      _GarmentDetailScreenState();
}

class _GarmentDetailScreenState extends ConsumerState<GarmentDetailScreen> {
  final _pageController = PageController();
  int _photoIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final garmentAsync = ref.watch(garmentProvider(widget.id));

    return garmentAsync.when(
      loading: () => const Scaffold(body: LoadingIndicator()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: 'Garment not found'),
      ),
      data: (garment) => Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 380,
              pinned: true,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: AppColors.background.withOpacity(0.8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: AppColors.background.withOpacity(0.8),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => _confirmDelete(context, ref),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildPhotoGallery(garment),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTitle(context, garment),
                  const SizedBox(height: 20),
                  _buildStats(context, garment),
                  const SizedBox(height: 24),
                  _buildAttributes(context, garment),
                  if (garment.notes != null) ...[
                    const SizedBox(height: 24),
                    _buildNotes(context, garment.notes!),
                  ],
                  const SizedBox(height: 32),
                  _buildWearButton(context, ref, garment.id),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGallery(garment) {
    final photos = garment.imageUrls as List<String>;
    if (photos.isEmpty) {
      return Container(
        color: AppColors.surfaceVariant,
        child: Center(
          child: Text(
            categoryIcon(garment.category),
            style: const TextStyle(fontSize: 80),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: photos.length,
          onPageChanged: (i) => setState(() => _photoIndex = i),
          itemBuilder: (_, i) => CachedNetworkImage(
            imageUrl: photos[i],
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
          ),
        ),
        if (photos.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(photos.length, (i) {
                final active = i == _photoIndex;
                return AnimatedContainer(
                  duration: 200.ms,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : AppColors.background.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context, garment) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                garment.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (garment.brand != null) ...[
                const SizedBox(height: 4),
                Text(
                  garment.brand!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: categoryColor(garment.category).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            garment.category,
            style: TextStyle(
              color: categoryColor(garment.category),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildStats(BuildContext context, garment) {
    return Row(
      children: [
        _statCard(context,
            icon: Icons.repeat,
            label: 'Times worn',
            value: '${garment.wearCount}'),
        const SizedBox(width: 12),
        if (garment.price != null)
          _statCard(context,
              icon: Icons.attach_money,
              label: 'Cost / wear',
              value: garment.costPerWear > 0
                  ? formatPrice(garment.costPerWear, garment.currency)
                  : 'N/A'),
        if (garment.lastWorn != null) ...[
          const SizedBox(width: 12),
          _statCard(context,
              icon: Icons.calendar_today_outlined,
              label: 'Last worn',
              value: formatShortDate(garment.lastWorn!)),
        ],
      ].expand((w) => [w]).take(3).toList(),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _statCard(BuildContext context,
      {required IconData icon,
      required String label,
      required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.textPrimary)),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributes(BuildContext context, garment) {
    final attrs = <String, String?>{
      'Color': garment.color,
      'Season': garment.season,
      'Occasion': garment.occasion,
      'Price': garment.price != null
          ? formatPrice(garment.price!, garment.currency)
          : null,
    };

    final filtered = attrs.entries.where((e) => e.value != null).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filtered.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${e.key}  ',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                TextSpan(
                  text: e.value!,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildNotes(BuildContext context, String notes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notes, color: AppColors.textDisabled, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(notes, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildWearButton(BuildContext context, WidgetRef ref, String id) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.checkroom),
        label: const Text('Log as Worn Today'),
        onPressed: () async {
          await ref.read(garmentRepositoryProvider).incrementWearCount(id);
          ref.invalidate(garmentProvider(id));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logged as worn!')),
            );
          }
        },
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Garment'),
        content: const Text(
            'This garment will be permanently removed from your wardrobe.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              context.pop();
              await ref.read(garmentRepositoryProvider).deleteGarment(widget.id);
              ref.invalidate(garmentsProvider);
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
