import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:digital_munshi/cache/init_cache.dart';
import 'package:digital_munshi/models/sale_model.dart';
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
        measurement REAL NOT NULL,
        dateTime TEXT NOT NULL,
        items TEXT,
        recordedById TEXT,
        stockTracked INTEGER NOT NULL DEFAULT 0,
        updatedAt TEXT,
        syncedStock TEXT,
        isSynced INTEGER NOT NULL,
        lastSyncAttempt TEXT,
        isDeleted INTEGER NOT NULL
      )
    ''');
    await createIndexes(db);
  }

  static Future<void> createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_business_date '
      'ON $tableName (businessId, dateTime)',
    );
  }

  /// v19: per-item lines, stock tracking and audit fields.
  static Future<void> migrateV19(Database db) async {
    await LocalCacheManager.addColumnIfMissing(
      db,
      tableName,
      'items',
      'TEXT',
    );
    await LocalCacheManager.addColumnIfMissing(
      db,
      tableName,
      'recordedById',
      'TEXT',
    );
    await LocalCacheManager.addColumnIfMissing(
      db,
      tableName,
      'stockTracked',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await LocalCacheManager.addColumnIfMissing(
      db,
      tableName,
      'updatedAt',
      'TEXT',
    );
    await LocalCacheManager.addColumnIfMissing(
      db,
      tableName,
      'syncedStock',
      'TEXT',
    );
    await createIndexes(db);
  }

  /// Records the stock use the cloud now reflects for [saleId].
  static Future<void> setSyncedStock(
    String saleId,
    Map<String, double> stock,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    await db.update(
      tableName,
      {'syncedStock': jsonEncode(stock)},
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  /// Every unsynced row for [businessId], including soft-deleted ones.
  /// Used to work out stock changes that haven't reached the cloud.
  static Future<List<SaleModel>> getPendingRows(String businessId) async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'businessId = ? AND isSynced = 0',
      whereArgs: [businessId],
    );
    return maps.map(SaleModel.fromJsonDb).toList();
  }

  static Future<void> deleteByBusiness(String businessId) async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName, where: 'businessId = ?', whereArgs: [businessId]);
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

  /// Saves a local edit without touching `syncedStock`, which only the
  /// sync writes (a single UPDATE, so it can't race with the sync).
  static Future<void> saveSaleKeepingSyncedStock(SaleModel sale) async {
    final db = await LocalCacheManager.getDatabase();
    final values = sale.toJsonDb()..remove('syncedStock');
    final updated = await db.update(
      tableName,
      values,
      where: 'id = ?',
      whereArgs: [sale.id],
    );
    if (updated == 0) await saveSingleSale(sale);
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
