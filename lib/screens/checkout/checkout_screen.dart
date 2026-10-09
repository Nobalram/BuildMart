import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/address.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/premium/empty_state.dart';
import '../../widgets/premium/fade_slide_in.dart';
import 'add_address_screen.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isPlacingOrder = false;
  String? _errorMessage;

  Future<void> _placeOrder() async {
    final uid = ref.read(authStateProvider).value?.uid;
    final userProfile = ref.read(currentUserProfileProvider).value;
    final addresses = ref.read(addressesProvider).value ?? [];
    final selectedAddressId = ref.read(selectedAddressIdProvider);
    final cartItems = ref.read(cartItemsProvider).value ?? [];
    final paymentMethod = ref.read(selectedPaymentMethodProvider);
    final selfArrange = ref.read(selfArrangeTransportProvider);
    final config = ref.read(platformConfigProvider).value;

    if (uid == null || userProfile == null || config == null) return;

    final address = addresses
        .where((a) => a.id == selectedAddressId)
        .firstOrNull;
    if (address == null) {
      setState(() => _errorMessage = 'Please select a delivery address.');
      return;
    }
    if (cartItems.isEmpty) {
      setState(() => _errorMessage = 'Your cart is empty.');
      return;
    }

    setState(() {
      _isPlacingOrder = true;
      _errorMessage = null;
    });

    try {
      final orderIds = await ref
          .read(orderRepositoryProvider)
          .placeOrder(
            buyerId: uid,
            buyerName: userProfile.name,
            buyerPhone: userProfile.phoneNumber,
            cartItems: cartItems,
            address: address,
            paymentMethod: paymentMethod,
            taxPercent: config.taxPercent,
            platformFee: config.platformFee,
            mileageKmPerLiter: config.mileageKmPerLiter,
            fuelCostPerLiter: config.fuelCostPerLiter,
            freeDeliveryThreshold: config.freeDeliveryThreshold,
            selfArrangedTransport: selfArrange,
          );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(orderCount: orderIds.length),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      setState(() {
        _isPlacingOrder = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(addressesProvider);
    final selectedAddressId = ref.watch(selectedAddressIdProvider);
    final paymentMethod = ref.watch(selectedPaymentMethodProvider);
    final selfArrange = ref.watch(selfArrangeTransportProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final transportFee = ref.watch(cartTransportFeeProvider);
    final platformFee = ref.watch(cartPlatformFeeProvider);
    final tax = ref.watch(cartTaxProvider);
    final total = ref.watch(cartGrandTotalProvider);
    final cartItems = ref.watch(cartItemsProvider).value ?? [];
    final config = ref.watch(platformConfigProvider).value;
    final qualifiesFreeDelivery =
        config != null && subtotal >= config.freeDeliveryThreshold;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FadeSlideIn(
            child: _SectionTitle(
              icon: Icons.location_on_rounded,
              title: 'Delivery Address',
              action: TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddAddressScreen()),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          addressesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState.error(
              title: 'Could not load addresses',
              subtitle: '$e',
              onRetry: () => ref.invalidate(addressesProvider),
            ),
            data: (addresses) {
              if (addresses.isEmpty) {
                return const EmptyState(
                  icon: Icons.location_off_outlined,
                  title: 'No saved addresses yet',
                  subtitle: 'Tap "Add New" to add your site address.',
                );
              }
              if (selectedAddressId == null) {
                final defaultAddr = addresses.firstWhere(
                  (a) => a.isDefault,
                  orElse: () => addresses.first,
                );
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(selectedAddressIdProvider.notifier).state =
                      defaultAddr.id;
                });
              }
              return Column(
                children: addresses.map((address) {
                  final selected = address.id == selectedAddressId;
                  return _AddressCard(
                    address: address,
                    selected: selected,
                    onTap: () =>
                        ref.read(selectedAddressIdProvider.notifier).state =
                            address.id,
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          FadeSlideIn(
            child: _SectionTitle(
              icon: Icons.local_shipping_rounded,
              title: 'Transport',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (qualifiesFreeDelivery)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.14),
                    AppColors.success.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.28),
                ),
                boxShadow: AppShadows.colored(
                  AppColors.success,
                  alpha: 0.14,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_shipping, color: AppColors.success),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Your order qualifies for FREE delivery!',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                _TransportOption(
                  label: 'BuildMart Delivery',
                  subtitle:
                      'Fee calculated by distance: ₹${transportFee.toStringAsFixed(0)}',
                  icon: Icons.local_shipping_outlined,
                  selected: !selfArrange,
                  onTap: () =>
                      ref.read(selfArrangeTransportProvider.notifier).state =
                          false,
                ),
                const SizedBox(height: AppSpacing.sm),
                _TransportOption(
                  label: 'I will arrange transport myself',
                  subtitle: 'No transport fee — you handle pickup/delivery',
                  icon: Icons.person_pin_circle_outlined,
                  selected: selfArrange,
                  onTap: () =>
                      ref.read(selfArrangeTransportProvider.notifier).state =
                          true,
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.lg),

          FadeSlideIn(
            child: _SectionTitle(
              icon: Icons.receipt_long_rounded,
              title: 'Order Summary',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: AppDecors.card(shadow: AppShadows.floating),
            child: Column(
              children: [
                ...cartItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.productName,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        _QtyStepper(
                          quantity: item.quantity,
                          maxQuantity: item.availableStock,
                          onChanged: (newQty) {
                            final uid = ref.read(authStateProvider).value?.uid;
                            if (uid != null) {
                              ref
                                  .read(cartRepositoryProvider)
                                  .updateQuantity(uid, item.productId, newQty);
                            }
                          },
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: 64,
                          child: Text(
                            '₹${item.lineTotal.toStringAsFixed(0)}',
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                _SummaryLine(label: 'Subtotal', value: subtotal),
                _SummaryLine(label: 'Transport Fee', value: transportFee),
                _SummaryLine(label: 'Platform Fee', value: platformFee),
                _SummaryLine(
                  label:
                      'Tax (${config?.taxPercent.toStringAsFixed(0) ?? 18}%)',
                  value: tax,
                ),
                const Divider(),
                _SummaryLine(label: 'Total', value: total, isBold: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Payment Method', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          _PaymentOption(
            label: 'Cash on Delivery',
            icon: Icons.payments_outlined,
            selected: paymentMethod == PaymentMethod.cod,
            onTap: () =>
                ref.read(selectedPaymentMethodProvider.notifier).state =
                    PaymentMethod.cod,
          ),
          const SizedBox(height: AppSpacing.sm),
          _PaymentOption(
            label: 'Online Payment (Card / UPI)',
            icon: Icons.credit_card,
            selected: paymentMethod == PaymentMethod.online,
            enabled: false,
            trailingLabel: 'Coming soon',
            onTap: () {},
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Place Order',
            type: AppButtonType.gradient,
            isLoading: _isPlacingOrder,
            onPressed: _placeOrder,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _TransportOption extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TransportOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final bool selected;
  final VoidCallback onTap;
  const _AddressCard({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.fullName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    address.formatted,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    address.phoneNumber,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected, enabled;
  final String? trailingLabel;
  final VoidCallback onTap;
  const _PaymentOption({
    required this.label,
    required this.icon,
    required this.selected,
    this.enabled = true,
    this.trailingLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (trailingLabel != null)
                Text(
                  trailingLabel!,
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;
  const _QtyStepper({
    required this.quantity,
    required this.maxQuantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepBtn(
          Icons.remove,
          quantity > 1 ? () => onChanged(quantity - 1) : null,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        _stepBtn(
          Icons.add,
          quantity < maxQuantity ? () => onChanged(quantity + 1) : null,
        ),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.surfaceMuted : AppColors.border,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap != null ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? action;
  const _SectionTitle({
    required this.icon,
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?action,
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  const _SummaryLine({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? Theme.of(context).textTheme.titleMedium
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
