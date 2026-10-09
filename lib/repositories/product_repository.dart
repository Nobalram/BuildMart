import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import '../models/product.dart';

class ProductRepository {
  final _db = FirebaseFirestore.instance;

  Stream<List<ProductCategory>> watchCategories() {
    return _db
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => ProductCategory.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<Product>> watchProducts({String? categoryName, int limit = 20}) {
    Query<Map<String, dynamic>> query = _db
        .collection('products')
        .where('isActive', isEqualTo: true);

    if (categoryName != null) {
      query = query.where('categoryName', isEqualTo: categoryName);
    }

    return query
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Product.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<({List<Product> products, DocumentSnapshot? lastDoc})>
  fetchProductsPage({
    String? categoryName,
    DocumentSnapshot? startAfter,
    String sortBy = 'createdAt',
    bool descending = true,
    int pageSize = 10,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection('products')
        .where('isActive', isEqualTo: true);

    if (categoryName != null) {
      query = query.where('categoryName', isEqualTo: categoryName);
    }

    query = query.orderBy(sortBy, descending: descending).limit(pageSize);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.get();
    final products = snap.docs
        .map((doc) => Product.fromMap(doc.id, doc.data()))
        .toList();
    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;

    return (products: products, lastDoc: lastDoc);
  }

  /// Fetches multiple products by ID, preserving the order given in
  /// [ids] — used for "Recently Viewed", where insertion order matters
  /// but Firestore's whereIn does not guarantee it.
  Future<List<Product>> fetchProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snap = await _db
        .collection('products')
        .where(FieldPath.documentId, whereIn: ids.take(30).toList())
        .get();
    final byId = {
      for (final doc in snap.docs) doc.id: Product.fromMap(doc.id, doc.data()),
    };
    return ids.map((id) => byId[id]).whereType<Product>().toList();
  }

  Stream<Product?> watchProduct(String productId) {
    return _db.collection('products').doc(productId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Product.fromMap(doc.id, doc.data()!);
    });
  }

  /// Client-side search across name, category, and seller name.
  ///
  /// Firestore doesn't support free-text "contains" search natively, and
  /// a real production app would use a dedicated search service (like
  /// Algolia or Typesense) for this. For our current product count, we
  /// fetch active products once and filter them in Dart — this keeps
  /// the app fully working without adding a paid third-party service.
  /// If your catalog grows into the thousands, swapping this method's
  /// internals for a search-service call is a drop-in replacement —
  /// nothing calling it needs to change.
  Future<List<Product>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];

    final snap = await _db
        .collection('products')
        .where('isActive', isEqualTo: true)
        .limit(200)
        .get();

    final lowerQuery = query.trim().toLowerCase();

    final results = snap.docs
        .map((doc) => Product.fromMap(doc.id, doc.data()))
        .where(
          (product) =>
              product.name.toLowerCase().contains(lowerQuery) ||
              product.categoryName.toLowerCase().contains(lowerQuery) ||
              product.sellerName.toLowerCase().contains(lowerQuery),
        )
        .toList();

    return results;
  }
}
