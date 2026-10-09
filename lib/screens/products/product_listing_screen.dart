import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/product_listing_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/premium/empty_state.dart';
import '../../widgets/shimmer_box.dart';
import 'product_details_screen.dart';
import '../../providers/cart_provider.dart';

class ProductListingScreen extends ConsumerStatefulWidget {
  final String? categoryName;

  const ProductListingScreen({super.key, this.categoryName});

  @override
  ConsumerState<ProductListingScreen> createState() =>
      _ProductListingScreenState();
}

class _ProductListingScreenState extends ConsumerState<ProductListingScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productListingProvider(widget.categoryName).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  String _sortLabel(SortOption option) {
    switch (option) {
      case SortOption.newest:
        return 'Newest';
      case SortOption.priceLowHigh:
        return 'Price: Low to High';
      case SortOption.priceHighLow:
        return 'Price: High to Low';
      case SortOption.rating:
        return 'Rating';
    }
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        final currentSort = ref
            .read(productListingProvider(widget.categoryName))
            .sortOption;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sort by', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                ...SortOption.values.map(
                  (option) => RadioListTile<SortOption>(
                    value: option,
                    groupValue: currentSort,
                    title: Text(_sortLabel(option)),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(
                              productListingProvider(widget.categoryName)
                                  .notifier,
                            )
                            .changeSort(value);
                      }
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListingProvider(widget.categoryName));
    final wishlist = ref.watch(wishlistIdsProvider).value ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName ?? 'All Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onPressed: () => _showSortSheet(context),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.62,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => const ProductCardShimmer(),
            );
          }

          if (state.error != null && state.products.isEmpty) {
            return EmptyState.error(
              title: 'Could not load products',
              subtitle: '${state.error}',
              onRetry: () => ref
                  .read(productListingProvider(widget.categoryName).notifier)
                  .loadFirstPage(),
            );
          }

          if (state.products.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Nothing here yet',
              subtitle: 'No products found in this category yet.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref
                .read(productListingProvider(widget.categoryName).notifier)
                .loadFirstPage(),
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.62,
              ),
              itemCount: state.products.length + (state.hasMore ? 2 : 0),
              itemBuilder: (context, index) {
                if (index >= state.products.length) {
                  return const ProductCardShimmer();
                }

                final product = state.products[index];
                return ProductCard(
                  imageUrl: product.imageUrl,
                  name: product.name,
                  heroTag: 'listing_${product.id}',
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
                          heroTag: 'listing_${product.id}',
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart'),
                        ),
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
