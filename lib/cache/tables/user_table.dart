import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/models/user_model.dart';
import 'package:sqflite/sqflite.dart';

class UserTable {
  static const String tableName = "users";

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        uid TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT,
        createdAt TEXT NOT NULL,
        isEmailVerified INTEGER NOT NULL,
        isSynced INTEGER NOT NULL,
        lastSyncAttempt TEXT
      )
    ''');
  }

  static Future<void> saveUser(UserModel user) async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return;
    await db.insert(
      tableName,
      user.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<UserModel?> getUser(String uid) async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return null;
    final maps = await db.query(
      tableName,
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserModel.fromJsonDb(maps.first);
  }

  static Future<void> deleteUser(String uid) async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return;
    await db.delete(tableName, where: 'uid = ?', whereArgs: [uid]);
  }

  static Future<void> deleteAllUsers() async {
    final db = await LocalCacheManager.getDatabase();
    if (db == null) return;
    await db.delete(tableName);
  }
}
