import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Pops a real system-tray notification on this device when a new
/// Firestore notification document is detected, as long as the app
/// process is alive (foreground or minimized). This does NOT work
/// if the app has been fully closed/swiped away or the phone
/// restarted — that would require a Cloud Function + Blaze plan.
class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);

    // Android 13+ requires runtime notification permission.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> show({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'buildmart_orders',
      'Order Updates',
      channelDescription: 'Notifications about your orders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
