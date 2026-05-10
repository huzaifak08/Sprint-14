import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/models/ledger_model.dart';
import 'package:sqflite/sqflite.dart';

class LedgerTable {
  static const String tableName = "ledgers";

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        isIncome INTEGER NOT NULL,
        note TEXT,
        paymentMethod TEXT NOT NULL,
        isSynced INTEGER NOT NULL,
        lastSyncAttempt TEXT,
        isDeleted INTEGER NOT NULL,
        dateTime TEXT NOT NULL
      )
    ''');
  }

  static Future<void> saveAllFetchedLedgers(List<LedgerModel> ledgers) async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return;
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

  static Future<void> saveSingleLedger(LedgerModel ledger) async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return;
    await db.insert(
      tableName,
      ledger.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<LedgerModel>> getUnsyncedLedgers() async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return [];
    final maps = await db.query(
      tableName,
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return maps.map(LedgerModel.fromJsonDb).toList();
  }

  static Future<List<LedgerModel>> getAllLedgersFromCache() async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return [];
    final maps = await db.query(tableName, orderBy: 'dateTime DESC');
    return maps.map(LedgerModel.fromJsonDb).toList();
  }

  static Future<LedgerModel?> getSingleLedgerById(String ledgerId) async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return null;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [ledgerId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return LedgerModel.fromJsonDb(maps.first);
  }

  static Future<void> hardDelete(String ledgerId) async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return;
    await db.delete(tableName, where: 'id = ?', whereArgs: [ledgerId]);
  }

  static Future<void> deleteAllLedgers() async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return;
    await db.delete(tableName);
  }
}
