import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { orderPlaced, orderStatus, orderCancelled, general }

NotificationType _typeFromString(String value) {
  return NotificationType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => NotificationType.general,
  );
}

/// Stored at: notifications/{notificationId}
/// Top-level (not nested under users/{uid}) because the WRITER and the
/// RECIPIENT are different accounts — a seller writes a notification
/// for a buyer, and vice versa, which a nested subcollection's
/// same-uid-only rules wouldn't allow.
class AppNotification {
  final String id;
  final String recipientId;
  final String title;
  final String body;
  final NotificationType type;
  final String? orderId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    required this.type,
    this.orderId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      recipientId: data['recipientId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: _typeFromString(data['type'] ?? 'general'),
      orderId: data['orderId'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'type': type.name,
      'orderId': orderId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
