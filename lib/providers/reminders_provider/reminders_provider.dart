import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/clients/notifications/notification_cloud_service.dart';
part 'reminders_provider.g.dart';

@Riverpod(keepAlive: true)
class RemindersNotifier extends _$RemindersNotifier {
  @override
  List<PendingNotificationRequest> build() {
    // Initial load
    _loadReminders();
    return [];
  }

  // Refreshes the state with the actual pending notifications from the OS
  Future<void> _loadReminders() async {
    final reminders = await NotificationCloudService()
        .checkPendingNotifications();
    state = reminders;
  }

  // Pass the ID explicitly to match your Project + Day logic
  Future<void> setReminder({
    required int id, // Use project.id.hashCode + dayOffset
    required String title,
    required String body,
    required DateTime dateTime,
    String? payload,
  }) async {
    await NotificationCloudService().scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDateTime: dateTime,
      payload: payload,
    );

    // Refresh the list so the UI updates immediately
    await _loadReminders();
  }

  Future<void> cancelReminder({required int reminderId}) async {
    await NotificationCloudService().cancelProjectNotifications(id: reminderId);
    _loadReminders();
  }
}
