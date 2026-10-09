import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

OrderStatus orderStatusFromString(String value) {
  return OrderStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => OrderStatus.pending,
  );
}

String orderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'Pending';
    case OrderStatus.confirmed:
      return 'Confirmed';
    case OrderStatus.preparing:
      return 'Preparing';
    case OrderStatus.outForDelivery:
      return 'Out for Delivery';
    case OrderStatus.delivered:
      return 'Delivered';
    case OrderStatus.cancelled:
      return 'Cancelled';
  }
}

enum PaymentMethod { cod, online }

class OrderLineItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final String unit;
  final double unitPrice;
  final int quantity;

  OrderLineItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.unit,
    required this.unitPrice,
    required this.quantity,
  });

  double get lineTotal => unitPrice * quantity;

  factory OrderLineItem.fromMap(Map<String, dynamic> data) {
    return OrderLineItem(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      unit: data['unit'] ?? '',
      unitPrice: (data['unitPrice'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'unit': unit,
      'unitPrice': unitPrice,
      'quantity': quantity,
    };
  }
}

class AppOrder {
  final String id;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String sellerId;
  final String sellerName;
  final List<OrderLineItem> items;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final double subtotal;
  final double transportFee;
  final double platformFee;
  final double tax;
  final double total;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final bool selfArrangedTransport;
  final DateTime createdAt;

  AppOrder({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.sellerId,
    required this.sellerName,
    required this.items,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    required this.subtotal,
    required this.transportFee,
    required this.platformFee,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    this.status = OrderStatus.pending,
    this.selfArrangedTransport = false,
    required this.createdAt,
  });

  factory AppOrder.fromMap(String id, Map<String, dynamic> data) {
    return AppOrder(
      id: id,
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      buyerPhone: data['buyerPhone'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => OrderLineItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      addressLine: data['addressLine'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      pincode: data['pincode'] ?? '',
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      transportFee: (data['transportFee'] ?? 0).toDouble(),
      platformFee: (data['platformFee'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      paymentMethod: (data['paymentMethod'] == 'online')
          ? PaymentMethod.online
          : PaymentMethod.cod,
      status: orderStatusFromString(data['status'] ?? 'pending'),
      selfArrangedTransport: data['selfArrangedTransport'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'items': items.map((e) => e.toMap()).toList(),
      'addressLine': addressLine,
      'city': city,
      'state': state,
      'pincode': pincode,
      'subtotal': subtotal,
      'transportFee': transportFee,
      'platformFee': platformFee,
      'tax': tax,
      'total': total,
      'paymentMethod': paymentMethod == PaymentMethod.online ? 'online' : 'cod',
      'status': status.name,
      'selfArrangedTransport': selfArrangedTransport,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
