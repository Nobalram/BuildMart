import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/page_transitions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/recently_viewed_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/category_row.dart';
import '../../widgets/offers_strip.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer_box.dart';
import '../../widgets/premium/fade_slide_in.dart';
import '../../widgets/premium/section_header.dart';
import '../../widgets/premium/scale_on_tap.dart';
import '../../widgets/premium/empty_state.dart';
import '../../widgets/premium/premium_snack.dart';
import '../cart/cart_screen.dart';
import '../products/product_details_screen.dart';
import '../products/product_listing_screen.dart';
import '../profile/notifications_screen.dart';
import '../search/search_screen.dart';
import '../categories/categories_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(homeProductsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final wishlist = ref.watch(wishlistIdsProvider).value ?? {};
    final recentlyViewedAsync = ref.watch(recentlyViewedProductsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final currentCityAsync = ref.watch(currentCityProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeProductsProvider);
            ref.invalidate(categoriesProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        // Avatar with gradient ring
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: profileAsync.when(
                            data: (user) => CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                (user?.name.isNotEmpty == true
                                        ? user!.name[0]
                                        : '?')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            loading: () => const ShimmerBox(
                              width: 36,
                              height: 36,
                              borderRadius: 18,
                            ),
                            error: (_, _) => const CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primaryLight,
                              child: Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              profileAsync.when(
                                data: (user) => Text(
                                  'Hi, ${user?.name.split(' ').first ?? "there"}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                loading: () =>
                                    const ShimmerBox(width: 100, height: 14),
                                error: (_, _) => const Text('Hi there'),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: currentCityAsync.when(
                                      data: (city) => Text(
                                        city,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      loading: () => const ShimmerBox(
                                        width: 70,
                                        height: 12,
                                      ),
                                      error: (_, _) => Text(
                                        'Set location',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ScaleOnTap(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                          },
                          pressedScale: 0.9,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: AppDecors.card(
                              radius: AppRadius.md,
                              shadow: AppShadows.soft,
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Center(
                                  child: Icon(
                                    Icons.notifications_none_rounded,
                                    size: 22,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 9,
                                    top: 9,
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: 1),
                                      duration: const Duration(
                                        milliseconds: 420,
                                      ),
                                      curve: Curves.elasticOut,
                                      builder: (context, value, _) =>
                                          Transform.scale(
                                            scale: value,
                                            child: Container(
                                              width: 9,
                                              height: 9,
                                              decoration: BoxDecoration(
                                                color: AppColors.error,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.6,
                                                ),
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.md + 2),
                      boxShadow: AppShadows.glow(
                        AppColors.primary,
                        alpha: 0.20,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: TextField(
                          readOnly: true,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SearchScreen(),
                              ),
                            );
                          },
                          decoration: InputDecoration(
                            hintText: 'Search for cement, bricks, sand...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.textMuted,
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: SectionHeader(
                    title: 'Offers for You',
                    leadingIcon: Icons.local_offer_rounded,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
              const SliverToBoxAdapter(child: OffersStrip()),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              const SliverToBoxAdapter(child: BannerCarousel()),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverToBoxAdapter(
                child: recentlyViewedAsync.when(
                  data: (products) {
                    if (products.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Recently Viewed',
                          leadingIcon: Icons.history_rounded,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          height: 190,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            itemCount: products.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return SizedBox(
                                width: 130,
                                child: ProductCard(
                                  imageUrl: product.imageUrl,
                                  name: product.name,
                                  heroTag: 'popular_${product.id}',
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
                                      slideFadeRoute(
                                        ProductDetailsScreen(
                                          productId: product.id,
                                          heroImageUrl: product.imageUrl,
                                          heroTag: 'popular_${product.id}',
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
                                              builder: (_) =>
                                                  const CartScreen(),
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: SectionHeader(
                    title: 'Categories',
                    leadingIcon: Icons.grid_view_rounded,
                    actionLabel: 'See All',
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CategoriesScreen(),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
              SliverToBoxAdapter(
                child: categoriesAsync.when(
                  data: (categories) => CategoryRow(
                    categories: categories,
                    selectedCategoryName: selectedCategory,
                    onSelect: (name) =>
                        ref.read(selectedCategoryProvider.notifier).state =
                            name,
                  ),
                  loading: () => const SizedBox(
                    height: 92,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: EmptyState.error(
                      title: 'Could not load categories',
                      subtitle: '$e',
                      onRetry: () => ref.invalidate(categoriesProvider),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              // Products header
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                  boxShadow: AppShadows.colored(
                                    AppColors.primary,
                                    alpha: 0.25,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  selectedCategory ?? 'Popular Products',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            if (selectedCategory != null)
                              TextButton(
                                onPressed: () {
                                  ref
                                          .read(
                                            selectedCategoryProvider.notifier,
                                          )
                                          .state =
                                      null;
                                },
                                child: const Text('Clear'),
                              ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProductListingScreen(
                                      categoryName: selectedCategory,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                              ),
                              iconAlignment: IconAlignment.end,
                              label: const Text('View All'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
              productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Nothing here yet',
                        subtitle: 'No products found in this category yet - try another one.',
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.sm,
                            mainAxisSpacing: AppSpacing.sm,
                            childAspectRatio: 0.62,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = products[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 300 + (index * 60)),
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 20),
                              child: child,
                            ),
                          ),
                          child: ProductCard(
                            imageUrl: product.imageUrl,
                            name: product.name,
                            heroTag: 'recent_${product.id}',
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
                                slideFadeRoute(
                                  ProductDetailsScreen(
                                    productId: product.id,
                                    heroImageUrl: product.imageUrl,
                                    heroTag: 'recent_${product.id}',
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
                            onGoToCart: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CartScreen(),
                                ),
                              );
                            },
                          ),
                        );
                      }, childCount: products.length),
                    ),
                  );
                },
                loading: () => SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 0.62,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ProductCardShimmer(),
                      childCount: 4,
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: EmptyState.error(
                    title: 'Could not load products',
                    subtitle: '$e',
                    onRetry: () => ref.invalidate(homeProductsProvider),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }
}
