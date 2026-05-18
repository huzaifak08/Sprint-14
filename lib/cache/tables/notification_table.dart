import 'package:sqflite/sqflite.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/models/notification_model.dart';
import 'dart:developer' as dev;

class NotificationTable {
  static const String tableName = "notifications";

  /// --- CREATE TABLE ---
  /// Register this method inside your LocalCacheManager onCreate/onUpgrade blocker arrays
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        businessId TEXT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        actionType TEXT NOT NULL,
        payload TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        readAt TEXT,
        isRead INTEGER NOT NULL,
        isSynced INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL,
        lastSyncAttempt TEXT
      )
    ''');
    dev.log(
      "Notification Table Structural Init Completed",
      name: "NotificationTable",
    );
  }

  /// --- SAVE / INSERT SINGLE NOTIFICATION ---
  /// Safely logs incoming push alerts directly into cache even while the app is in the background
  static Future<void> saveNotification(NotificationModel notification) async {
    final db = await LocalCacheManager.getDatabase();
    await db.insert(
      tableName,
      notification.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// --- SAVE ALL (BULK CLOUD FETCH) ---
  /// Batches network incoming feeds cleanly down into SQLite frames
  static Future<void> saveAllFetchedNotifications(
    List<NotificationModel> notifications,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    final batch = db.batch();
    for (var n in notifications) {
      batch.insert(
        tableName,
        n.toJsonDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// --- GET ALL NOTIFICATIONS FOR USER ---
  /// Excludes soft-deleted elements and returns chronologically ordered lists
  static Future<List<NotificationModel>> getUserNotifications({
    required String userId,
    String? businessId,
  }) async {
    final db = await LocalCacheManager.getDatabase();

    String whereClause = 'userId = ? AND isDeleted = 0';
    List<dynamic> whereArgs = [userId];

    // Optional: Filter notifications tied to the active business context
    if (businessId != null) {
      whereClause += ' AND (businessId = ? OR businessId IS NULL)';
      whereArgs.add(businessId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
    );

    return List.generate(
      maps.length,
      (i) => NotificationModel.fromJsonDb(maps[i]),
    );
  }

  /// --- GET UNREAD COUNT ---
  /// Returns a lightweight reactive counter for notification bell badges
  static Future<int> getUnreadCount(String userId, {String? businessId}) async {
    final db = await LocalCacheManager.getDatabase();

    String query =
        'SELECT COUNT(*) FROM $tableName WHERE userId = ? AND isRead = 0 AND isDeleted = 0';
    List<dynamic> args = [userId];

    if (businessId != null) {
      query += ' AND (businessId = ? OR businessId IS NULL)';
      args.add(businessId);
    }

    final List<Map<String, dynamic>> result = await db.rawQuery(query, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// --- GET ALL UNSYNCED NOTIFICATIONS ---
  /// Crucial selector for your background synchronization workers (read updates & deletions)
  static Future<List<NotificationModel>> getUnsyncedNotifications() async {
    final db = await LocalCacheManager.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'isSynced = 0',
    );

    return List.generate(
      maps.length,
      (i) => NotificationModel.fromJsonDb(maps[i]),
    );
  }

  /// --- HARD PURGE RECORD ---
  /// Drops reference permanently out of the hardware cache frame once cloud tracking responds clean
  static Future<void> hardDeleteNotification(String id) async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// --- COMPLETE TABLE CLEAR ---
  /// Triggered during central profile logout routines
  static Future<void> deleteAllNotifications() async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName);
  }
}
