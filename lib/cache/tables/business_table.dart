import 'package:sqflite/sqflite.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/models/business_model.dart';

class BusinessTable {
  static const String tableName = "businesses";

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        currency TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        ownerId TEXT NOT NULL,
        isSynced INTEGER NOT NULL,
        lastSyncAttempt TEXT,
        isDeleted INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> saveSingleBusiness(BusinessModel business) async {
    final db = await LocalCacheManager.getDatabase();
    await db.insert(
      tableName,
      business.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<BusinessModel>> getAllBusinessesFromCache() async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'isDeleted = ?',
      whereArgs: [0],
    );
    return maps.map(BusinessModel.fromJsonDb).toList();
  }

  /// Bulk save for syncing from cloud
  static Future<void> saveAllFetchedBusinesses(
    List<BusinessModel> businesses,
  ) async {
    final db = await LocalCacheManager.getDatabase();

    // Using a batch for performance when handling multiple shop profiles
    Batch batch = db.batch();

    for (var business in businesses) {
      batch.insert(
        tableName,
        business.toJsonDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Gets all business profiles waiting for cloud sync
  static Future<List<BusinessModel>> getUnsyncedBusinesses() async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'isSynced = ?',
      whereArgs: [0],
    );

    return maps.map(BusinessModel.fromJsonDb).toList();
  }

  static Future<void> hardDelete(String id) async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
