import 'package:sqflite/sqflite.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/models/settlement_milestone_model.dart';

class SettlementMilestoneTable {
  static const String tableName = "settlement_milestones";

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        settledByUserId TEXT NOT NULL,
        settledAt TEXT NOT NULL,
        totalPoolSpent REAL NOT NULL,
        settlementSummary TEXT NOT NULL,
        isSynced INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL,
        lastSyncAttempt TEXT
      )
    ''');
  }

  static Future<void> saveSingleMilestone(
    SettlementMilestoneModel milestone,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    await db.insert(
      tableName,
      milestone.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> saveAllMilestones(
    List<SettlementMilestoneModel> milestones,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    Batch batch = db.batch();
    for (var milestone in milestones) {
      batch.insert(
        tableName,
        milestone.toJsonDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<SettlementMilestoneModel>> getMilestonesByEvent(
    String eventId,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'eventId = ? AND isDeleted = ?',
      whereArgs: [eventId, 0],
      orderBy: 'settledAt DESC',
    );
    return maps.map(SettlementMilestoneModel.fromJsonDb).toList();
  }

  static Future<List<SettlementMilestoneModel>> getUnsyncedMilestones() async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return maps.map(SettlementMilestoneModel.fromJsonDb).toList();
  }

  static Future<int> hardDelete(String milestoneId) async {
    final db = await LocalCacheManager.getDatabase();
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [milestoneId],
    );
  }

  static Future<void> clearTable() async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName);
  }
}
