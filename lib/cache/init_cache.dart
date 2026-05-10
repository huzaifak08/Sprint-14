import 'dart:developer' as dev;
import 'package:flutter/foundation.dart' show kIsWeb; // Add this
import 'package:sprint_14/cache/tables/business_table.dart';
import 'package:sprint_14/cache/tables/ledger_table.dart';
import 'package:sprint_14/cache/tables/product_table.dart';
import 'package:sprint_14/cache/tables/sale_table.dart';
import 'package:sprint_14/cache/tables/settings_table.dart';
import 'package:sprint_14/cache/tables/user_table.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalCacheManager {
  static Database? database;

  /// Updated to return nullable Database to support Web
  static Future<Database?> getDatabase() async {
    if (kIsWeb) return null; // 🔥 Immediate exit for Web

    if (database != null) {
      return database!;
    }

    database = await initDatabase();
    return database;
  }

  static Future<Database?> initDatabase() async {
    if (kIsWeb) return null; // 🔥 Immediate exit for Web

    try {
      final documentsDirectory = await getDatabasesPath();
      final path = join(documentsDirectory, 'sprint_14.db');
      dev.log("Cache Path: $path");

      return await openDatabase(
        path,
        version: 4,
        onCreate: (db, version) async {
          await LedgerTable.createTable(db);
          await UserTable.createTable(db);
          await BusinessTable.createTable(db);
          await ProductTable.createTable(db);
          await SaleTable.createTable(db);
          await SettingsTable.createTable(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 3) {
            await BusinessTable.createTable(db);
            await ProductTable.createTable(db);
            await SaleTable.createTable(db);
            await SettingsTable.createTable(db);
          }

          if (oldVersion < 4) {
            try {
              await db.execute(
                "ALTER TABLE products ADD COLUMN currentStock REAL NOT NULL DEFAULT 0.0",
              );
              dev.log(
                "Database Upgraded: Added currentStock to products table",
                name: "init Cache",
              );
            } catch (e) {
              dev.log("Migration Error: $e", name: "init Cache");
            }
          }
        },
      );
    } catch (e) {
      dev.log("SQLite Initialization Failed: $e", name: "init Cache");
      return null;
    }
  }

  static Future<void> deleteAllCacheData() async {
    if (kIsWeb) return; // 🔥 No-op for Web

    final db = await getDatabase();
    if (db == null) return;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
    );
    for (var table in tables) {
      final tableName = table['name'].toString();
      await db.delete(tableName);
    }
  }
}
