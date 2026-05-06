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

  /// 1. Save Single Sale
  static Future<void> saveSingleSale(SaleModel sale) async {
    final db = await LocalCacheManager.getDatabase();
    await db.insert(
      tableName,
      sale.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 2. Bulk Save (New): Used during loadSales to persist cloud data
  static Future<void> saveAllSales(List<SaleModel> sales) async {
    final db = await LocalCacheManager.getDatabase();
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

  /// 3. Load Sales: Filters out soft-deleted items
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

  /// 4. Get Unsynced Sales (Filtered): Critical for background sync logic
  static Future<List<SaleModel>> getUnsyncedSalesByBusiness(
    String businessId,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'businessId = ? AND isSynced = ?',
      whereArgs: [businessId, 0],
    );
    return maps.map(SaleModel.fromJsonDb).toList();
  }

  /// 5. Hard Delete: Removes record from device after cloud sync confirm
  static Future<void> hardDelete(String saleId) async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName, where: 'id = ?', whereArgs: [saleId]);
  }

  /// 6. Clear Table (New): Security protocol for logout
  static Future<void> clearAllSales() async {
    try {
      final db = await LocalCacheManager.getDatabase();
      await db.delete(tableName);
      dev.log("Sales table cleared successfully.", name: "SaleTable");
    } catch (e) {
      dev.log("Error clearing Sales table: $e", name: "SaleTable");
    }
  }
}
