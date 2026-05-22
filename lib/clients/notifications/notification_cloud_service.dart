import 'dart:io';
import 'dart:developer' as dev;
import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:sprint_14/helpers/app_data.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as ts;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationCloudService {
  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin get _flutterLocalNotiPlugin =>
      FlutterLocalNotificationsPlugin();

  // For schedule:
  static bool _timezoneInitialized = false;

  //* Notification Permission:
  void requestNotificationPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      dev.log("NOTIFICATIONS PERMISSIONS GRANTED");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      dev.log("NOTIFICATIONS PERMISSIONS PROVISIONAL");
    } else {
      dev.log("NOTIFICATIONS PERMISSIONS DENIED (ELSE)");

      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    }
  }

  //* Get Device Token:
  Future<String?> getDeviceToken() async {
    String? token = await _firebaseMessaging.getToken();
    dev.log("DEVICE TOKEN => $token");
    return token;
  }

  //* Notifications Listener:
  void firebaseNotificationsInit(
    BuildContext context,
    RemoteMessage message,
  ) async {
    var androidInitSetting = const AndroidInitializationSettings(
      "@mipmap/ic_launcher",
    );
    var iosInitSetting = const DarwinInitializationSettings();

    var initSetting = InitializationSettings(
      android: androidInitSetting,
      iOS: iosInitSetting,
    );

    // For Schedule Notifications only:
    await initializeTimeZone();

    await _flutterLocalNotiPlugin.initialize(
      settings: initSetting,
      onDidReceiveNotificationResponse: (payload) {
        handleMessage(context, message);
        _handleActionMessage(payload); // After enabling actions
      },
    );

    FirebaseMessaging.onMessage.listen((message) {
      dev.log(message.notification?.title ?? "NO NOTIFICATION TITLE");
      dev.log(message.notification?.body ?? "NO NOTIFICATION BODY");
    });
  }

  // For Schedule notifications only:
  Future<void> initializeTimeZone() async {
    if (_timezoneInitialized) return;

    ts.initializeTimeZones();
    final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));

    _timezoneInitialized = true;
  }

  //* Foreground Notifications:
  void handleForegroundNotifications(BuildContext context) async {
    FirebaseMessaging.onMessage.listen((message) {
      RemoteNotification? notification = message.notification;
      // AndroidNotification? androidNoti = message.notification?.android;

      if (kDebugMode) {
        dev.log("NOTIFICATION TITLE: ${notification?.title}");
        dev.log("NOTIFICATION BODY: ${notification?.body}");
      }

      // ios:
      if (Platform.isIOS) {
        iosForegroundMessage();
      }

      // android:
      if (Platform.isAndroid) {
        firebaseNotificationsInit(
          AppData.shared.navigatorKey.currentContext ?? context,
          message,
        );
        showNotification(message);
      }
    });
  }

  //* Render Notification:
  Future<void> showNotification(RemoteMessage message) async {
    if (message.notification != null) {
      // Channel Setting:
      AndroidNotificationChannel channel = AndroidNotificationChannel(
        message.notification!.android!.channelId.toString(),
        message.notification!.android!.channelId.toString(),
        importance: Importance.high,
        showBadge: true,
        playSound: true,
      );

      // Android Setting:
      AndroidNotificationDetails
      androidNotificationDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: "channelDescription",
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: channel.sound,
        // actions: [
        //   AndroidNotificationAction(
        //     "reply_id",
        //     "Reply",
        //     showsUserInterface: true,
        //     inputs: [
        //       AndroidNotificationActionInput(label: "Type your message..."),
        //     ],
        //   ),

        //   AndroidNotificationAction(
        //     "mark_as_done_id",
        //     "Mark as done",
        //     showsUserInterface: true,
        //   ),
        // ],
      );

      // IOS Setting:
      DarwinNotificationDetails darwinNotificationDetails =
          const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      // Merge Settings:
      NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
      );

      final int safeUniqueNotificationId = DateTime.now().millisecondsSinceEpoch
          .remainder(100000);

      // Show Notifications:
      Future.delayed(Duration.zero, () {
        // Todo: Use UUID instead of 0:
        _flutterLocalNotiPlugin.show(
          id: safeUniqueNotificationId,
          title: message.notification?.title,
          body: message.notification?.body,
          notificationDetails: notificationDetails,
          payload: "Send anything as payload as per need",
        );
      });
    }
  }

  void iosForegroundMessage() async {
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  //* Background and Terminated Notifications:
  Future<void> setUpInteractMessage(BuildContext context) async {
    // Background State:
    // onMessageOpenedApp --> Tappable notification to navigate
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleMessage(
        AppData.shared.navigatorKey.currentContext ?? context,
        message,
      );
    });

    // Terminated State:
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null && message.data.isNotEmpty) {
        handleMessage(
          AppData.shared.navigatorKey.currentContext ?? context,
          message,
        );
      }
    });
  }

  Future<void> handleMessage(
    BuildContext? context, // Optional - we won't use it for navigation
    RemoteMessage message,
  ) async {
    // if (message.data['view'] == "chat") {
    // Extract data with null checks
    //   final userDataString = message.data['user'] as String?;
    //   final roomId = message.data['roomId'];

    //   if (userDataString == null || roomId == null) {
    //     debugPrint('Missing user or roomId in FCM payload');
    //     return;
    //   }

    //   try {
    //     UserModel user = UserModel.fromJson(userDataString);

    //     // Safe navigation using GLOBAL key (no local context needed)
    //     final navigator = AppData.shared.navigatorKey.currentState;
    //     if (navigator == null || !navigator.mounted) {
    //       debugPrint(
    //         'Navigator not available or unmounted - skipping navigation',
    //       );
    //       return;
    //     }

    //     // Push the route
    //     navigator.push(
    //       MaterialPageRoute(
    //         builder: (context) => ChatMessagesView(roomId: roomId, user: user),
    //       ),
    //     );

    //     debugPrint('Navigation pushed successfully');
    //   } catch (e, stackTrace) {
    //     debugPrint('Error in handleMessage: $e');
    //     debugPrint('Stack trace: $stackTrace');
    //     if (context != null && context.mounted) {
    //       ScaffoldMessenger.of(
    //         context,
    //       ).showSnackBar(SnackBar(content: Text('Navigation error: $e')));
    //     }
    //   }
    // } else if (message.data['view'] == "product") {
    //   try {
    //     // Safe navigation using GLOBAL key (no local context needed)
    //     final navigator = AppData.shared.navigatorKey.currentState;
    //     if (navigator == null || !navigator.mounted) {
    //       debugPrint(
    //         'Navigator not available or unmounted - skipping navigation',
    //       );
    //       return;
    //     }

    //     AppProviderContainer.instance.invalidate(commentsNotifierProvider);

    //     // Push the route
    //     navigator.push(
    //       MaterialPageRoute(
    //         builder: (context) =>
    //             ProductDetailView(productId: message.data['productId']),
    //       ),
    //     );

    //     debugPrint('Navigation pushed successfully');
    //   } catch (e, stackTrace) {
    //     debugPrint('Error in handleMessage: $e');
    //     debugPrint('Stack trace: $stackTrace');
    //     if (context != null && context.mounted) {
    //       ScaffoldMessenger.of(
    //         context,
    //       ).showSnackBar(SnackBar(content: Text('Navigation error: $e')));
    //     }
    //   }
    // }
  }

  //* Handle Notifications Actions:
  void _handleActionMessage(NotificationResponse notificationResponse) async {
    debugPrint("Notification Action: ${notificationResponse.actionId}");

    if (notificationResponse.actionId == "reply_id") {
      // String? input = notificationResponse.input;
    } else if (notificationResponse.actionId == "mark_as_done_id") {}
  }

  //* Schedule a notification: hours(0-23) mins(0-59):
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    String formattedPayload = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(scheduledDateTime);

    if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotiPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      bool? canSchedule = await androidImplementation
          ?.canScheduleExactNotifications();

      if (canSchedule == false) {
        dev.log("Permission denied for exact alarms.");
        await androidImplementation?.requestExactAlarmsPermission();
        return;
      }
    }

    await initializeTimeZone();
    final location = tz.local;

    // Convert DateTime to TZDateTime
    var scheduledDate = tz.TZDateTime.from(scheduledDateTime, location);

    // Safety Check: If the time is in the past, don't schedule (or schedule 10s from now for testing)
    if (scheduledDate.isBefore(tz.TZDateTime.now(location))) {
      dev.log("Scheduled date $scheduledDate is in the past. Skipping.");
      return;
    }

    dev.log("Notification ID: $id | Date: $scheduledDate | Title: $title");

    await _flutterLocalNotiPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: formattedPayload,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'sprint14_channel',
          'Project Reminders',
          channelDescription: 'Notifications for app testing milestones',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    dev.log("Notification $id scheduled successfully.");
  }

  Future<List<PendingNotificationRequest>> checkPendingNotifications() async {
    final List<PendingNotificationRequest> pendingRequests =
        await _flutterLocalNotiPlugin.pendingNotificationRequests();

    dev.log("PENDING NOTIFICATIONS COUNT: ${pendingRequests.length}");
    // for (var request in pendingRequests) {
    //   dev.log("Pending ID: ${request.id} - ${request.title}");
    // }

    return pendingRequests;
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotiPlugin.cancelAll();
  }

  Future<void> cancelProjectNotifications({required int id}) async {
    await _flutterLocalNotiPlugin.cancel(id: id);
  }

  Future<void> subscribeToAll() async {
    await _firebaseMessaging.subscribeToTopic("all");
    dev.log("Subscribed to ALL", name: "Notifications Cloud Service");
  }
}
