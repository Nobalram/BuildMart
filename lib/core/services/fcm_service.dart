import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Requests notification permission and saves this device's FCM token
/// to the user's Firestore document. Saving the token now means that
/// if a Cloud Function is added later (requires Blaze), it can send
/// real push notifications to this exact device immediately — no
/// app update needed.
class FcmService {
  final _messaging = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> initAndSaveToken(String uid) async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await _messaging.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }

      // Keep the stored token fresh if it ever rotates.
      _messaging.onTokenRefresh.listen((newToken) {
        _db.collection('users').doc(uid).set({
          'fcmToken': newToken,
        }, SetOptions(merge: true));
      });
    } catch (_) {
      // Non-fatal — notification history still works without a token;
      // this only affects future real push delivery.
    }
  }
}
