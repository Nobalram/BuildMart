import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/local_notification_service.dart';
import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';
import 'auth_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(),
);

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(<AppNotification>[]);
  return ref.watch(notificationRepositoryProvider).watchNotifications(uid);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

/// Watches the notification stream and fires a local system-tray
/// notification the moment a genuinely NEW document appears — not
/// on first load (which would re-notify for the entire history every
/// time the app starts), only for arrivals after that initial load.
final notificationWatcherProvider = Provider<void>((ref) {
  final Set<String> seenIds = {};
  bool firstEmission = true;

  ref.listen<AsyncValue<List<AppNotification>>>(notificationsProvider, (
    previous,
    next,
  ) {
    next.whenData((notifications) {
      if (firstEmission) {
        // Seed with whatever already exists so we don't re-alert
        // for old notifications on every app start.
        seenIds.addAll(notifications.map((n) => n.id));
        firstEmission = false;
        return;
      }

      for (final n in notifications) {
        if (!seenIds.contains(n.id)) {
          seenIds.add(n.id);
          LocalNotificationService.show(title: n.title, body: n.body);
        }
      }
    });
  }, fireImmediately: true);
});
