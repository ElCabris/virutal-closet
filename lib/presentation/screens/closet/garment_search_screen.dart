import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/garment_card.dart';
import '../../widgets/common/loading_indicator.dart';

class GarmentSearchScreen extends ConsumerStatefulWidget {
  const GarmentSearchScreen({super.key});

  @override
  ConsumerState<GarmentSearchScreen> createState() =>
      _GarmentSearchScreenState();
}

class _GarmentSearchScreenState extends ConsumerState<GarmentSearchScreen> {
  final _queryCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final garmentsAsync = ref.watch(allGarmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryCtrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search your closet',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
      ),
      body: garmentsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (_, __) => ErrorView(
          message: 'Failed to load wardrobe',
          onRetry: () => ref.invalidate(allGarmentsProvider),
        ),
        data: (garments) {
          final results =
              garments.where((g) => g.matchesQuery(_query)).toList();
          if (results.isEmpty) {
            return const EmptyView(
              icon: Icons.search_off,
              title: 'No garments found',
              subtitle: 'Try a different name, brand or color',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: results.length,
            itemBuilder: (_, index) => GarmentCard(
              garment: results[index],
              index: index,
              onTap: () => context.push('/closet/${results[index].id}'),
            ),
          );
        },
      ),
    );
  }
}
