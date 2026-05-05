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

  /// Bulk save for syncing from cloud
  static Future<void> saveAllFetchedLedgers(List<LedgerModel> ledgers) async {
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

  /// Saves or updates a single transaction
  static Future<void> saveSingleLedger(LedgerModel ledger) async {
    final db = await LocalCacheManager.getDatabase();
    await db.insert(
      tableName,
      ledger.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Gets all transactions waiting for cloud sync
  static Future<List<LedgerModel>> getUnsyncedLedgers() async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'isSynced = ?',
      whereArgs: [0],
    );

    return maps.map(LedgerModel.fromJsonDb).toList();
  }

  /// Loads the entire ledger for the UI
  static Future<List<LedgerModel>> getAllLedgersFromCache() async {
    final db = await LocalCacheManager.getDatabase();
    // We order by dateTime descending so newest expenses show first
    final maps = await db.query(tableName, orderBy: 'dateTime DESC');
    return List.generate(maps.length, (i) => LedgerModel.fromJsonDb(maps[i]));
  }

  static Future<LedgerModel?> getSingleLedgerById(String ledgerId) async {
    final db = await LocalCacheManager.getDatabase();

    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [ledgerId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return LedgerModel.fromJsonDb(maps.first);
  }

  /// Hard delete from local DB (used after Cloud deletion confirmation)
  static Future<void> hardDelete(String ledgerId) async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName, where: 'id = ?', whereArgs: [ledgerId]);
  }

  static Future<void> deleteAllLedgers() async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName);
  }
}
