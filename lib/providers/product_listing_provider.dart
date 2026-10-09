import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import 'product_provider.dart';

enum SortOption { newest, priceLowHigh, priceHighLow, rating }

class ProductListingState {
  final List<Product> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final String? error;
  final SortOption sortOption;

  const ProductListingState({
    this.products = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastDoc,
    this.error,
    this.sortOption = SortOption.newest,
  });

  ProductListingState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    String? error,
    SortOption? sortOption,
  }) {
    return ProductListingState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
      error: error,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

class ProductListingController extends StateNotifier<ProductListingState> {
  final Ref ref;
  final String? categoryName;

  ProductListingController(this.ref, this.categoryName)
    : super(const ProductListingState()) {
    loadFirstPage();
  }

  ({String sortBy, bool descending}) _sortParams(SortOption option) {
    switch (option) {
      case SortOption.newest:
        return (sortBy: 'createdAt', descending: true);
      case SortOption.priceLowHigh:
        return (sortBy: 'price', descending: false);
      case SortOption.priceHighLow:
        return (sortBy: 'price', descending: true);
      case SortOption.rating:
        return (sortBy: 'rating', descending: true);
    }
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = _sortParams(state.sortOption);
      final result = await ref
          .read(productRepositoryProvider)
          .fetchProductsPage(
            categoryName: categoryName,
            sortBy: params.sortBy,
            descending: params.descending,
          );
      state = state.copyWith(
        products: result.products,
        lastDoc: result.lastDoc,
        hasMore: result.products.length == 10,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.lastDoc == null) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final params = _sortParams(state.sortOption);
      final result = await ref
          .read(productRepositoryProvider)
          .fetchProductsPage(
            categoryName: categoryName,
            startAfter: state.lastDoc,
            sortBy: params.sortBy,
            descending: params.descending,
          );
      state = state.copyWith(
        products: [...state.products, ...result.products],
        lastDoc: result.lastDoc,
        hasMore: result.products.length == 10,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void changeSort(SortOption option) {
    state = state.copyWith(
      sortOption: option,
      products: [],
      lastDoc: null,
      hasMore: true,
    );
    loadFirstPage();
  }
}

/// One controller instance per category — .family lets each Listing
/// screen (Bricks, Cement, etc.) keep its own independent page state.
final productListingProvider =
    StateNotifierProvider.family<
      ProductListingController,
      ProductListingState,
      String?
    >((ref, categoryName) => ProductListingController(ref, categoryName));
