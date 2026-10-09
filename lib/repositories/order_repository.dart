import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/address.dart';
import '../models/app_notification.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class InsufficientStockException implements Exception {
  final String productName;
  final int available;
  InsufficientStockException(this.productName, this.available);

  @override
  String toString() =>
      'Only $available ${available == 1 ? "unit" : "units"} of "$productName" left in stock.';
}

class OrderRepository {
  final _db = FirebaseFirestore.instance;

  Future<List<String>> placeOrder({
    required String buyerId,
    required String buyerName,
    required String buyerPhone,
    required List<CartItem> cartItems,
    required Address address,
    required PaymentMethod paymentMethod,
    required double taxPercent,
    required double platformFee,
    required double mileageKmPerLiter,
    required double fuelCostPerLiter,
    required double freeDeliveryThreshold,
    required bool selfArrangedTransport,
  }) async {
    final Map<String, List<CartItem>> bySeller = {};
    for (final item in cartItems) {
      bySeller.putIfAbsent(item.sellerId, () => []).add(item);
    }

    final orderIds = <String>[];
    final notificationWrites = <Map<String, dynamic>>[];
    final subtotalAll = cartItems.fold(
      0.0,
      (sum, item) => sum + item.lineTotal,
    );
    final waiveTransport =
        selfArrangedTransport || subtotalAll >= freeDeliveryThreshold;

    await _db.runTransaction((transaction) async {
      final productRefs = cartItems
          .map((item) => _db.collection('products').doc(item.productId))
          .toList();
      final productSnaps = await Future.wait(
        productRefs.map((ref) => transaction.get(ref)),
      );

      final liveStock = <String, int>{};
      for (var i = 0; i < cartItems.length; i++) {
        final snap = productSnaps[i];
        final stock = (snap.data()?['stock'] ?? 0) as int;
        liveStock[cartItems[i].productId] = stock;

        if (stock < cartItems[i].quantity) {
          throw InsufficientStockException(cartItems[i].productName, stock);
        }
      }

      for (final entry in bySeller.entries) {
        final sellerId = entry.key;
        final items = entry.value;
        final sellerName = items.first.sellerName;

        final subtotal = items.fold(0.0, (sum, item) => sum + item.lineTotal);

        double transportFee = 0;
        if (!waiveTransport &&
            address.latitude != null &&
            address.longitude != null &&
            items.first.sellerLat != null &&
            items.first.sellerLng != null) {
          final distanceMeters = Geolocator.distanceBetween(
            address.latitude!,
            address.longitude!,
            items.first.sellerLat!,
            items.first.sellerLng!,
          );
          final liters = (distanceMeters / 1000) / mileageKmPerLiter;
          transportFee = liters * fuelCostPerLiter;
        }

        final sellerPlatformShare = platformFee / bySeller.length;
        final tax = subtotal * (taxPercent / 100);
        final total = subtotal + transportFee + sellerPlatformShare + tax;

        final orderRef = _db.collection('orders').doc();
        orderIds.add(orderRef.id);

        final order = AppOrder(
          id: orderRef.id,
          buyerId: buyerId,
          buyerName: buyerName,
          buyerPhone: buyerPhone,
          sellerId: sellerId,
          sellerName: sellerName,
          items: items
              .map(
                (item) => OrderLineItem(
                  productId: item.productId,
                  productName: item.productName,
                  imageUrl: item.imageUrl,
                  unit: item.unit,
                  unitPrice: item.unitPrice,
                  quantity: item.quantity,
                ),
              )
              .toList(),
          addressLine: address.addressLine,
          city: address.city,
          state: address.state,
          pincode: address.pincode,
          subtotal: subtotal,
          transportFee: transportFee,
          platformFee: sellerPlatformShare,
          tax: tax,
          total: total,
          paymentMethod: paymentMethod,
          status: OrderStatus.pending,
          selfArrangedTransport: selfArrangedTransport,
          createdAt: DateTime.now(),
        );

        transaction.set(orderRef, order.toMap());

        notificationWrites.add(
          AppNotification(
            id: '',
            recipientId: sellerId,
            title: 'New Order Received',
            body:
                '$buyerName placed an order worth ₹${total.toStringAsFixed(0)}',
            type: NotificationType.orderPlaced,
            orderId: orderRef.id,
            createdAt: DateTime.now(),
          ).toMap(),
        );
      }

      for (var i = 0; i < cartItems.length; i++) {
        final newStock =
            liveStock[cartItems[i].productId]! - cartItems[i].quantity;
        transaction.update(productRefs[i], {'stock': newStock});
      }

      final cartRef = _db.collection('users').doc(buyerId).collection('cart');
      for (final item in cartItems) {
        transaction.delete(cartRef.doc(item.productId));
      }
    });

    // Notifications go to a different top-level collection with
    // different ownership than the transaction's writes, so they're
    // sent right after the transaction commits successfully.
    for (final notificationData in notificationWrites) {
      await _db.collection('notifications').add(notificationData);
    }

    return orderIds;
  }

  Stream<List<AppOrder>> watchBuyerOrders(String buyerId) {
    return _db
        .collection('orders')
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AppOrder.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<AppOrder?> watchOrder(String orderId) {
    return _db.collection('orders').doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppOrder.fromMap(doc.id, doc.data()!);
    });
  }

  Future<void> cancelOrder(String orderId) async {
    final orderRef = _db.collection('orders').doc(orderId);
    String? sellerIdToNotify;
    double? totalForNotif;

    await _db.runTransaction((transaction) async {
      final orderSnap = await transaction.get(orderRef);
      if (!orderSnap.exists) return;

      final order = AppOrder.fromMap(orderSnap.id, orderSnap.data()!);

      if (order.status == OrderStatus.delivered ||
          order.status == OrderStatus.cancelled) {
        throw Exception('This order can no longer be cancelled.');
      }

      final productRefs = order.items
          .map((item) => _db.collection('products').doc(item.productId))
          .toList();
      final productSnaps = await Future.wait(
        productRefs.map((ref) => transaction.get(ref)),
      );

      for (var i = 0; i < order.items.length; i++) {
        final currentStock = (productSnaps[i].data()?['stock'] ?? 0) as int;
        transaction.update(productRefs[i], {
          'stock': currentStock + order.items[i].quantity,
        });
      }

      transaction.update(orderRef, {'status': OrderStatus.cancelled.name});

      sellerIdToNotify = order.sellerId;
      totalForNotif = order.total;
    });

    if (sellerIdToNotify != null) {
      await _db
          .collection('notifications')
          .add(
            AppNotification(
              id: '',
              recipientId: sellerIdToNotify!,
              title: 'Order Cancelled',
              body:
                  'An order worth ₹${totalForNotif!.toStringAsFixed(0)} was cancelled by the buyer.',
              type: NotificationType.orderCancelled,
              orderId: orderId,
              createdAt: DateTime.now(),
            ).toMap(),
          );
    }
  }
}
