import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/premium/empty_state.dart';
import '../../widgets/premium/premium_snack.dart';
import '../../widgets/shimmer_box.dart';
import '../cart/cart_screen.dart';
import '../products/product_details_screen.dart';

/// Fetches the full Product documents for a set of wishlisted IDs.
/// Firestore's whereIn supports up to 30 IDs per query, which comfortably
/// covers a typical wishlist size.
final wishlistedProductsProvider = StreamProvider<List<Product>>((ref) {
  final wishlistIds = ref.watch(wishlistIdsProvider).value ?? {};
  if (wishlistIds.isEmpty) return Stream.value(<Product>[]);

  return FirebaseFirestore.instance
      .collection('products')
      .where(FieldPath.documentId, whereIn: wishlistIds.take(30).toList())
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .toList(),
      );
});

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(wishlistedProductsProvider);
    final wishlist = ref.watch(wishlistIdsProvider).value ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: productsAsync.when(
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.62,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => const ProductCardShimmer(),
        ),
        error: (e, _) => EmptyState.error(
          title: 'Could not load wishlist',
          subtitle: '$e',
          onRetry: () => ref.invalidate(wishlistedProductsProvider),
        ),
        data: (products) {
          if (products.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border,
              title: 'Your wishlist is empty',
              subtitle: 'Tap the heart icon on any product to save it here.',
              accentColor: AppColors.error,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(wishlistedProductsProvider),
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.62,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  imageUrl: product.imageUrl,
                  name: product.name,
                  heroTag: 'wish_${product.id}',
                  price: product.discountedPrice,
                  unit: product.unit,
                  rating: product.rating,
                  discountPercent: product.discountPercent > 0
                      ? product.discountPercent
                      : null,
                  inStock: product.inStock,
                  isWishlisted: wishlist.contains(product.id),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsScreen(
                          productId: product.id,
                          heroImageUrl: product.imageUrl,
                          heroTag: 'wish_${product.id}',
                        ),
                      ),
                    );
                  },
                  onWishlistTap: () {
                    toggleWishlist(
                      ref,
                      product.id,
                      wishlist.contains(product.id),
                    );
                  },
                  onAddToCart: () async {
                    await addProductToCart(ref, product);
                    if (context.mounted) {
                      showAppSnack(
                        context,
                        '${product.name} added to cart',
                        kind: SnackKind.success,
                        actionLabel: 'VIEW',
                        onAction: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CartScreen(),
                            ),
                          );
                        },
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
