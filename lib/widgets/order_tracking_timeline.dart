import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/order.dart';

class OrderTrackingTimeline extends StatelessWidget {
  final OrderStatus status;

  const OrderTrackingTimeline({super.key, required this.status});

  static const _steps = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  static const _stepLabels = {
    OrderStatus.pending: 'Order Placed',
    OrderStatus.confirmed: 'Confirmed',
    OrderStatus.preparing: 'Preparing',
    OrderStatus.outForDelivery: 'Out for Delivery',
    OrderStatus.delivered: 'Delivered',
  };

  static const _stepIcons = {
    OrderStatus.pending: Icons.receipt_long_outlined,
    OrderStatus.confirmed: Icons.check_circle_outline,
    OrderStatus.preparing: Icons.inventory_2_outlined,
    OrderStatus.outForDelivery: Icons.local_shipping_outlined,
    OrderStatus.delivered: Icons.home_outlined,
  };

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error),
            SizedBox(width: AppSpacing.sm),
            Text(
              'This order was cancelled.',
              style: TextStyle(color: AppColors.error),
            ),
          ],
        ),
      );
    }

    final currentIndex = _steps.indexOf(status);

    return Column(
      children: List.generate(_steps.length, (index) {
        final step = _steps[index];
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;
        final isLast = index == _steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: isCompleted ? 1 : 0),
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    builder: (context, value, child) => Transform.scale(
                      scale: 0.7 + (0.3 * value),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            AppColors.border,
                            AppColors.primary,
                            value,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _stepIcons[step],
                          size: 18,
                          color: Color.lerp(
                            AppColors.textMuted,
                            Colors.white,
                            value,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: index < currentIndex
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg, top: 6),
                  child: Text(
                    _stepLabels[step]!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCompleted
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
