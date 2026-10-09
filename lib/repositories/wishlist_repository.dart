import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _wishlistRef(String uid) =>
      _db.collection('users').doc(uid).collection('wishlist');

  Stream<Set<String>> watchWishlistIds(String uid) {
    return _wishlistRef(uid)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toSet());
  }

  Future<void> toggle(
    String uid,
    String productId,
    bool isCurrentlyWishlisted,
  ) async {
    final docRef = _wishlistRef(uid).doc(productId);
    if (isCurrentlyWishlisted) {
      await docRef.delete();
    } else {
      await docRef.set({'addedAt': Timestamp.now()});
    }
  }
}
