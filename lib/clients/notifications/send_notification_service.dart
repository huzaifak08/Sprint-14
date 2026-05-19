import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:sprint_14/clients/notifications/notification_server_key.dart';

class SendNotificationService {
  static Future<void> sendNotification({
    required String deviceToken,
    required String notificationTitle,
    required String notificationBody,
    Map<String, dynamic>? data,
  }) async {
    try {
      String bearerToken = await NotificationServerKey().getServerKeyToken();

      String url =
          "https://fcm.googleapis.com/v1/projects/sprint14-d3ab2/messages:send";

      var headers = <String, String>{
        "Content-Type": "application/json",
        "Authorization": "Bearer $bearerToken",
      };

      // Ensure data map isn't null so it doesn't crash foreground parsing loops
      final Map<String, String> stringifiedData = {};
      if (data != null) {
        data.forEach((key, value) {
          stringifiedData[key] = value.toString();
        });
      }

      // 🔥 Corrected FCM v1 Payload Structure
      Map<String, dynamic> body = {
        "message": {
          "token": deviceToken,
          "notification": {
            "title": notificationTitle,
            "body": notificationBody,
          },
          "data": stringifiedData,

          // 🤖 Android Specific Targeting Details
          "android": {
            "priority": "high", // ✅ This is correct! Wakes up the device.
            "notification": {
              "channel_id":
                  "sprint14_channel", // ✅ Maps to your Flutter channel
              "sound": "default",
              "default_sound": true,
              // ❌ Removed 'importance' and 'priority' from here since they belong to the device channel setup itself
            },
          },

          // 🍏 iOS/APNS Presentation Targeting Details
          "apns": {
            "headers": {"apns-priority": "10"},
            "payload": {
              "aps": {
                "alert": {"title": notificationTitle, "body": notificationBody},
                "sound": "default",
                "badge": 1,
              },
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      dev.log(
        "FCM Response: ${response.body}",
        name: "SendNotificationService",
      );
    } catch (e) {
      dev.log(
        "Exception caught in SendNotificationService: $e",
        name: "SendNotificationService",
      );
    }
  }
}
