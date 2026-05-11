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
        productIds TEXT NOT NULL,
        productTitles TEXT NOT NULL,
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
    dev.log('Saving single sale to cache', name: 'Sale Table');
    try {
      final db = await LocalCacheManager.getDatabase();
      await db.insert(
        tableName,
        sale.toJsonDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      dev.log('Saved single sale to cache', name: 'Sale Table');
    } catch (e, st) {
      dev.log(
        'Failed to save single sale: $e',
        name: 'Sale Table',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static Future<void> saveAllSales(List<SaleModel> sales) async {
    dev.log('Saving ${sales.length} sales to cache', name: 'Sale Table');
    try {
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
      dev.log('Saved all sales to cache', name: 'Sale Table');
    } catch (e, st) {
      dev.log(
        'Failed to save all sales: $e',
        name: 'Sale Table',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static Future<List<SaleModel>> getBusinessSalesFromCache(
    String businessId,
  ) async {
    dev.log(
      'Querying cached sales for businessId: $businessId',
      name: 'Sale Table',
    );
    try {
      final db = await LocalCacheManager.getDatabase();
      final maps = await db.query(
        tableName,
        where: 'businessId = ? AND isDeleted = ?',
        whereArgs: [businessId, 0],
        orderBy: 'dateTime DESC',
      );
      final sales = maps.map(SaleModel.fromJsonDb).toList();
      dev.log(
        'Retrieved ${sales.length} cached sales for businessId: $businessId',
        name: 'Sale Table',
      );
      return sales;
    } catch (e, st) {
      dev.log(
        'Failed to query business sales from cache: $e',
        name: 'Sale Table',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static Future<List<SaleModel>> getUnsyncedSalesByBusiness(
    String businessId,
  ) async {
    dev.log(
      'Querying unsynced cached sales for businessId: $businessId',
      name: 'Sale Table',
    );
    try {
      final db = await LocalCacheManager.getDatabase();
      final maps = await db.query(
        tableName,
        where: 'businessId = ? AND isSynced = ?',
        whereArgs: [businessId, 0],
      );
      final sales = maps.map(SaleModel.fromJsonDb).toList();
      dev.log(
        'Retrieved ${sales.length} unsynced sales for businessId: $businessId',
        name: 'Sale Table',
      );
      return sales;
    } catch (e, st) {
      dev.log(
        'Failed to query unsynced sales by business: $e',
        name: 'Sale Table',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static Future<void> hardDelete(String saleId) async {
    dev.log('Hard deleting sale with id: $saleId', name: 'Sale Table');
    try {
      final db = await LocalCacheManager.getDatabase();
      await db.delete(tableName, where: 'id = ?', whereArgs: [saleId]);
      dev.log('Hard deleted sale with id: $saleId', name: 'Sale Table');
    } catch (e, st) {
      dev.log(
        'Failed to hard delete sale: $e',
        name: 'Sale Table',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static Future<void> clearAllSales() async {
    dev.log('Clearing all sales from cache', name: 'Sale Table');
    try {
      final db = await LocalCacheManager.getDatabase();
      await db.delete(tableName);
      dev.log('Cleared all sales from cache', name: 'Sale Table');
    } catch (e, st) {
      dev.log(
        'Failed to clear all sales: $e',
        name: 'Sale Table',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
