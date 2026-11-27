import 'dart:developer' as dev;
import 'package:sqflite/sqflite.dart';
import 'package:digital_munshi/cache/init_cache.dart';
import 'package:digital_munshi/models/project_model.dart';

/// Local cache of the owner's projects (`users/{uid}/projects`).
class ProjectTable {
  static const String tableName = 'projects';

  /// --- CREATE TABLE ---
  /// Called by LocalCacheManager during onCreate or onUpgrade.
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        appName TEXT NOT NULL,
        owner TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        keystorePassword TEXT NOT NULL,
        backupCodes TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        endDate TEXT NOT NULL,
        currentStep INTEGER NOT NULL,
        paymentStatus TEXT NOT NULL,
        testingDayAtUpdate INTEGER,
        testingUpdateDate TEXT,
        updatedAt TEXT,
        isSynced INTEGER NOT NULL,
        lastSyncAttempt TEXT,
        isDeleted INTEGER NOT NULL
      )
    ''');
    dev.log("Project Table Created", name: "ProjectTable");
  }

  /// --- VISIBLE PROJECTS (newest first) ---
  static Future<List<ProjectModel>> getProjects() async {
    final db = await LocalCacheManager.getDatabase();
    final rows = await db.query(
      tableName,
      where: 'isDeleted = 0',
      orderBy: 'createdAt DESC',
    );
    return rows.map(ProjectModel.fromJsonDb).toList();
  }

  /// --- EVERY ROW (incl. pending deletes), for the sync merge ---
  static Future<List<ProjectModel>> getAllRows() async {
    final rows = await LocalCacheManager.queryAllRows(tableName);
    return rows.map(ProjectModel.fromJsonDb).toList();
  }

  static Future<List<ProjectModel>> getUnsynced() async {
    final db = await LocalCacheManager.getDatabase();
    final rows = await db.query(tableName, where: 'isSynced = 0');
    return rows.map(ProjectModel.fromJsonDb).toList();
  }

  static Future<bool> hasUnsynced() async {
    final db = await LocalCacheManager.getDatabase();
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName WHERE isSynced = 0'),
    );
    return (count ?? 0) > 0;
  }

  /// --- SAVE LOCAL EDIT ---
  static Future<void> save(ProjectModel project) async {
    final db = await LocalCacheManager.getDatabase();
    await db.insert(
      tableName,
      project.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// --- APPLY CLOUD COPIES ---
  /// Writes [projects] from the cloud without ever replacing a row that has
  /// pending local changes, even one edited after the merge was computed:
  /// the update only touches synced rows and the insert skips existing ones.
  static Future<void> saveFromCloud(List<ProjectModel> projects) async {
    if (projects.isEmpty) return;
    final db = await LocalCacheManager.getDatabase();
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final p in projects) {
        final row = p.toJsonDb();
        batch.update(
          tableName,
          row,
          where: 'id = ? AND isSynced = 1',
          whereArgs: [p.id],
        );
        batch.insert(
          tableName,
          row,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// --- REMOVE CLOUD-DELETED ROWS ---
  /// Only synced rows are removed, so a project edited locally in the
  /// meantime survives (and is re-uploaded).
  static Future<void> removeSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await LocalCacheManager.getDatabase();
    final batch = db.batch();
    for (final id in ids) {
      batch.delete(
        tableName,
        where: 'id = ? AND isSynced = 1',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  /// --- HARD DELETE (after the cloud delete succeeded) ---
  static Future<void> hardDelete(String id) async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
