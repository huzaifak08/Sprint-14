import 'package:sqflite/sqflite.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/models/sale_model.dart';
import 'dart:developer' as dev;

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
    if (db == null) return;
    await db.insert(
      tableName,
      sale.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> saveAllSales(List<SaleModel> sales) async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return;
    final batch = db.batch();
    for (final sale in sales) {
      batch.insert(
        tableName,
        sale.toJsonDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    dev.log("Batch saved ${sales.length} sales to cache.", name: "SaleTable");
  }

  static Future<List<SaleModel>> getBusinessSalesFromCache(
    String businessId,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return [];
    final maps = await db.query(
      tableName,
      where: 'businessId = ? AND isDeleted = ?',
      whereArgs: [businessId, 0],
      orderBy: 'dateTime DESC',
    );
    return maps.map(SaleModel.fromJsonDb).toList();
  }

  static Future<List<SaleModel>> getUnsyncedSalesByBusiness(
    String businessId,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return [];
    final maps = await db.query(
      tableName,
      where: 'businessId = ? AND isSynced = ?',
      whereArgs: [businessId, 0],
    );
    return maps.map(SaleModel.fromJsonDb).toList();
  }

  static Future<void> hardDelete(String saleId) async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return;
    await db.delete(tableName, where: 'id = ?', whereArgs: [saleId]);
  }

  static Future<void> clearAllSales() async {
    try {
      final db = await LocalCacheManager.getDatabase();
      if (db == null) return;
      await db.delete(tableName);
      dev.log("Sales table cleared successfully.", name: "SaleTable");
    } catch (e) {
      dev.log("Error clearing Sales table: $e", name: "SaleTable");
    }
  }
}
