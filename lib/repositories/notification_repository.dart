import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';

class NotificationRepository {
  final _db = FirebaseFirestore.instance;

  Stream<List<AppNotification>> watchNotifications(String recipientId) {
    return _db
        .collection('notifications')
        .where('recipientId', isEqualTo: recipientId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> send({
    required String recipientId,
    required String title,
    required String body,
    required NotificationType type,
    String? orderId,
  }) async {
    await _db
        .collection('notifications')
        .add(
          AppNotification(
            id: '',
            recipientId: recipientId,
            title: title,
            body: body,
            type: type,
            orderId: orderId,
            createdAt: DateTime.now(),
          ).toMap(),
        );
  }

  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  Future<void> markAllAsRead(String recipientId) async {
    final snap = await _db
        .collection('notifications')
        .where('recipientId', isEqualTo: recipientId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
