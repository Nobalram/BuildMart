import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at: reviews/{orderId}_{productId}
/// Using a deterministic ID (not auto-generated) is what lets us
/// enforce "one review per order item" purely through the document
/// ID itself — writing to the same ID twice just overwrites the
/// buyer's own prior review (treated as an edit) instead of creating
/// duplicates.
class Review {
  final String id;
  final String productId;
  final String orderId;
  final String buyerId;
  final String buyerName;
  final int rating;
  final String? reviewText;
  final String? photoUrl;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.productId,
    required this.orderId,
    required this.buyerId,
    required this.buyerName,
    required this.rating,
    this.reviewText,
    this.photoUrl,
    required this.createdAt,
  });

  factory Review.fromMap(String id, Map<String, dynamic> data) {
    return Review(
      id: id,
      productId: data['productId'] ?? '',
      orderId: data['orderId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      rating: (data['rating'] ?? 0) as int,
      reviewText: data['reviewText'],
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'orderId': orderId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'rating': rating,
      'reviewText': reviewText,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
