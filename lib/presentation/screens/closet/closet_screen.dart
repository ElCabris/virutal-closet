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

class ClosetScreen extends ConsumerWidget {
  const ClosetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garmentsAsync = ref.watch(garmentsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref),
            const SizedBox(height: 16),
            CategoryFilter(
              categories: AppConstants.garmentCategories,
              selected: selectedCategory,
              onSelected: (cat) =>
                  ref.read(selectedCategoryProvider.notifier).state = cat,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: garmentsAsync.when(
                loading: () => const GarmentGridShimmer(),
                error: (e, _) => ErrorView(
                  message: 'Failed to load wardrobe',
                  onRetry: () => ref.invalidate(garmentsProvider),
                ),
                data: (garments) => garments.isEmpty
                    ? EmptyView(
                        icon: Icons.checkroom_outlined,
                        title: selectedCategory == 'All'
                            ? 'Your closet is empty'
                            : 'No $selectedCategory yet',
                        subtitle: selectedCategory == 'All'
                            ? 'Add your first garment to start building your wardrobe'
                            : 'Try a different category or add a new garment',
                        action: selectedCategory == 'All'
                            ? ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add Garment'),
                                onPressed: () => context.push('/closet/add'),
                              )
                            : null,
                      )
                    : _buildGrid(context, garments),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/closet/add'),
        child: const Icon(Icons.add),
      ).animate().scale(delay: 300.ms),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Closet',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Consumer(
                builder: (_, ref, __) {
                  final count = ref
                      .watch(garmentsProvider)
                      .valueOrNull
                      ?.length;
                  return Text(
                    count != null ? '$count items' : '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                },
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/closet/search'),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List garments) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: garments.length,
      itemBuilder: (_, index) => GarmentCard(
        garment: garments[index],
        index: index,
        onTap: () => context.push('/closet/${garments[index].id}'),
      ),
    );
  }
}
