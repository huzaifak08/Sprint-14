import 'package:sqflite/sqflite.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/models/event_ledger_model.dart';

class EventLedgerTable {
  static const String tableName = "event_ledgers";

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        creatorId TEXT NOT NULL,
        type TEXT NOT NULL,
        isSettled INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        metadata TEXT NOT NULL,
        isSynced INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL,
        lastSyncAttempt TEXT
      )
    ''');
  }

  static Future<void> saveSingleLedger(EventLedgerModel ledger) async {
    final db = await LocalCacheManager.getDatabase();
    await db.insert(
      tableName,
      ledger.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> saveAllLedgers(List<EventLedgerModel> ledgers) async {
    final db = await LocalCacheManager.getDatabase();
    Batch batch = db.batch();
    for (var ledger in ledgers) {
      batch.insert(
        tableName,
        ledger.toJsonDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<EventLedgerModel>> getActiveLedgers() async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'isDeleted = ?',
      whereArgs: [0],
      orderBy: 'createdAt DESC',
    );
    return maps.map(EventLedgerModel.fromJsonDb).toList();
  }

  static Future<List<EventLedgerModel>> getUnsyncedLedgers() async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return maps.map(EventLedgerModel.fromJsonDb).toList();
  }

  static Future<int> hardDelete(String ledgerId) async {
    final db = await LocalCacheManager.getDatabase();
    return await db.delete(tableName, where: 'id = ?', whereArgs: [ledgerId]);
  }

  static Future<void> deleteAllLedgers() async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName);
  }
}
