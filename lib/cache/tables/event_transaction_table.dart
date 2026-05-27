import 'package:sqflite/sqflite.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/models/event_transaction_model.dart';

class EventTransactionTable {
  static const String tableName = "event_transactions";

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        paidById TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        transactionDate TEXT NOT NULL,
        milestoneId TEXT,
        splitDetails TEXT NOT NULL,
        isSynced INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL,
        lastSyncAttempt TEXT
      )
    ''');
  }

  static Future<void> saveSingleTransaction(
    EventTransactionModel transaction,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    await db.insert(
      tableName,
      transaction.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> saveAllTransactions(
    List<EventTransactionModel> transactions,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    Batch batch = db.batch();
    for (var transaction in transactions) {
      batch.insert(
        tableName,
        transaction.toJsonDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Fetches ONLY the active transactions for an event that haven't been bundled into a settlement milestone yet
  static Future<List<EventTransactionModel>> getActiveEventTransactions(
    String eventId,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'eventId = ? AND milestoneId IS NULL AND isDeleted = ?',
      whereArgs: [eventId, 0],
      orderBy: 'transactionDate DESC',
    );
    return maps.map(EventTransactionModel.fromJsonDb).toList();
  }

  /// Fetches historically settled transactions linked to a specific checkpoint milestone
  static Future<List<EventTransactionModel>> getTransactionsByMilestone(
    String milestoneId,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'milestoneId = ? AND isDeleted = ?',
      whereArgs: [milestoneId, 0],
    );
    return maps.map(EventTransactionModel.fromJsonDb).toList();
  }

  /// High-efficiency lookups for dynamically loading existing categories used inside this ledger
  static Future<List<String>> getDistinctCategoriesInLedger(
    String eventId,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT category FROM $tableName WHERE eventId = ? AND isDeleted = ?',
      [eventId, 0],
    );
    return maps.map((row) => row['category'] as String).toList();
  }

  static Future<List<EventTransactionModel>> getUnsyncedTransactions() async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return maps.map(EventTransactionModel.fromJsonDb).toList();
  }

  static Future<int> hardDelete(String transactionId) async {
    final db = await LocalCacheManager.getDatabase();
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  static Future<void> clearTable() async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName);
  }
}
