import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../repositories/wishlist_repository.dart';
import 'auth_provider.dart';

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(),
);
final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => WishlistRepository(),
);

final categoriesProvider = StreamProvider<List<ProductCategory>>((ref) {
  return ref.watch(productRepositoryProvider).watchCategories();
});

/// Selected category filter for the Home page product grid.
/// Null means "show all products".
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final homeProductsProvider = StreamProvider<List<Product>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  return ref
      .watch(productRepositoryProvider)
      .watchProducts(categoryName: category);
});

/// One live-updating provider per productId — used by the Product
/// Details screen. .family lets each product keep its own stream.
final productDetailsProvider = StreamProvider.family<Product?, String>((
  ref,
  productId,
) {
  return ref.watch(productRepositoryProvider).watchProduct(productId);
});

/// Real, Firestore-backed wishlist — replaces the old in-memory Set.
/// Persists across app restarts and would sync across devices.
final wishlistIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(<String>{});
  return ref.watch(wishlistRepositoryProvider).watchWishlistIds(uid);
});

/// Helper used by product cards everywhere — toggles wishlist state
/// for the signed-in buyer.
Future<void> toggleWishlist(
  WidgetRef ref,
  String productId,
  bool isCurrentlyWishlisted,
) async {
  final uid = ref.read(authStateProvider).value?.uid;
  if (uid == null) return;
  await ref
      .read(wishlistRepositoryProvider)
      .toggle(uid, productId, isCurrentlyWishlisted);
}
