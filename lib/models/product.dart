import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String sellerId;
  final String sellerName;
  final double? sellerLat;
  final double? sellerLng;
  final String categoryName;
  final double price;
  final int discountPercent;
  final String unit;
  final int stock;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final List<String> images;
  final String? description;
  final Map<String, String> specifications;
  final int minimumOrder;
  final double deliveryCharge;
  final bool isActive;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.sellerId,
    required this.sellerName,
    this.sellerLat,
    this.sellerLng,
    required this.categoryName,
    required this.price,
    required this.discountPercent,
    required this.unit,
    required this.stock,
    required this.rating,
    this.reviewCount = 0,
    required this.imageUrl,
    this.images = const [],
    this.description,
    this.specifications = const {},
    this.minimumOrder = 1,
    this.deliveryCharge = 0,
    required this.isActive,
    required this.createdAt,
  });

  double get discountedPrice =>
      discountPercent > 0 ? price - (price * discountPercent / 100) : price;

  bool get inStock => stock > 0;

  /// Falls back to [imageUrl] if the seller hasn't added a gallery yet —
  /// this keeps the carousel working for seed data with just one image.
  List<String> get galleryImages => images.isNotEmpty ? images : [imageUrl];

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      sellerLat: (data['sellerLat'] as num?)?.toDouble(),
      sellerLng: (data['sellerLng'] as num?)?.toDouble(),
      categoryName: data['categoryName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      discountPercent: (data['discountPercent'] ?? 0) as int,
      unit: data['unit'] ?? '',
      stock: (data['stock'] ?? 0) as int,
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: (data['reviewCount'] ?? 0) as int,
      imageUrl: data['imageUrl'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      description: data['description'],
      specifications: Map<String, String>.from(data['specifications'] ?? {}),
      minimumOrder: (data['minimumOrder'] ?? 1) as int,
      deliveryCharge: (data['deliveryCharge'] ?? 0).toDouble(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
