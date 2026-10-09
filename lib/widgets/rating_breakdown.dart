import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class RatingBreakdown extends StatelessWidget {
  final double averageRating;
  final int reviewCount;
  final List<int> individualRatings; // e.g. [5, 4, 5, 3, ...] from real reviews

  const RatingBreakdown({
    super.key,
    required this.averageRating,
    required this.reviewCount,
    this.individualRatings = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (reviewCount == 0) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Row(
          children: [
            Icon(Icons.star_border, color: AppColors.textMuted),
            SizedBox(width: AppSpacing.sm),
            Text('No reviews yet for this product.'),
          ],
        ),
      );
    }

    final counts = List<int>.filled(5, 0);
    for (final rating in individualRatings) {
      if (rating >= 1 && rating <= 5) counts[5 - rating]++;
    }
    final maxCount = counts.isEmpty
        ? 1
        : counts.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              averageRating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < averageRating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: AppColors.star,
                      size: 16,
                    ),
                  ),
                ),
                Text(
                  '$reviewCount review${reviewCount == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(5, (i) {
          final star = 5 - i;
          final fraction = maxCount == 0 ? 0.0 : counts[i] / maxCount;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    '$star',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Icon(Icons.star, color: AppColors.star, size: 12),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceMuted,
                      valueColor: const AlwaysStoppedAnimation(AppColors.star),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 20,
                  child: Text(
                    '${counts[i]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
