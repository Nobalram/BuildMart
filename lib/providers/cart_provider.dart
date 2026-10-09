import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../repositories/cart_repository.dart';
import 'auth_provider.dart';
import 'checkout_provider.dart';

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepository(),
);

final cartItemsProvider = StreamProvider<List<CartItem>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(<CartItem>[]);
  return ref.watch(cartRepositoryProvider).watchCart(uid);
});

final cartCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartItemsProvider).value ?? [];
  return items.fold(0, (sum, item) => sum + item.quantity);
});

final cartSubtotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartItemsProvider).value ?? [];
  return items.fold(0.0, (sum, item) => sum + item.lineTotal);
});

/// Distance-based transport fee: (distance_km / mileage) * fuel_cost,
/// summed per distinct seller in the cart, using the buyer's selected
/// delivery address. Waived entirely if the buyer opted to arrange
/// their own transport, or if the order subtotal clears the free
/// delivery threshold.
final cartTransportFeeProvider = Provider<double>((ref) {
  final selfArrange = ref.watch(selfArrangeTransportProvider);
  final subtotal = ref.watch(cartSubtotalProvider);
  final config = ref.watch(platformConfigProvider).value;
  if (config == null) return 0;
  if (selfArrange) return 0;
  if (subtotal >= config.freeDeliveryThreshold) return 0;

  final items = ref.watch(cartItemsProvider).value ?? [];
  final addresses = ref.watch(addressesProvider).value ?? [];
  final selectedId = ref.watch(selectedAddressIdProvider);
  final address =
      addresses.where((a) => a.id == selectedId).firstOrNull ??
      addresses.where((a) => a.isDefault).firstOrNull;

  if (address?.latitude == null || address?.longitude == null) return 0;

  final sellersSeen = <String>{};
  double totalFee = 0;
  for (final item in items) {
    if (sellersSeen.contains(item.sellerId)) continue;
    sellersSeen.add(item.sellerId);
    if (item.sellerLat == null || item.sellerLng == null) continue;

    final distanceMeters = Geolocator.distanceBetween(
      address!.latitude!,
      address.longitude!,
      item.sellerLat!,
      item.sellerLng!,
    );
    final distanceKm = distanceMeters / 1000;
    final liters = distanceKm / config.mileageKmPerLiter;
    totalFee += liters * config.fuelCostPerLiter;
  }
  return totalFee;
});

final cartPlatformFeeProvider = Provider<double>((ref) {
  final config = ref.watch(platformConfigProvider).value;
  return config?.platformFee ?? 29;
});

final cartTaxProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final config = ref.watch(platformConfigProvider).value;
  final rate = (config?.taxPercent ?? 18) / 100;
  return subtotal * rate;
});

final cartGrandTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final transport = ref.watch(cartTransportFeeProvider);
  final platformFee = ref.watch(cartPlatformFeeProvider);
  final tax = ref.watch(cartTaxProvider);
  return subtotal + transport + platformFee + tax;
});

Future<void> addProductToCart(
  WidgetRef ref,
  Product product, {
  int quantity = 1,
}) async {
  final uid = ref.read(authStateProvider).value?.uid;
  if (uid == null) return;
  await ref
      .read(cartRepositoryProvider)
      .addToCart(uid, product, quantity: quantity);
}
