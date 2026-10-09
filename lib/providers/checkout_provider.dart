import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/address.dart';
import '../models/order.dart';
import '../models/platform_config.dart';
import '../repositories/address_repository.dart';
import '../repositories/order_repository.dart';
import 'auth_provider.dart';

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepository(),
);
final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(),
);
final configRepositoryProvider = Provider<ConfigRepository>(
  (ref) => ConfigRepository(),
);

final platformConfigProvider = StreamProvider<PlatformConfig>((ref) {
  return ref.watch(configRepositoryProvider).watchConfig();
});

final addressesProvider = StreamProvider<List<Address>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(<Address>[]);
  return ref.watch(addressRepositoryProvider).watchAddresses(uid);
});

final selectedAddressIdProvider = StateProvider<String?>((ref) => null);
final selectedPaymentMethodProvider = StateProvider<PaymentMethod>(
  (ref) => PaymentMethod.cod,
);

/// True = buyer will arrange their own pickup/transport (fee = 0).
/// False = BuildMart-calculated transport fee applies.
final selfArrangeTransportProvider = StateProvider<bool>((ref) => false);

final buyerOrdersProvider = StreamProvider<List<AppOrder>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(<AppOrder>[]);
  return ref.watch(orderRepositoryProvider).watchBuyerOrders(uid);
});

final orderDetailsProvider = StreamProvider.family<AppOrder?, String>((
  ref,
  orderId,
) {
  return ref.watch(orderRepositoryProvider).watchOrder(orderId);
});
