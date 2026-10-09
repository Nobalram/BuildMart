import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _cartRef(String uid) =>
      _db.collection('users').doc(uid).collection('cart');

  Stream<List<CartItem>> watchCart(String uid) {
    return _cartRef(uid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CartItem.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Adds [quantity] more of [product] to the cart, or creates the item
  /// if it isn't in the cart yet. Uses a transaction so rapid taps don't
  /// race and drop increments.
  Future<void> addToCart(
    String uid,
    Product product, {
    int quantity = 1,
  }) async {
    final docRef = _cartRef(uid).doc(product.id);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);

      if (snap.exists) {
        final currentQty = (snap.data()?['quantity'] ?? 0) as int;
        final newQty = (currentQty + quantity).clamp(1, product.stock);
        transaction.update(docRef, {
          'quantity': newQty,
          'availableStock': product.stock,
          'unitPrice': product.discountedPrice,
          'originalPrice': product.price,
        });
      } else {
        final item = CartItem(
          productId: product.id,
          productName: product.name,
          imageUrl: product.imageUrl,
          sellerId: product.sellerId,
          sellerName: product.sellerName,
          sellerLat: product.sellerLat,
          sellerLng: product.sellerLng,
          unit: product.unit,
          unitPrice: product.discountedPrice,
          originalPrice: product.price,
          deliveryCharge: product.deliveryCharge,
          quantity: quantity.clamp(1, product.stock),
          availableStock: product.stock,
          addedAt: DateTime.now(),
        );
        transaction.set(docRef, item.toMap());
      }
    });
  }

  Future<void> updateQuantity(
    String uid,
    String productId,
    int quantity,
  ) async {
    if (quantity <= 0) {
      await removeItem(uid, productId);
      return;
    }
    await _cartRef(uid).doc(productId).update({'quantity': quantity});
  }

  Future<void> removeItem(String uid, String productId) async {
    await _cartRef(uid).doc(productId).delete();
  }

  Future<void> clearCart(String uid) async {
    final snap = await _cartRef(uid).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
