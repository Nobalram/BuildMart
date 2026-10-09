import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/premium/premium_snack.dart';
import '../../widgets/premium/scale_on_tap.dart';
import '../../widgets/quantity_input_dialog.dart';
import '../../widgets/shimmer_box.dart';
import '../../widgets/rating_breakdown.dart';
import '../../providers/review_provider.dart';
import '../../providers/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../../providers/recently_viewed_provider.dart';
import '../checkout/checkout_screen.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;
  final String? heroImageUrl;

  /// Tag of the Hero on the card that opened this screen, so the flight
  /// animates between exactly that card and this page. Must be unique per
  /// card instance — duplicate Hero tags in one route throw on navigation.
  final String? heroTag;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    this.heroImageUrl,
    this.heroTag,
  });

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  final _imageController = PageController();
  int _currentImage = 0;
  int _quantity = 1;
  bool _justAdded = false;
  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailsProvider(widget.productId));
    final wishlist = ref.watch(wishlistIdsProvider).value ?? {};

    return Scaffold(
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load product: $e')),
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Product not found.'));
          }

          // Record this view once per build cycle, after the frame —
          // avoids calling setState-equivalent logic during build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(recentlyViewedIdsProvider.notifier).recordView(product.id);
          });

          final isWishlisted = wishlist.contains(product.id);
          _quantity = _quantity.clamp(product.minimumOrder, 999).toInt();

          return CustomScrollView(
            slivers: [
              // Image carousel app bar
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                actions: [
                  IconButton(
                    icon: Icon(
                      isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: isWishlisted ? AppColors.error : null,
                    ),
                    onPressed: () {
                      toggleWishlist(
                        ref,
                        product.id,
                        wishlist.contains(product.id),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Positioned.fill(
                        child: Hero(
                          tag:
                              widget.heroTag ??
                              'product_image_${widget.heroImageUrl ?? product.imageUrl}${product.name}',
                          child: PageView.builder(
                            controller: _imageController,
                            onPageChanged: (i) =>
                                setState(() => _currentImage = i),
                            itemCount: product.galleryImages.length,
                            itemBuilder: (context, index) => CachedNetworkImage(
                              imageUrl: product.galleryImages[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const ShimmerBox(
                                width: double.infinity,
                                height: double.infinity,
                                borderRadius: 0,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.surfaceMuted,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (product.galleryImages.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              product.galleryImages.length,
                              (index) {
                                final active = index == _currentImage;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: active ? 18 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? Colors.white
                                        : Colors.white54,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Details body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                              ],
                            ),
                          ),
                          if (product.discountPercent > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: Text(
                                '${product.discountPercent}% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: AppColors.star,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${product.rating}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${product.reviewCount} reviews',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            product.inStock ? 'In Stock' : 'Out of Stock',
                            style: TextStyle(
                              color: product.inStock
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        'Ratings & Reviews',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Consumer(
                        builder: (context, ref, _) {
                          final reviewsAsync = ref.watch(
                            productReviewsProvider(product.id),
                          );
                          final reviews = reviewsAsync.value ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RatingBreakdown(
                                averageRating: product.rating,
                                reviewCount: product.reviewCount,
                                individualRatings: reviews
                                    .map((r) => r.rating)
                                    .toList(),
                              ),
                              if (reviews.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                ...reviews
                                    .take(5)
                                    .map(
                                      (review) => Container(
                                        margin: const EdgeInsets.only(
                                          bottom: AppSpacing.sm,
                                        ),
                                        padding: const EdgeInsets.all(
                                          AppSpacing.md,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceMuted,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    review.buyerName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: AppSpacing.sm,
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: List.generate(
                                                    5,
                                                    (i) => Icon(
                                                      i < review.rating
                                                          ? Icons.star
                                                          : Icons.star_border,
                                                      color: AppColors.star,
                                                      size: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (review.reviewText != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                review.reviewText!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium,
                                              ),
                                            ],
                                            if (review.photoUrl != null) ...[
                                              const SizedBox(
                                                height: AppSpacing.sm,
                                              ),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppRadius.sm,
                                                    ),
                                                child: Image.network(
                                                  review.photoUrl!,
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Specifications
                      const Divider(),
                      const SizedBox(height: AppSpacing.md),

                      // Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${product.discountedPrice.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '/ ${product.unit}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (product.discountPercent > 0) ...[
                            const SizedBox(width: 10),
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Quantity selector
                      Text(
                        'Quantity',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          _QuantityButton(
                            icon: Icons.remove,
                            onTap: _quantity > product.minimumOrder
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          ScaleOnTap(
                            onTap: () async {
                              final value = await showQuantityInputDialog(
                                context,
                                initial: _quantity,
                                min: product.minimumOrder,
                                max: product.stock > 0 ? product.stock : 999,
                                unit: product.unit,
                                title: 'Enter quantity',
                              );
                              if (value == null || !mounted) return;
                              setState(() => _quantity = value);
                            },
                            pressedScale: 0.94,
                            child: Container(
                              width: 56,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                '$_quantity',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ),
                          _QuantityButton(
                            icon: Icons.add,
                            onTap: _quantity < product.stock
                                ? () => setState(() => _quantity++)
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Flexible(
                            child: Text(
                              'Min order: ${product.minimumOrder} ${product.unit}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.md),

                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        product.description?.isNotEmpty == true
                            ? product.description!
                            : 'No description provided by the seller yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Specifications
                      if (product.specifications.isNotEmpty) ...[
                        Text(
                          'Specifications',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...product.specifications.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 130,
                                  child: Text(
                                    entry.key,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Delivery info
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                product.deliveryCharge > 0
                                    ? 'Delivery charge: ₹${product.deliveryCharge.toStringAsFixed(0)}'
                                    : 'Free delivery on this item',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: productAsync.maybeWhen(
        data: (product) {
          if (product == null) return null;
          return Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 22,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: _justAdded ? 'Go to Cart' : 'Add to Cart',
                      type: AppButtonType.outlined,
                      icon: _justAdded
                          ? Icons.arrow_forward
                          : Icons.add_shopping_cart,
                      onPressed: !product.inStock
                          ? null
                          : (_justAdded
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const CartScreen(),
                                      ),
                                    );
                                  }
                                : () async {
                                    await addProductToCart(
                                      ref,
                                      product,
                                      quantity: _quantity,
                                    );
                                    if (context.mounted) {
                                      setState(() => _justAdded = true);
                                      showAppSnack(
                                        context,
                                        '${product.name} added to cart',
                                        kind: SnackKind.success,
                                        actionLabel: 'VIEW',
                                        onAction: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const CartScreen(),
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  }),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Buy Now',
                      type: AppButtonType.gradient,
                      icon: Icons.flash_on_rounded,
                      onPressed: product.inStock
                          ? () async {
                              await addProductToCart(
                                ref,
                                product,
                                quantity: _quantity,
                              );
                              if (context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CheckoutScreen(),
                                  ),
                                );
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.surfaceMuted : AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}
