import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/models/project_model.dart';
import 'package:sqflite/sqflite.dart';

class ProjectTable {
  static const String tableName = "projects";

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        appName TEXT NOT NULL,
        owner TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        currentStep INTEGER NOT NULL,
        paymentStatus TEXT NOT NULL,
        keystorePassword TEXT NOT NULL,
        backupCodes TEXT NOT NULL,
        testingDayAtUpdate INTEGER,
        testingUpdateDate TEXT,
        isSynced INTEGER NOT NULL,
        lastSyncAttempt TEXT,
        isDeleted INTEGER NOT NULL,
        endDate TEXT,
        createdAt TEXT
      )
    ''');
  }

  static Future<void> saveAllFetchedProjects(
    List<ProjectModel> projects,
  ) async {
    final db = await LocalCacheManager.getDatabase();
    Batch batch = db.batch();
    for (var project in projects) {
      batch.insert(
        tableName,
        project.toJsonDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<void> saveSingleProject(ProjectModel project) async {
    final db = await LocalCacheManager.getDatabase();
    await db.insert(
      tableName,
      project.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ProjectModel>> getUnsyncedProjects() async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(
      tableName,
      where: 'isSynced = ?',
      whereArgs: [0],
    );

    return maps.map(ProjectModel.fromJsonDb).toList();
  }

  static Future<List<ProjectModel>> getAllProjectsFromCache() async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(tableName);
    return List.generate(maps.length, (i) => ProjectModel.fromJsonDb(maps[i]));
  }

  static Future<ProjectModel?> getSingleProjectById(String projectId) async {
    final db = await LocalCacheManager.getDatabase();

    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [projectId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return ProjectModel.fromJsonDb(maps.first);
  }

  static Future<void> deleteSingleProject(String projectId) async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName, where: 'id = ?', whereArgs: [projectId]);
  }

  static Future<void> deleteAllProjects() async {
    final db = await LocalCacheManager.getDatabase();
    await db.delete(tableName);
  }
}
