import 'dart:developer' as dev;
import 'package:sprint_14/clients/notifications/send_notification_service.dart';
import 'package:sprint_14/providers/app_provider_container.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/providers/notification_provider/notification_provider.dart';
import 'package:sprint_14/providers/user_provider/user_provider.dart';

Future<void> saveAndSendNotification({
  required String title,
  required String body,
  required String receiverId,
  String? businessId,
  String? actionType,
  Map<String, dynamic>? payload,
}) async {
  // Callers fire this without awaiting, so never let an error escape.
  try {
    // Send Notification:
    final sender = await AppProviderContainer.instance.read(
      authControllerProvider.future,
    );

    final receiver = await AppProviderContainer.instance.read(
      userProfileProvider(receiverId).future,
    );

    if (receiver != null) {
      for (int index = 0; index < receiver.deviceTokens.length; index++) {
        await SendNotificationService.sendNotification(
          deviceToken: receiver.deviceTokens[index],
          notificationTitle: title,
          notificationBody: body,
        );
      }
    }

    if (businessId != null && sender != null) {
      // Save Notification:
      await AppProviderContainer.instance
          .read(notificationProvider.notifier)
          .sendDynamicNotification(
            targetUserId: receiverId,
            businessId: businessId,
            title: title,
            body: body,
            actionType: actionType ?? "none",
            payload: payload ?? {"senderId": sender.uid},
          );
    }
  } catch (e) {
    dev.log("saveAndSendNotification failed: $e", name: "Notifications");
  }
}
