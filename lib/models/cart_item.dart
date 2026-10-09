import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final String sellerId;
  final String sellerName;
  final double? sellerLat;
  final double? sellerLng;
  final String unit;
  final double unitPrice;
  final double originalPrice;
  final double deliveryCharge;
  final int quantity;
  final int availableStock;
  final DateTime addedAt;

  CartItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    this.sellerLat,
    this.sellerLng,
    required this.unit,
    required this.unitPrice,
    required this.originalPrice,
    this.deliveryCharge = 0,
    required this.quantity,
    required this.availableStock,
    required this.addedAt,
  });

  double get lineTotal => unitPrice * quantity;

  factory CartItem.fromMap(String id, Map<String, dynamic> data) {
    return CartItem(
      productId: id,
      productName: data['productName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      sellerLat: (data['sellerLat'] as num?)?.toDouble(),
      sellerLng: (data['sellerLng'] as num?)?.toDouble(),
      unit: data['unit'] ?? '',
      unitPrice: (data['unitPrice'] ?? 0).toDouble(),
      originalPrice: (data['originalPrice'] ?? 0).toDouble(),
      deliveryCharge: (data['deliveryCharge'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 1) as int,
      availableStock: (data['availableStock'] ?? 0) as int,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerLat': sellerLat,
      'sellerLng': sellerLng,
      'unit': unit,
      'unitPrice': unitPrice,
      'originalPrice': originalPrice,
      'deliveryCharge': deliveryCharge,
      'quantity': quantity,
      'availableStock': availableStock,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}
