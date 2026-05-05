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
    String bearerToken = await NotificationServerKey().getServerKeyToken();

    String url =
        "https://fcm.googleapis.com/v1/projects/sprint14-d3ab2/messages:send";

    var headers = <String, String>{
      "Content-Type": "application/json",
      "Authorization": "Bearer $bearerToken",
    };

    Map<String, dynamic> body = {
      "message": {
        "token": deviceToken,
        "notification": {"body": notificationBody, "title": notificationTitle},
        "data": data,
      },
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    dev.log(response.body);
  }
}
