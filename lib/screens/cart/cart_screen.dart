import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_theme.dart';
import '../../models/cart_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/premium/empty_state.dart';
import '../../widgets/premium/scale_on_tap.dart';
import '../../widgets/quantity_input_dialog.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartItemsProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final transportFee = ref.watch(cartTransportFeeProvider);
    final platformFee = ref.watch(cartPlatformFeeProvider);
    final tax = ref.watch(cartTaxProvider);
    final grandTotal = ref.watch(cartGrandTotalProvider);
    final uid = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          cartAsync.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear cart?'),
                          content: const Text(
                            'This removes all items from your cart.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                if (uid != null) {
                                  await ref
                                      .read(cartRepositoryProvider)
                                      .clearCart(uid);
                                }
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Clear'),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState.error(
          title: 'Could not load cart',
          subtitle: '$e',
          onRetry: () => ref.invalidate(cartItemsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              subtitle: 'Browse products and add items to get started.',
            );
          }

          // Group items by seller so each seller's sub-order and its
          // own delivery charge are visually clear (matches how orders
          // will be split per-seller at checkout).
          final Map<String, List<CartItem>> grouped = {};
          for (final item in items) {
            grouped.putIfAbsent(item.sellerId, () => []).add(item);
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: grouped.entries.map((entry) {
                    final sellerItems = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.local_shipping_outlined,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Shipment',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ...sellerItems.map(
                            (item) => Dismissible(
                              key: ValueKey(item.productId),
                              direction: uid == null
                                  ? DismissDirection.none
                                  : DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.lg,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: AppColors.error,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Remove',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              confirmDismiss: (_) async {
                                final confirmed =
                                    await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.lg,
                                          ),
                                        ),
                                        title: const Text('Remove item?'),
                                        content: Text(
                                          '"${item.productName}" will be removed from your cart.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              'Remove',
                                              style: TextStyle(
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                                if (!confirmed || uid == null) return false;
                                await ref
                                    .read(cartRepositoryProvider)
                                    .removeItem(uid, item.productId);
                                return true;
                              },
                              child: _CartItemTile(item: item, uid: uid),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Order summary
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SummaryRow(label: 'Subtotal', value: subtotal),
                      _SummaryRow(label: 'Transport Fee', value: transportFee),
                      _SummaryRow(label: 'Platform Fee', value: platformFee),
                      _SummaryRow(label: 'Tax', value: tax),
                      const Divider(),
                      _SummaryRow(
                        label: 'Total',
                        value: grandTotal,
                        isBold: true,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Proceed to Checkout',
                        type: AppButtonType.gradient,
                        icon: Icons.arrow_forward_rounded,
                        animateIn: true,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CheckoutScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;
  final String? uid;

  const _CartItemTile({required this.item, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                width: 64,
                height: 64,
                color: AppColors.surfaceMuted,
                child: const Icon(Icons.image_not_supported_outlined, size: 20),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '₹${item.unitPrice.toStringAsFixed(0)} / ${item.unit}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      '₹${item.lineTotal.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                if (item.quantity >= item.availableStock)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Max stock reached',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _StepButton(
                      icon: Icons.remove,
                      onTap: uid == null
                          ? null
                          : () => ref
                                .read(cartRepositoryProvider)
                                .updateQuantity(
                                  uid!,
                                  item.productId,
                                  item.quantity - 1,
                                ),
                    ),
                    ScaleOnTap(
                      onTap: uid == null || item.availableStock <= 0
                          ? null
                          : () async {
                              final value = await showQuantityInputDialog(
                                context,
                                initial: item.quantity,
                                min: 1,
                                max: item.availableStock,
                                unit: item.unit,
                              );
                              if (value == null || !context.mounted) return;
                              ref
                                  .read(cartRepositoryProvider)
                                  .updateQuantity(uid!, item.productId, value);
                            },
                      pressedScale: 0.92,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 44),
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    _StepButton(
                      icon: Icons.add,
                      onTap:
                          (uid == null || item.quantity >= item.availableStock)
                          ? null
                          : () => ref
                                .read(cartRepositoryProvider)
                                .updateQuantity(
                                  uid!,
                                  item.productId,
                                  item.quantity + 1,
                                ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 20,
            ),
            onPressed: uid == null
                ? null
                : () => ref
                      .read(cartRepositoryProvider)
                      .removeItem(uid!, item.productId),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.surfaceMuted : AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₹${value.toStringAsFixed(0)}', style: style),
        ],
      ),
    );
  }
}
