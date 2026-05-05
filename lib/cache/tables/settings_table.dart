import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/models/app_settings_model.dart';
import 'package:sqflite/sqflite.dart';

class SettingsTable {
  static const String tableName = "sprint_14_app_settings";

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY CHECK (id = 0), 
        isDarkMode INTEGER NOT NULL,
        defaultBusinessId TEXT
      )
    ''');
  }

  static Future<void> saveSettings(AppSettingsModel settings) async {
    final db = await LocalCacheManager.getDatabase();
    await db.insert(tableName, {
      'id': 0,
      ...settings.toJsonDb(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<AppSettingsModel> getSettings() async {
    final db = await LocalCacheManager.getDatabase();
    final maps = await db.query(tableName, where: 'id = 0');
    if (maps.isEmpty) return AppSettingsModel();
    return AppSettingsModel.fromJsonDb(maps.first);
  }
}
