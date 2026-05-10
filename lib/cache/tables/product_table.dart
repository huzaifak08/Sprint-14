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
        currentStock REAL NOT NULL,
        isSynced INTEGER NOT NULL,
        lastSyncAttempt TEXT,
        isDeleted INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> saveAllProducts(List<ProductModel> products) async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return;
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
    if (db == null) return [];
    final maps = await db.query(
      tableName,
      where: 'businessId = ? AND isDeleted = ?',
      whereArgs: [businessId, 0],
    );
    return maps.map(ProductModel.fromJsonDb).toList();
  }

  static Future<List<ProductModel>> getProductsByPlacement(
    String businessId,
    bool isTheya,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return [];
    final maps = await db.query(
      tableName,
      where: 'businessId = ? AND isTheya = ? AND isDeleted = 0',
      whereArgs: [businessId, isTheya ? 1 : 0],
    );
    return maps.map(ProductModel.fromJsonDb).toList();
  }

  static Future<List<ProductModel>> getUnsyncedProductsByBusiness(
    String businessId,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return [];
    final maps = await db.query(
      tableName,
      where: 'businessId = ? AND isSynced = 0',
      whereArgs: [businessId],
    );
    return maps.map(ProductModel.fromJsonDb).toList();
  }

  static Future<void> saveSingleProduct(ProductModel product) async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return;
    await db.insert(
      tableName,
      product.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<int> hardDelete(String productId) async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return 0;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [productId]);
  }

  static Future<void> deleteAllProducts() async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return;
    await db.delete(tableName);
  }
}
