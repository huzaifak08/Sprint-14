import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/models/notification_model.dart';
import 'package:sprint_14/providers/notification_provider/notification_provider.dart';

class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 🧹 Mark All As Read Shortcut Option
          notificationsAsync.when(
            data: (list) {
              final unreadExists = list.any((n) => !n.isRead);
              if (!unreadExists) return const SizedBox.shrink();

              return TextButton.icon(
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text(
                  "Mark all read",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _markAllAsRead(ref, list),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState(theme);
          }

          return RefreshIndicator(
            onRefresh: () => ref
                .read(notificationProvider.notifier)
                .syncPendingNotifications(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notification = notifications[index];

                // 🔥 Slide-To-Delete Gestures Wrapped on Each Card Row Frame
                return Dismissible(
                  key: Key("notif_${notification.id}"),
                  direction: DismissDirection.endToStart,
                  background: _buildDismissibleBackground(theme),
                  onDismissed: (_) {
                    ref
                        .read(notificationProvider.notifier)
                        .deleteNotification(notification.id);
                    _showSnackBar(context, "Notification removed.");
                  },
                  child: _NotificationCardItem(notification: notification),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text("Failed to render notification files: $err")),
      ),
    );
  }

  /// --- MARK ALL AS READ BATCH RUNNER ---
  void _markAllAsRead(WidgetRef ref, List<NotificationModel> list) {
    final unreadItems = list.where((n) => !n.isRead);
    for (var item in unreadItems) {
      ref.read(notificationProvider.notifier).markAsRead(item.id);
    }
  }

  /// --- SLIDE TO REMOVE DECORATION LAYOUT ---
  Widget _buildDismissibleBackground(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerRight,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Delete",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Icon(Icons.delete_outline_rounded, color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 74,
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          const Text(
            "All Caught Up!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            "When alerts or updates arrive, they will log right here.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

/// --- 🔥 SUB-WIDGET: SINGLE ALERTS ROW CARD ITEM ---
class _NotificationCardItem extends ConsumerWidget {
  final NotificationModel notification;
  const _NotificationCardItem({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Context Icon selection driven by string keywords parsed inside incoming payloads
    IconData leadingIcon;
    Color iconColor;

    switch (notification.actionType.trim().toLowerCase()) {
      case 'navigate':
        leadingIcon = Icons.directions_rounded;
        iconColor = theme.colorScheme.primary;
        break;
      case 'url':
        leadingIcon = Icons.open_in_new_rounded;
        iconColor = theme.colorScheme.tertiary;
        break;
      case 'refresh':
        leadingIcon = Icons.cached_rounded;
        iconColor = Colors.teal;
        break;
      default:
        leadingIcon = Icons.notification_important_outlined;
        iconColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: !notification.isRead
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.primary.withValues(alpha: 0.04),
          width: !notification.isRead ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => ref
              .read(notificationProvider.notifier)
              .handleNotificationClick(context, notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔔 Dynamic Context Lead Status Sphere Circle
                CircleAvatar(
                  radius: 22,
                  backgroundColor: iconColor.withValues(alpha: 0.08),
                  child: Icon(leadingIcon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: !notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 14.5,
                                color: !notification.isRead
                                    ? theme.colorScheme.onSecondary
                                    : theme.colorScheme.onSecondary.withValues(
                                        alpha: 0.7,
                                      ),
                              ),
                            ),
                          ),
                          // 🔵 Unread Visual Indicator Pip Dot
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8, top: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSecondary.withValues(
                            alpha: 0.6,
                          ),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatRelativeTime(notification.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!notification.isSynced)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud_off_rounded,
                                  size: 12,
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Offline Saved",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// --- LIGHTWEIGHT RELATIVE TIMESTAMP PARSER ---
  String _formatRelativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return "Just now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    if (difference.inDays < 7) return "${difference.inDays}d ago";
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }
}
