import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/garment.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';

class GarmentCard extends StatelessWidget {
  const GarmentCard({
    super.key,
    required this.garment,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.index = 0,
  });

  final Garment garment;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: 200.ms,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildImage()),
            _buildInfo(context),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 40).ms, duration: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          garment.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: garment.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
                  errorWidget: (_, __, ___) => _buildPlaceholder(),
                )
              : _buildPlaceholder(),
          if (selected)
            Container(
              color: AppColors.primary.withOpacity(0.3),
              child: const Center(
                child: Icon(Icons.check_circle, color: AppColors.primary, size: 32),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: categoryColor(garment.category).withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                garment.category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Text(
          categoryIcon(garment.category),
          style: const TextStyle(fontSize: 40),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            garment.name,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (garment.brand != null) ...[
                Expanded(
                  child: Text(
                    garment.brand!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),
              Row(
                children: [
                  const Icon(Icons.repeat, size: 12, color: AppColors.textDisabled),
                  const SizedBox(width: 3),
                  Text(
                    '${garment.wearCount}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
