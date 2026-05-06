import 'package:sqflite/sqflite.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/models/product_model.dart';

class ProductTable {
  static const String tableName = "products";

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        businessId TEXT NOT NULL,
        title TEXT NOT NULL,
        isTheya INTEGER NOT NULL,
        classification TEXT NOT NULL,
        retailPrice REAL NOT NULL,
        msrpPrice REAL NOT NULL,
        unitType TEXT NOT NULL,
        isSynced INTEGER NOT NULL,
        lastSyncAttempt TEXT,
        isDeleted INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> saveAllProducts(List<ProductModel> products) async {
    final db = await LocalCacheManager.getDatabase();
    Batch batch = db.batch();
    for (var product in products) {
      batch.insert(
        tableName,
        product.toJsonDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<ProductModel>> getAllProducts(String businessId) async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'businessId = ? AND isDeleted = ?',
      whereArgs: [businessId],
    );
    return maps.map(ProductModel.fromJsonDb).toList();
  }

  static Future<List<ProductModel>> getProductsByBusiness(
    String businessId,
    bool isTheya,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'businessId = ? AND isTheya = ? AND isDeleted = ?',
      whereArgs: [businessId, isTheya ? 1 : 0, 0],
    );
    return maps.map(ProductModel.fromJsonDb).toList();
  }

  /// Gets all products for a specific business waiting for cloud sync
  static Future<List<ProductModel>> getUnsyncedProductsByBusiness(
    String businessId,
  ) async {
    final db = await LocalCacheManager.getDatabase();

    final maps = await db.query(
      tableName,
      where: 'businessId = ? AND isSynced = ?',
      whereArgs: [businessId, 0],
    );

    return maps.map(ProductModel.fromJsonDb).toList();
  }

  static Future<void> saveSingleProduct(ProductModel product) async {
    final db = await LocalCacheManager.getDatabase();
    await db.insert(
      tableName,
      product.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteAllProducts() async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName);
  }
}
