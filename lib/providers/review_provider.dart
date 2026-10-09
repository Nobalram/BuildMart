import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review.dart';
import '../repositories/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepository(),
);

final productReviewsProvider = StreamProvider.family<List<Review>, String>((
  ref,
  productId,
) {
  return ref.watch(reviewRepositoryProvider).watchProductReviews(productId);
});

/// Keyed by "orderId|productId" — lets the Order Details screen check,
/// per line item, whether this buyer has already reviewed it.
final existingReviewProvider =
    FutureProvider.family<Review?, ({String orderId, String productId})>((
      ref,
      key,
    ) {
      return ref
          .read(reviewRepositoryProvider)
          .getReview(key.orderId, key.productId);
    });
