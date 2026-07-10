import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/outfit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';

class OutfitCard extends StatelessWidget {
  const OutfitCard({
    super.key,
    required this.outfit,
    this.onTap,
    this.index = 0,
  });

  final Outfit outfit;
  final VoidCallback? onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildGarmentGrid()),
            _buildInfo(context),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildGarmentGrid() {
    final garments = outfit.garments.take(4).toList();
    if (garments.isEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Container(
          color: AppColors.surfaceVariant,
          child: const Center(
            child: Icon(Icons.checkroom_outlined,
                color: AppColors.textDisabled, size: 36),
          ),
        ),
      );
    }

    if (garments.length == 1) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: _buildGarmentImage(garments[0].coverImageUrl),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        children: garments
            .take(4)
            .map((g) => _buildGarmentImage(g.coverImageUrl))
            .toList(),
      ),
    );
  }

  Widget _buildGarmentImage(String? url) {
    if (url == null) {
      return Container(color: AppColors.surfaceVariant);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
      errorWidget: (_, __, ___) =>
          Container(color: AppColors.surfaceVariant),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            outfit.name,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (outfit.occasion != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    outfit.occasion!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                '${outfit.garments.length} items',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OutfitSuggestionCard extends StatelessWidget {
  const OutfitSuggestionCard({
    super.key,
    required this.name,
    required this.description,
    required this.occasion,
    required this.tip,
    required this.garmentCount,
    this.onSave,
    this.index = 0,
  });

  final String name;
  final String description;
  final String occasion;
  final String tip;
  final int garmentCount;
  final VoidCallback? onSave;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.card,
            AppColors.primary.withOpacity(0.04),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      occasion,
                      style: const TextStyle(
                          color: AppColors.primary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (onSave != null)
                IconButton(
                  icon: const Icon(Icons.bookmark_outline,
                      color: AppColors.primary),
                  onPressed: onSave,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: AppColors.warning, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$garmentCount items from your wardrobe',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 100).ms, duration: 400.ms)
        .slideX(begin: 0.05, end: 0);
  }
}
