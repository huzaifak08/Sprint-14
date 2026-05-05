import 'package:sqflite/sqflite.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/models/sale_model.dart';

class SaleTable {
  static const String tableName = "sales";

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        businessId TEXT NOT NULL,
        productId TEXT NOT NULL,
        productTitle TEXT NOT NULL,
        soldAtPrice REAL NOT NULL,
        profit REAL NOT NULL,
        quantity REAL NOT NULL,
        dateTime TEXT NOT NULL,
        isSynced INTEGER NOT NULL,
        lastSyncAttempt TEXT,
        isDeleted INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> saveSingleSale(SaleModel sale) async {
    final db = await LocalCacheManager.getDatabase();
    await db.insert(
      tableName,
      sale.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Loads sales for a specific business, newest first
  static Future<List<SaleModel>> getBusinessSalesFromCache(
    String businessId,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'businessId = ? AND isDeleted = ?',
      whereArgs: [businessId, 0],
      orderBy: 'dateTime DESC',
    );
    return maps.map(SaleModel.fromJsonDb).toList();
  }

  static Future<List<SaleModel>> getUnsyncedSales() async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return maps.map(SaleModel.fromJsonDb).toList();
  }

  static Future<void> hardDelete(String saleId) async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName, where: 'id = ?', whereArgs: [saleId]);
  }
}
