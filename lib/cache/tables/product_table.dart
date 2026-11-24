import 'package:sqflite/sqflite.dart';
import 'package:digital_munshi/cache/init_cache.dart';
import 'package:digital_munshi/models/product_model.dart';

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
        pendingStockDelta REAL NOT NULL DEFAULT 0,
        stockAdjustmentId TEXT,
        updatedAt TEXT,
        isSynced INTEGER NOT NULL,
        lastSyncAttempt TEXT,
        isDeleted INTEGER NOT NULL
      )
    ''');
    await createIndexes(db);
  }

  static Future<void> createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_business '
      'ON $tableName (businessId)',
    );
  }

  /// v19: pending stock adjustments and edit time.
  static Future<void> migrateV19(Database db) async {
    await LocalCacheManager.addColumnIfMissing(
      db,
      tableName,
      'pendingStockDelta',
      'REAL NOT NULL DEFAULT 0',
    );
    await LocalCacheManager.addColumnIfMissing(
      db,
      tableName,
      'stockAdjustmentId',
      'TEXT',
    );
    await LocalCacheManager.addColumnIfMissing(
      db,
      tableName,
      'updatedAt',
      'TEXT',
    );
    await createIndexes(db);
  }

  /// Stores the cloud stock figures (productId -> stock) returned by a
  /// transaction. Only touches the stock mirror, never pending edits.
  static Future<void> setCloudStock(Map<String, double> stock) async {
    if (stock.isEmpty) return;
    final db = await LocalCacheManager.getDatabase();
    final batch = db.batch();
    stock.forEach((id, value) {
      batch.update(
        tableName,
        {'currentStock': value},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    await batch.commit(noResult: true);
  }

  /// Marks [uploadedDelta] of a pending stock adjustment as applied in the
  /// cloud. Any further change the user made meanwhile stays pending.
  static Future<void> settleStockAdjustment({
    required String productId,
    required String adjustmentId,
    required double uploadedDelta,
  }) async {
    final db = await LocalCacheManager.getDatabase();
    await db.rawUpdate(
      'UPDATE $tableName SET pendingStockDelta = pendingStockDelta - ?, '
      'stockAdjustmentId = CASE WHEN stockAdjustmentId = ? THEN NULL '
      'ELSE stockAdjustmentId END WHERE id = ?',
      [uploadedDelta, adjustmentId, productId],
    );
  }

  static Future<void> deleteByBusiness(String businessId) async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName, where: 'businessId = ?', whereArgs: [businessId]);
  }

  /// Saves a list of products using a batch for high performance
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

  /// Fetches all non-deleted products for a business
  static Future<List<ProductModel>> getAllProducts(String businessId) async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'businessId = ? AND isDeleted = ?',
      whereArgs: [businessId, 0],
    );
    return maps.map(ProductModel.fromJsonDb).toList();
  }

  /// Fetches products filtered by placement (Theya vs Inside)
  static Future<List<ProductModel>> getProductsByPlacement(
    String businessId,
    bool isTheya,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'businessId = ? AND isTheya = ? AND isDeleted = 0',
      whereArgs: [businessId, isTheya ? 1 : 0],
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
      where: 'businessId = ? AND isSynced = 0',
      whereArgs: [businessId],
    );

    return maps.map(ProductModel.fromJsonDb).toList();
  }

  /// The local row for [productId], including unsynced / soft-deleted rows.
  static Future<ProductModel?> getById(String productId) async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    return maps.isEmpty ? null : ProductModel.fromJsonDb(maps.first);
  }

  /// Saves a product's details without touching its stock columns
  /// (`currentStock`, `pendingStockDelta`, `stockAdjustmentId`), which only
  /// [addStockAdjustment] and the sync change. Inserts the row if missing.
  ///
  /// Marking a product synced only succeeds while no stock adjustment is
  /// pending, so an adjustment made during an upload is never dropped.
  static Future<void> saveProductKeepingStock(ProductModel product) async {
    final db = await LocalCacheManager.getDatabase();
    final values = product.toJsonDb()
      ..remove('currentStock')
      ..remove('pendingStockDelta')
      ..remove('stockAdjustmentId');
    final updated = await db.update(
      tableName,
      values,
      where: product.isSynced
          ? 'id = ? AND ABS(pendingStockDelta) < 0.000000001'
          : 'id = ?',
      whereArgs: [product.id],
    );
    if (updated == 0 && await getById(product.id) == null) {
      await saveSingleProduct(product);
    }
  }

  /// Queues a manual stock change of [delta] units for upload (one SQL
  /// statement, so concurrent changes add up instead of overwriting).
  static Future<void> addStockAdjustment({
    required String productId,
    required double delta,
    required String adjustmentId,
  }) async {
    final db = await LocalCacheManager.getDatabase();
    await db.rawUpdate(
      'UPDATE $tableName SET pendingStockDelta = pendingStockDelta + ?, '
      'stockAdjustmentId = ?, isSynced = 0 WHERE id = ?',
      [delta, adjustmentId, productId],
    );
  }

  /// Saves or updates a single product
  static Future<void> saveSingleProduct(ProductModel product) async {
    final db = await LocalCacheManager.getDatabase();
    await db.insert(
      tableName,
      product.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Permanently removes a product from the local SQLite database
  static Future<int> hardDelete(String productId) async {
    final db = await LocalCacheManager.getDatabase();

    return await db.delete(tableName, where: 'id = ?', whereArgs: [productId]);
  }

  /// Clears the entire table
  static Future<void> deleteAllProducts() async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName);
  }
}
