import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/filter_sheet.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer_box.dart';
import '../products/product_details_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  static const List<String> _popularSearches = [
    'Cement',
    'Bricks',
    'M-Sand',
    'TMT Steel',
    'Blue Metal',
    'Tiles',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    final recents = ref.read(recentSearchesProvider);
    if (!recents.contains(query)) {
      ref.read(recentSearchesProvider.notifier).state = [
        query,
        ...recents,
      ].take(8).toList();
    }
    ref.read(searchControllerProvider.notifier).onQueryChanged(query);
    _focusNode.unfocus();
  }

  String _sortLabel(SearchSortOption option) {
    switch (option) {
      case SearchSortOption.relevance:
        return 'Relevance';
      case SearchSortOption.priceLowHigh:
        return 'Price: Low to High';
      case SearchSortOption.priceHighLow:
        return 'Price: High to Low';
      case SearchSortOption.rating:
        return 'Rating';
      case SearchSortOption.newest:
        return 'Newest';
    }
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        final currentSort = ref.read(searchControllerProvider).sortOption;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sort by', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                ...SearchSortOption.values.map(
                  (option) => RadioListTile<SearchSortOption>(
                    value: option,
                    groupValue: currentSort,
                    title: Text(_sortLabel(option)),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(searchControllerProvider.notifier)
                            .updateSort(value);
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

  void _showFilterSheet() {
    final categoriesAsync = ref.read(categoriesProvider);
    final categories = categoriesAsync.value ?? [];
    final currentFilters = ref.read(searchControllerProvider).filters;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => FilterSheet(
        initialFilters: currentFilters,
        categories: categories,
        onApply: (filters) {
          ref.read(searchControllerProvider.notifier).updateFilters(filters);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);
    final recents = ref.watch(recentSearchesProvider);
    final wishlist = ref.watch(wishlistIdsProvider).value ?? {};
    final cartCount = ref.watch(cartCountProvider);
    final hasActiveFilters = !searchState.filters.isEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            onChanged: (value) => ref
                .read(searchControllerProvider.notifier)
                .onQueryChanged(value),
            onSubmitted: _submitSearch,
            decoration: InputDecoration(
              hintText: 'Search for cement, bricks, sand...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _controller.clear();
                        ref.read(searchControllerProvider.notifier).clear();
                        setState(() {});
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onTapOutside: (_) => _focusNode.unfocus(),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter / sort bar — only shown once there's a query
          if (searchState.query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showFilterSheet,
                      icon: Icon(
                        Icons.filter_list,
                        size: 18,
                        color: hasActiveFilters ? AppColors.primary : null,
                      ),
                      label: Text(
                        hasActiveFilters ? 'Filters (on)' : 'Filters',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: hasActiveFilters
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        side: BorderSide(
                          color: hasActiveFilters
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showSortSheet,
                      icon: const Icon(Icons.sort, size: 18),
                      label: Text(_sortLabel(searchState.sortOption)),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: searchState.query.isEmpty
                ? _buildSuggestions(recents)
                : _buildResults(searchState, wishlist, cartCount),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(List<String> recents) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (recents.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () =>
                    ref.read(recentSearchesProvider.notifier).state = [],
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recents
                .map(
                  (term) => ActionChip(
                    label: Text(term),
                    avatar: const Icon(Icons.history, size: 16),
                    onPressed: () {
                      _controller.text = term;
                      _submitSearch(term);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          'Popular Searches',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularSearches
              .map(
                (term) => ActionChip(
                  label: Text(term),
                  avatar: const Icon(Icons.trending_up, size: 16),
                  onPressed: () {
                    _controller.text = term;
                    _submitSearch(term);
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildResults(SearchState state, Set<String> wishlist, int cartCount) {
    if (state.isSearching) {
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

    if (state.error != null) {
      return Center(child: Text('Search failed: ${state.error}'));
    }

    final results = state.filteredResults;

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No results for "${state.query}"',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Try a different keyword or clear filters.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.62,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return ProductCard(
          imageUrl: product.imageUrl,
          name: product.name,
          heroTag: 'search_${product.id}',
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
                  heroTag: 'search_${product.id}',
                ),
              ),
            );
          },
          onWishlistTap: () {
            toggleWishlist(ref, product.id, wishlist.contains(product.id));
          },
          onAddToCart: () async {
            await addProductToCart(ref, product);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.name} added to cart')),
              );
            }
          },
        );
      },
    );
  }
}
