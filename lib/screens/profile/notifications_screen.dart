import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../orders/order_details_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.orderPlaced:
        return Icons.shopping_bag_outlined;
      case NotificationType.orderStatus:
        return Icons.local_shipping_outlined;
      case NotificationType.orderCancelled:
        return Icons.cancel_outlined;
      case NotificationType.general:
        return Icons.notifications_outlined;
    }
  }

  Color _colorFor(NotificationType type) {
    switch (type) {
      case NotificationType.orderPlaced:
        return AppColors.info;
      case NotificationType.orderStatus:
        return AppColors.primary;
      case NotificationType.orderCancelled:
        return AppColors.error;
      case NotificationType.general:
        return AppColors.textSecondary;
    }
  }

  String _timeLabel(DateTime time) {
    final diff = DateTime.now().difference(time);
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final clock = '$hh:$mm';

    if (diff.inMinutes < 1) return 'Just now · $clock';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago · $clock';
    if (diff.inHours < 24) return '${diff.inHours}h ago · $clock';
    if (diff.inDays < 7) return '${diff.inDays}d ago · $clock';
    return '${time.day}/${time.month}/${time.year} · $clock';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final uid = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          notificationsAsync.maybeWhen(
            data: (notifications) => notifications.any((n) => !n.isRead)
                ? TextButton(
                    onPressed: () {
                      if (uid != null) {
                        ref
                            .read(notificationRepositoryProvider)
                            .markAllAsRead(uid);
                      }
                    },
                    child: const Text('Mark all read'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Could not load notifications: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_none_outlined,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No notifications yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Order updates and offers will appear here.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: () {
                  if (!n.isRead) {
                    ref.read(notificationRepositoryProvider).markAsRead(n.id);
                  }
                  if (n.orderId != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailsScreen(orderId: n.orderId!),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: n.isRead
                        ? AppColors.surface
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _colorFor(n.type).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconFor(n.type),
                          color: _colorFor(n.type),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: n.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              n.body,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _timeLabel(n.createdAt),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
