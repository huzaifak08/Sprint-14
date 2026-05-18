import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/tables/notification_table.dart';
import 'package:sprint_14/models/notification_model.dart';
import 'package:sprint_14/services/notification_service.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'dart:developer' as dev;

part 'notification_provider.g.dart';

@Riverpod(keepAlive: true)
class NotificationNotifier extends _$NotificationNotifier {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<List<NotificationModel>>? _streamSubscription;

  @override
  FutureOr<List<NotificationModel>> build() async {
    final authUser = ref.watch(authControllerProvider).value;
    if (authUser == null) return [];

    ref.onDispose(() => _streamSubscription?.cancel());

    return await _initNotifications(authUser.uid);
  }

  Future<List<NotificationModel>> _initNotifications(String uid) async {
    final localLogs = await NotificationTable.getUserNotifications(userId: uid);

    if (localLogs.isNotEmpty) {
      dev.log(
        "Notification Cache Hit. Spawning background cloud sync stream.",
        name: "NotificationProvider",
      );
      _startCloudStreaming(uid);
      return localLogs;
    }

    dev.log(
      "Notification Cache Empty. Bootstrapping data directly from Cloud.",
      name: "NotificationProvider",
    );
    _startCloudStreaming(uid);

    return [];
  }

  void _startCloudStreaming(String uid) {
    _streamSubscription?.cancel();

    _streamSubscription = _notificationService
        .streamUserNotifications(uid)
        .listen(
          (cloudPayload) async {
            await NotificationTable.saveAllFetchedNotifications(cloudPayload);

            state = AsyncData(cloudPayload);
          },
          onError: (error) {
            dev.log(
              "Cloud Notification pipeline connection failure: $error",
              name: "NotificationProvider",
            );
          },
        );
  }

  Future<void> markAsRead(String notificationId) async {
    final currentNotifications = state.value ?? [];
    final index = currentNotifications.indexWhere(
      (n) => n.id == notificationId,
    );
    if (index == -1) return;

    final original = currentNotifications[index];
    if (original.isRead) return;

    final updatedNotification = original.copyWith(
      isRead: true,
      readAt: DateTime.now(),
      isSynced: false,
      lastSyncAttempt: DateTime.now(),
    );

    final updatedList = [...currentNotifications];
    updatedList[index] = updatedNotification;
    state = AsyncData(updatedList);
    await NotificationTable.saveNotification(updatedNotification);

    try {
      await _notificationService.saveOrUpdateNotification(updatedNotification);

      await NotificationTable.saveNotification(
        updatedNotification.copyWith(isSynced: true),
      );
    } catch (e) {
      dev.log("Failed updating unread metrics online, cached offline: $e");
    }
  }

  Future<bool> sendDynamicNotification({
    required String targetUserId,
    required String title,
    required String body,
    String? businessId,
    String actionType = 'none',
    Map<String, dynamic> payload = const {},
  }) async {
    return await _notificationService.sendDynamicNotification(
      targetUserId: targetUserId,
      title: title,
      body: body,
      businessId: businessId,
      actionType: actionType,
      payload: payload,
    );
  }

  Future<void> deleteNotification(String notificationId) async {
    final currentNotifications = state.value ?? [];
    final index = currentNotifications.indexWhere(
      (n) => n.id == notificationId,
    );
    if (index == -1) return;

    final target = currentNotifications[index];

    final updatedList = [...currentNotifications]..removeAt(index);
    state = AsyncData(updatedList);

    final deletedMarker = target.copyWith(isDeleted: true, isSynced: false);
    await NotificationTable.saveNotification(deletedMarker);

    try {
      final success = await _notificationService.deleteNotificationData(
        userId: target.userId,
        notificationId: notificationId,
      );

      if (success) {
        await NotificationTable.hardDeleteNotification(notificationId);
      }
    } catch (e) {
      dev.log(
        "Upstream alert node deletion deferred to next connectivity window: $e",
      );
    }
  }

  void handleNotificationClick(
    BuildContext context,
    NotificationModel notification,
  ) {
    markAsRead(notification.id);

    final String action = notification.actionType.trim().toLowerCase();

    if (action == 'navigate') {
      final targetRoute = notification.payload['route'];
      final associatedId = notification.payload['id'];

      if (targetRoute != null) {
        dev.log(
          "Routing Navigation Executed to: $targetRoute with Param ID: $associatedId",
          name: "NotificationProvider",
        );
      }
    } else if (action == 'url') {
      final urlTarget = notification.payload['url'];
      if (urlTarget != null) {
        dev.log(
          "Launching outbound resource reference link: $urlTarget",
          name: "NotificationProvider",
        );
      }
    }
  }

  Future<void> syncPendingNotifications() async {
    dev.log(
      "Processing offline queued notification mutations...",
      name: "NotificationProvider",
    );

    final unsyncedLogs = await NotificationTable.getUnsyncedNotifications();
    if (unsyncedLogs.isEmpty) return;

    for (var notification in unsyncedLogs) {
      try {
        if (notification.isDeleted) {
          final success = await _notificationService.deleteNotificationData(
            userId: notification.userId,
            notificationId: notification.id,
          );
          if (success) {
            await NotificationTable.hardDeleteNotification(notification.id);
          }
        } else {
          final success = await _notificationService.saveOrUpdateNotification(
            notification,
          );
          if (success) {
            await NotificationTable.saveNotification(
              notification.copyWith(isSynced: true),
            );
          }
        }
      } catch (e) {
        dev.log(
          "Synchronization sequence failed for notification node [${notification.id}]: $e",
        );
        await NotificationTable.saveNotification(
          notification.copyWith(lastSyncAttempt: DateTime.now()),
        );
      }
    }
  }
}

@riverpod
int notificationUnreadCount(Ref ref) {
  final currentNotifications = ref.watch(notificationProvider).value ?? [];
  return currentNotifications.where((n) => !n.isRead).length;
}
