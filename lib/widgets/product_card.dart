import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/theme/app_theme.dart';
import 'premium/scale_on_tap.dart';
import 'shimmer_box.dart';

class ProductCard extends StatefulWidget {
  final String imageUrl;
  final String name;
  final String heroTag;
  final double price;
  final String unit;
  final double rating;
  final int? discountPercent;
  final bool inStock;
  final bool isWishlisted;
  final VoidCallback onTap;
  final VoidCallback onWishlistTap;
  final VoidCallback onAddToCart;
  final VoidCallback? onGoToCart;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.heroTag,
    required this.price,
    required this.unit,
    required this.rating,
    this.discountPercent,
    this.inStock = true,
    this.isWishlisted = false,
    required this.onTap,
    required this.onWishlistTap,
    required this.onAddToCart,
    this.onGoToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with TickerProviderStateMixin {
  bool _justAdded = false;
  late final AnimationController _heartController;
  late final Animation<double> _heartScale;
  late final AnimationController _cartController;
  late final Animation<double> _cartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _heartScale = TweenSequence(
      [
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 45),
        TweenSequenceItem(tween: Tween(begin: 1.45, end: 1.0), weight: 55),
      ],
    ).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeOut));

    _cartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _cartScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.12), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 35),
    ]).animate(CurvedAnimation(parent: _cartController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _heartController.dispose();
    _cartController.dispose();
    super.dispose();
  }

  void _handleWishlistTap() {
    HapticFeedback.lightImpact();
    _heartController.forward(from: 0);
    widget.onWishlistTap();
  }

  void _handleAddToCart() {
    HapticFeedback.mediumImpact();
    _cartController.forward(from: 0);
    widget.onAddToCart();
    setState(() => _justAdded = true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ScaleOnTap(
      onTap: widget.onTap,
      pressedScale: 0.975,
      haptic: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.floating,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: widget.heroTag,
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const ShimmerBox(
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 0,
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.subtleGradient,
                          ),
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // bottom scrim for legibility of overlaid content
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 64,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x14000000)],
                        ),
                      ),
                    ),
                  ),

                  if (widget.discountPercent != null &&
                      widget.discountPercent! > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          boxShadow: AppShadows.colored(AppColors.primary),
                        ),
                        child: Text(
                          '${widget.discountPercent}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                  Positioned(
                    top: 4,
                    right: 4,
                    child: ScaleTransition(
                      scale: _heartScale,
                      child: IconButton(
                        onPressed: _handleWishlistTap,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            widget.isWishlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            key: ValueKey(widget.isWishlisted),
                            color: widget.isWishlisted
                                ? AppColors.error
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.92),
                          minimumSize: const Size(32, 32),
                          elevation: 0,
                          shadowColor: Colors.black.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),

                  if (!widget.inStock)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: const Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.star.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.star,
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              widget.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: RichText(
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '₹${widget.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              TextSpan(
                                text: ' / ${widget.unit}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ScaleTransition(
                        scale: _cartScale,
                        child: ScaleOnTap(
                          haptic: false,
                          onTap: !widget.inStock
                              ? null
                              : (_justAdded
                                    ? widget.onGoToCart
                                    : _handleAddToCart),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: widget.inStock && !_justAdded
                                  ? AppColors.primaryGradient
                                  : null,
                              color: !widget.inStock
                                  ? AppColors.surfaceMuted
                                  : _justAdded
                                  ? AppColors.success
                                  : null,
                              borderRadius: BorderRadius.circular(
                                AppRadius.sm + 2,
                              ),
                              boxShadow: widget.inStock
                                  ? AppShadows.colored(
                                      _justAdded
                                          ? AppColors.success
                                          : AppColors.primary,
                                    )
                                  : null,
                            ),
                            child: Icon(
                              _justAdded
                                  ? Icons.shopping_bag_rounded
                                  : Icons.add_shopping_cart_rounded,
                              color: widget.inStock
                                  ? Colors.white
                                  : AppColors.textMuted,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
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
