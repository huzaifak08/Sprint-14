import 'dart:developer' as dev;
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

  static Future<Database> getDatabase() async {
    if (database != null) {
      return database!;
    }

    database = await initDatabase();
    return database!;
  }

  static Future<Database> initDatabase() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, 'sprint_14.db');
    dev.log("Cache Path: $path");

    return openDatabase(
      path,
      version: 6, // Increment version number when schema changes
      onCreate: (db, version) async {
        // await ProjectTable.createTable(db);
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

        if (oldVersion < 5) {
          try {
            // Migrating Sales Table for Multi-Product support
            // We rename the old columns and add the new plural ones
            await db.execute(
              "ALTER TABLE sales RENAME COLUMN productId TO productIds",
            );
            await db.execute(
              "ALTER TABLE sales RENAME COLUMN productTitle TO productTitles",
            );
            dev.log(
              "Database Upgraded to v5: Sales table migrated to multi-product schema",
            );
          } catch (e) {
            dev.log("Migration Error v5: $e. Recreating table...");
            // Fallback: Recreate table if rename fails
            await db.execute("DROP TABLE IF EXISTS sales");
            await SaleTable.createTable(db);
          }

          if (oldVersion < 6) {
            try {
              await db.execute(
                "ALTER TABLE sales ADD COLUMN measurement REAL NOT NULL DEFAULT 1.0",
              );
              dev.log(
                "Database Upgraded to v6: Added measurement column to sales table",
              );
            } catch (e) {
              dev.log("Migration Error v6: $e");
            }
          }
        }
      },
    );
  }

  static Future<void> deleteAllCacheData() async {
    final db = await getDatabase();
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
    );
    for (var table in tables) {
      final tableName = table['name'].toString();
      await db.delete(tableName);
    }
  }
}
