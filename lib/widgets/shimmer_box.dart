import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_theme.dart';

/// A grey animated placeholder box — used while product images,
/// lists, or dashboard data are still loading from Firestore.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceMuted,
      highlightColor: AppColors.border,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A ready-made shimmer skeleton shaped like a product card —
/// drop this into a GridView while products are loading.
class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ShimmerBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: AppRadius.md,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const ShimmerBox(width: 100, height: 14),
          const SizedBox(height: AppSpacing.xs),
          const ShimmerBox(width: 60, height: 14),
        ],
      ),
    );
  }
}
