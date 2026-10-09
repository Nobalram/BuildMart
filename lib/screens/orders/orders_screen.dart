import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/order.dart';
import '../../providers/checkout_provider.dart';
import '../../widgets/premium/empty_state.dart';
import '../../widgets/premium/scale_on_tap.dart';
import 'order_details_screen.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.outForDelivery:
        return AppColors.info;
      case OrderStatus.preparing:
      case OrderStatus.confirmed:
        return AppColors.warning;
      case OrderStatus.pending:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(buyerOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState.error(
          title: 'Could not load orders',
          subtitle: '$e',
          onRetry: () => ref.invalidate(buyerOrdersProvider),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Your orders will show up here once you place one.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(buyerOrdersProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final order = orders[index];
                return ScaleOnTap(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailsScreen(orderId: order.id),
                      ),
                    );
                  },
                  pressedScale: 0.98,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: AppDecors.card(shadow: AppShadows.floating),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${(order.id.length >= 8 ? order.id.substring(0, 8) : order.id).toUpperCase()}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(order.status)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: Text(
                                orderStatusLabel(order.status),
                                style: TextStyle(
                                  color: _statusColor(order.status),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          order.items
                              .map((i) => '${i.productName} x${i.quantity}')
                              .join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${order.total.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
