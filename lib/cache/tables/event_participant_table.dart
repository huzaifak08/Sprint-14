import 'package:sqflite/sqflite.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/models/event_participant_model.dart';

class EventParticipantTable {
  static const String tableName = "event_participants";

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        userId TEXT,
        displayName TEXT NOT NULL,
        isActive INTEGER NOT NULL,
        joinedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL,
        lastSyncAttempt TEXT
      )
    ''');
  }

  static Future<void> saveParticipant(EventParticipantModel participant) async {
    final db = await LocalCacheManager.getDatabase();
    await db.insert(
      tableName,
      participant.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> saveAllParticipants(
    List<EventParticipantModel> participants,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    Batch batch = db.batch();
    for (var participant in participants) {
      batch.insert(
        tableName,
        participant.toJsonDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<EventParticipantModel>> getParticipantsByEvent(
    String eventId,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'eventId = ? AND isDeleted = ?',
      whereArgs: [eventId, 0],
    );
    return maps.map(EventParticipantModel.fromJsonDb).toList();
  }

  static Future<List<EventParticipantModel>> getUnsyncedParticipants() async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return maps.map(EventParticipantModel.fromJsonDb).toList();
  }

  static Future<int> hardDelete(String participantId) async {
    final db = await LocalCacheManager.getDatabase();
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [participantId],
    );
  }

  static Future<void> clearTable() async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName);
  }
}
