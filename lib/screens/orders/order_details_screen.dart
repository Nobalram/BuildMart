import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/order_tracking_timeline.dart';
import 'invoice_screen.dart';
import '../../providers/review_provider.dart';
import '../reviews/write_review_screen.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  bool _isCancelling = false;
  bool _isReordering = false;

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text(
          'Stock will be restored and this cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      await ref.read(orderRepositoryProvider).cancelOrder(widget.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Order cancelled.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _reorder(AppOrder order) async {
    setState(() => _isReordering = true);
    final repo = ref.read(productRepositoryProvider);
    final cartRepo = ref.read(cartRepositoryProvider);
    final uid = ref.read(authStateProvider).value?.uid;

    if (uid == null) {
      setState(() => _isReordering = false);
      return;
    }

    int addedCount = 0;
    int skippedCount = 0;

    for (final item in order.items) {
      // Fetch the product's CURRENT price/stock — never trust the
      // old order's snapshot, since price or availability may have
      // changed since this order was originally placed.
      final Product? product = await repo.watchProduct(item.productId).first;
      if (product == null || !product.inStock) {
        skippedCount++;
        continue;
      }
      await cartRepo.addToCart(uid, product, quantity: item.quantity);
      addedCount++;
    }

    if (!mounted) return;
    setState(() => _isReordering = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          skippedCount > 0
              ? '$addedCount item(s) added to cart. $skippedCount unavailable.'
              : '$addedCount item(s) added to cart.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailsProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load order: $e')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found.'));
          }

          final canCancel =
              order.status == OrderStatus.pending ||
              order.status == OrderStatus.confirmed;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${(order.id.length >= 8 ? order.id.substring(0, 8) : order.id).toUpperCase()}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.receipt_outlined, size: 18),
                    label: const Text('Invoice'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InvoiceScreen(order: order),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Text(
                'Placed on ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('Tracking', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              OrderTrackingTimeline(status: order.status),
              const SizedBox(height: AppSpacing.md),

              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: order.items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.productName} x${item.quantity} ${item.unit}',
                                ),
                              ),
                              Text('₹${item.lineTotal.toStringAsFixed(0)}'),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'Delivery Address',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${order.addressLine}, ${order.city}, ${order.state} - ${order.pincode}',
              ),
              const SizedBox(height: AppSpacing.md),

              const SizedBox(height: AppSpacing.sm),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Paid',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '₹${order.total.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              if (canCancel)
                AppButton(
                  label: 'Cancel Order',
                  type: AppButtonType.outlined,
                  isLoading: _isCancelling,
                  onPressed: _cancelOrder,
                ),
              if (order.status == OrderStatus.delivered) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Rate Your Items',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...order.items.map(
                  (item) => _ReviewableItemTile(orderId: order.id, item: item),
                ),
              ],
              if (order.status == OrderStatus.delivered ||
                  order.status == OrderStatus.cancelled) ...[
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Reorder',
                  type: AppButtonType.gradient,
                  icon: Icons.replay,
                  isLoading: _isReordering,
                  onPressed: () => _reorder(order),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewableItemTile extends ConsumerWidget {
  final String orderId;
  final OrderLineItem item;

  const _ReviewableItemTile({required this.orderId, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existingAsync = ref.watch(
      existingReviewProvider((orderId: orderId, productId: item.productId)),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.network(
              item.imageUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              item.productName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          existingAsync.when(
            loading: () => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (existing) => TextButton.icon(
              icon: Icon(
                existing != null ? Icons.edit_outlined : Icons.star_border,
                size: 16,
              ),
              label: Text(existing != null ? 'Edit' : 'Review'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WriteReviewScreen(
                      orderId: orderId,
                      productId: item.productId,
                      productName: item.productName,
                      productImageUrl: item.imageUrl,
                      existingReview: existing,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
