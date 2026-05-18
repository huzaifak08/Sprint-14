import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sprint_14/helpers/app_data.dart';
import 'package:sprint_14/helpers/constants.dart'; // Contains centralized firestore / collection tags
import 'package:sprint_14/models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Helper getter to point directly to a user's private notification collection hub
  /// Path Matrix: /users/{userId}/notifications
  CollectionReference<Map<String, dynamic>> _getNotificationRef(String userId) {
    return _firestore
        .collection(usersCollection)
        .doc(userId)
        .collection(notificationsCollection);
  }

  /// --- 1. SYNC / UPSERT NOTIFICATION CHANGELOG ---
  /// Pushes interaction modifications (read states, metadata transitions) up to Firestore
  Future<bool> saveOrUpdateNotification(NotificationModel notification) async {
    try {
      dev.log(
        "Syncing notification state entry up to cloud: ${notification.id}",
        name: "NotificationService",
      );

      await _getNotificationRef(
        notification.userId,
      ).doc(notification.id).set(notification.toMap(), SetOptions(merge: true));

      return true;
    } catch (e) {
      dev.log(
        "Cloud Notification Write Crash: $e",
        name: "NotificationService",
      );
      return false;
    }
  }

  /// --- 2. FETCH ALL HISTORICAL LOGS ---
  /// One-shot fallback download call used to seed empty local SQLite caches
  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    try {
      dev.log(
        "Downloading cloud notification database logs for user: $userId",
        name: "NotificationService",
      );

      final snapshot = await _getNotificationRef(
        userId,
      ).orderBy('createdAt', descending: true).limit(10).get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      dev.log(
        "Failed fetching historical logs out of Firestore cloud: $e",
        name: "NotificationService",
      );
      throw Exception("Cloud communication breakdown: $e");
    }
  }

  /// 🔥 GENERIC DYNAMIC BROADCAST METHOD
  Future<bool> sendDynamicNotification({
    required String targetUserId, // The explicit Receiver's UID
    required String title, // Heading text
    required String body, // Main descriptive text
    String? businessId,
    String actionType =
        'none', // Action type handler string ('navigate', 'url', etc.)
    Map<String, dynamic> payload =
        const {}, // Custom parameters (e.g., {'route': '/orders', 'id': '123'})
  }) async {
    try {
      final genericNotification = NotificationModel(
        id: AppData.shared.uuid.v4(),
        userId: targetUserId,
        businessId: businessId,
        title: title,
        body: body,
        actionType: actionType,
        payload: payload,
        createdAt: DateTime.now(),
        isSynced: true, // Written directly to cloud, so it starts synced
      );

      // Pushes right into the targeted receiver's subcollection tree path
      await _getNotificationRef(
        targetUserId,
      ).doc(genericNotification.id).set(genericNotification.toMap());

      return true;
    } catch (e) {
      dev.log(
        "Failed to dispatch dynamic notification: $e",
        name: "NotificationService",
      );
      return false;
    }
  }

  /// --- 3. PERMANENT REMOVAL (HARD DELETE) ---
  /// Removes document frame completely from server clusters once localized soft flags clear
  Future<bool> deleteNotificationData({
    required String userId,
    required String notificationId,
  }) async {
    try {
      dev.log(
        "Purging cloud notification node: $notificationId",
        name: "NotificationService",
      );

      await _getNotificationRef(userId).doc(notificationId).delete();
      return true;
    } catch (e) {
      dev.log(
        "Failed executing hard delete on target notification index: $e",
        name: "NotificationService",
      );
      return false;
    }
  }

  /// --- 4. REAL-TIME IN-APP LISTENER STREAM ---
  /// Streams live incoming notification documents directly into the app view layers while active
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _getNotificationRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(40)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data()))
              .toList();
        });
  }
}
