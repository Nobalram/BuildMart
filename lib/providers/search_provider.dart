import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import 'product_provider.dart';

class ProductFilters {
  final double? minPrice;
  final double? maxPrice;
  final String? category;
  final double? minRating;
  final bool inStockOnly;

  const ProductFilters({
    this.minPrice,
    this.maxPrice,
    this.category,
    this.minRating,
    this.inStockOnly = false,
  });

  bool get isEmpty =>
      minPrice == null &&
      maxPrice == null &&
      category == null &&
      minRating == null &&
      !inStockOnly;

  ProductFilters copyWith({
    double? minPrice,
    double? maxPrice,
    String? category,
    double? minRating,
    bool? inStockOnly,
    bool clearCategory = false,
  }) {
    return ProductFilters(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      category: clearCategory ? null : (category ?? this.category),
      minRating: minRating ?? this.minRating,
      inStockOnly: inStockOnly ?? this.inStockOnly,
    );
  }

  bool matches(Product product) {
    if (minPrice != null && product.discountedPrice < minPrice!) return false;
    if (maxPrice != null && product.discountedPrice > maxPrice!) return false;
    if (category != null && product.categoryName != category) return false;
    if (minRating != null && product.rating < minRating!) return false;
    if (inStockOnly && !product.inStock) return false;
    return true;
  }
}

enum SearchSortOption { relevance, priceLowHigh, priceHighLow, rating, newest }

class SearchState {
  final String query;
  final List<Product> results;
  final bool isSearching;
  final String? error;
  final ProductFilters filters;
  final SearchSortOption sortOption;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.error,
    this.filters = const ProductFilters(),
    this.sortOption = SearchSortOption.relevance,
  });

  List<Product> get filteredResults {
    var list = results.where(filters.matches).toList();
    switch (sortOption) {
      case SearchSortOption.priceLowHigh:
        list.sort((a, b) => a.discountedPrice.compareTo(b.discountedPrice));
        break;
      case SearchSortOption.priceHighLow:
        list.sort((a, b) => b.discountedPrice.compareTo(a.discountedPrice));
        break;
      case SearchSortOption.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SearchSortOption.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SearchSortOption.relevance:
        break;
    }
    return list;
  }

  SearchState copyWith({
    String? query,
    List<Product>? results,
    bool? isSearching,
    String? error,
    ProductFilters? filters,
    SearchSortOption? sortOption,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      error: error,
      filters: filters ?? this.filters,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

class SearchController extends StateNotifier<SearchState> {
  final Ref ref;
  Timer? _debounce;

  SearchController(this.ref) : super(const SearchState());

  /// Called on every keystroke. Waits 400ms after the user stops typing
  /// before actually hitting Firestore — this avoids firing a query on
  /// every single character, which would be wasteful and slow.
  void onQueryChanged(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isSearching: false, error: null);
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _runSearch(query),
    );
  }

  Future<void> _runSearch(String query) async {
    state = state.copyWith(isSearching: true, error: null);
    try {
      final results = await ref
          .read(productRepositoryProvider)
          .searchProducts(query);
      state = state.copyWith(results: results, isSearching: false);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  void updateFilters(ProductFilters filters) {
    state = state.copyWith(filters: filters);
  }

  void updateSort(SearchSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  void clear() {
    _debounce?.cancel();
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>(
      (ref) => SearchController(ref),
    );

/// Recent searches — kept in memory for this session only.
/// A later stage can persist these to local storage or Firestore.
final recentSearchesProvider = StateProvider<List<String>>((ref) => []);
