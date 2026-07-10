import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/providers.dart';
import '../../widgets/garment_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryStats = ref.watch(categoryStatsProvider);
    final mostWorn = ref.watch(mostWornProvider);
    final leastWorn = ref.watch(leastWornProvider);
    final garments = ref.watch(garmentsProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Text(
                  'Analytics',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: garments.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (data) => _buildSummaryCards(context, data.length),
              ),
            ),
            SliverToBoxAdapter(
              child: categoryStats.when(
                loading: () => const LoadingIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => stats.isEmpty
                    ? const SizedBox.shrink()
                    : _buildCategoryChart(context, stats),
              ),
            ),
            SliverToBoxAdapter(
              child: mostWorn.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (items) => items.isEmpty
                    ? const SizedBox.shrink()
                    : _buildGarmentList(
                        context, 'Most Worn', items, ref),
              ),
            ),
            SliverToBoxAdapter(
              child: leastWorn.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (items) => items.isEmpty
                    ? const SizedBox.shrink()
                    : _buildGarmentList(
                        context, 'Least Worn', items, ref),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _summaryCard(context,
              value: '$total',
              label: 'Total Items',
              icon: Icons.checkroom_outlined,
              color: AppColors.primary),
          const SizedBox(width: 12),
          _summaryCard(context,
              value: '0',
              label: 'Outfits Planned',
              icon: Icons.calendar_today_outlined,
              color: AppColors.info),
          const SizedBox(width: 12),
          _summaryCard(context,
              value: '—',
              label: 'Cost / Wear',
              icon: Icons.attach_money,
              color: AppColors.success),
        ],
      ).animate().fadeIn().slideY(begin: 0.1),
    );
  }

  Widget _summaryCard(BuildContext context,
      {required String value,
      required String label,
      required IconData icon,
      required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                  ),
            ),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(BuildContext context, Map<String, int> stats) {
    final total = stats.values.fold(0, (a, b) => a + b);
    final sections = stats.entries.map((e) {
      final pct = e.value / total;
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: categoryColor(e.key),
        title: pct > 0.08 ? '${(pct * 100).round()}%' : '',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        radius: 70,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wardrobe Breakdown',
                  style: Theme.of(context).textTheme.titleMedium)
              .animate()
              .fadeIn(delay: 100.ms),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 160,
                  width: 160,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: stats.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: categoryColor(e.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${e.value}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildGarmentList(BuildContext context, String title,
      List garments, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium)
              .animate()
              .fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: garments.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => SizedBox(
                width: 130,
                child: GarmentCard(
                  garment: garments[i],
                  index: i,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
