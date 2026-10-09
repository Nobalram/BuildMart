import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import 'product_provider.dart';

const _prefsKey = 'recently_viewed_product_ids';
const _maxItems = 10;

class RecentlyViewedController extends StateNotifier<List<String>> {
  RecentlyViewedController() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      state = List<String>.from(jsonDecode(raw));
    }
  }

  Future<void> recordView(String productId) async {
    final updated = [
      productId,
      ...state.where((id) => id != productId),
    ].take(_maxItems).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(updated));
  }
}

final recentlyViewedIdsProvider =
    StateNotifierProvider<RecentlyViewedController, List<String>>(
      (ref) => RecentlyViewedController(),
    );

/// Re-fetches whenever the viewed-ids list changes.
final recentlyViewedProductsProvider = FutureProvider<List<Product>>((
  ref,
) async {
  final ids = ref.watch(recentlyViewedIdsProvider);
  if (ids.isEmpty) return [];
  return ref.read(productRepositoryProvider).fetchProductsByIds(ids);
});
