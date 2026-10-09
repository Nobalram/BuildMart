import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review.dart';

class ReviewRepository {
  final _db = FirebaseFirestore.instance;

  String _reviewId(String orderId, String productId) => '${orderId}_$productId';

  Stream<List<Review>> watchProductReviews(String productId) {
    return _db
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Review.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<Review?> getReview(String orderId, String productId) async {
    final doc = await _db
        .collection('reviews')
        .doc(_reviewId(orderId, productId))
        .get();
    if (!doc.exists) return null;
    return Review.fromMap(doc.id, doc.data()!);
  }

  /// Writes the review AND updates the product's aggregate rating in
  /// one transaction. If this is an edit of an existing review (same
  /// order+product), the old rating is first removed from the running
  /// average before the new one is applied, so editing never skews
  /// the product's score.
  Future<void> submitReview({
    required String productId,
    required String orderId,
    required String buyerId,
    required String buyerName,
    required int rating,
    String? reviewText,
    String? photoUrl,
  }) async {
    final reviewRef = _db
        .collection('reviews')
        .doc(_reviewId(orderId, productId));
    final productRef = _db.collection('products').doc(productId);

    await _db.runTransaction((transaction) async {
      final existingReviewSnap = await transaction.get(reviewRef);
      final productSnap = await transaction.get(productRef);

      final currentRating = (productSnap.data()?['rating'] ?? 0).toDouble();
      final currentCount = (productSnap.data()?['reviewCount'] ?? 0) as int;

      double newRating;
      int newCount;

      if (existingReviewSnap.exists) {
        // Editing a previous review — remove its old contribution first.
        final oldRating = (existingReviewSnap.data()?['rating'] ?? 0) as int;
        final totalPoints = (currentRating * currentCount) - oldRating + rating;
        newCount = currentCount;
        newRating = newCount > 0 ? totalPoints / newCount : 0;
      } else {
        final totalPoints = (currentRating * currentCount) + rating;
        newCount = currentCount + 1;
        newRating = totalPoints / newCount;
      }

      transaction.set(
        reviewRef,
        Review(
          id: reviewRef.id,
          productId: productId,
          orderId: orderId,
          buyerId: buyerId,
          buyerName: buyerName,
          rating: rating,
          reviewText: reviewText,
          photoUrl: photoUrl,
          createdAt: DateTime.now(),
        ).toMap(),
      );

      transaction.update(productRef, {
        'rating': double.parse(newRating.toStringAsFixed(2)),
        'reviewCount': newCount,
      });
    });
  }
}
