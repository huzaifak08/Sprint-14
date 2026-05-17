import 'package:sqflite/sqflite.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/models/participant_model.dart';
import 'dart:developer' as dev;

class ParticipantTable {
  static const String tableName = "participants";

  /// --- CREATE TABLE ---
  /// Executed via LocalCacheManager during onCreate or onUpgrade resets
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        businessId TEXT NOT NULL,
        userId TEXT NOT NULL,
        role TEXT NOT NULL,
        isActive INTEGER NOT NULL,
        assignedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL,
        lastSyncAttempt TEXT
      )
    ''');
    dev.log("Participant Table Created", name: "ParticipantTable");
  }

  /// --- SAVE / UPDATE SINGLE PARTICIPANT ---
  /// Handles local optimistic additions or state updates (e.g., toggling isActive)
  static Future<void> saveParticipant(ParticipantModel participant) async {
    final db = await LocalCacheManager.getDatabase();
    await db.insert(
      tableName,
      participant.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// --- SAVE ALL (BULK FETCH SYNC) ---
  /// Locks down database batching when downloading all shop staff from Firestore
  static Future<void> saveAllFetchedParticipants(
    List<ParticipantModel> participants,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    final batch = db.batch();
    for (var p in participants) {
      batch.insert(
        tableName,
        p.toJsonDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// --- GET ALL ACTIVE PARTICIPANTS FOR A BUSINESS ---
  /// Excludes soft-deleted elements and can optionally filter for active staff only
  static Future<List<ParticipantModel>> getBusinessParticipants({
    required String businessId,
    bool onlyActive = false,
  }) async {
    final db = await LocalCacheManager.getDatabase();

    String whereClause = 'businessId = ? AND isDeleted = 0';
    List<dynamic> whereArgs = [businessId];

    if (onlyActive) {
      whereClause += ' AND isActive = 1';
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'assignedAt DESC',
    );

    return List.generate(
      maps.length,
      (i) => ParticipantModel.fromJsonDb(maps[i]),
    );
  }

  /// --- GET SPECIFIC USER COMPOSITE ASSIGNMENT ---
  /// Instantly verifies what role a logged-in user holds inside a specific business workspace
  static Future<ParticipantModel?> getSpecificParticipant({
    required String businessId,
    required String userId,
  }) async {
    final db = await LocalCacheManager.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'businessId = ? AND userId = ? AND isDeleted = 0',
      whereArgs: [businessId, userId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ParticipantModel.fromJsonDb(maps.first);
  }

  /// --- GET ALL UNSYNCED STAFF MODIFICATIONS ---
  /// Essential engine query for background sync tracking workers
  static Future<List<ParticipantModel>> getUnsyncedParticipants() async {
    final db = await LocalCacheManager.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'isSynced = 0',
    );

    return List.generate(
      maps.length,
      (i) => ParticipantModel.fromJsonDb(maps[i]),
    );
  }

  /// --- HARD DELETE ---
  /// Clears record permanently out of local device only after confirmed cloud sync deletion
  static Future<void> hardDeleteParticipant(String id) async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// --- CLEAR TABLE ---
  /// Total wipe invoked when executing deep-clean logouts
  static Future<void> deleteAllParticipants() async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName);
  }
}
