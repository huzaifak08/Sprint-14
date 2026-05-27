import 'dart:developer' as dev;
import 'package:sprint_14/cache/tables/business_table.dart';
import 'package:sprint_14/cache/tables/event_ledger_table.dart';
import 'package:sprint_14/cache/tables/event_participant_table.dart';
import 'package:sprint_14/cache/tables/event_transaction_table.dart';
import 'package:sprint_14/cache/tables/expense_table.dart';
import 'package:sprint_14/cache/tables/ledger_table.dart';
import 'package:sprint_14/cache/tables/notification_table.dart';
import 'package:sprint_14/cache/tables/participant_table.dart';
import 'package:sprint_14/cache/tables/product_table.dart';
import 'package:sprint_14/cache/tables/sale_table.dart';
import 'package:sprint_14/cache/tables/settings_table.dart';
import 'package:sprint_14/cache/tables/settlement_milestone_table.dart';
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
      version: 17, // Increment version number when schema changes
      onCreate: (db, version) async {
        // await ProjectTable.createTable(db);
        await LedgerTable.createTable(db);
        await UserTable.createTable(db);
        await BusinessTable.createTable(db);
        await ProductTable.createTable(db);
        await SaleTable.createTable(db);
        await ExpenseTable.createTable(db);
        await ParticipantTable.createTable(db);
        await NotificationTable.createTable(db);
        await SettingsTable.createTable(db);
        await EventLedgerTable.createTable(db);
        await EventParticipantTable.createTable(db);
        await EventTransactionTable.createTable(db);
        await SettlementMilestoneTable.createTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 14) {
          dev.log(
            "Migration started from v$oldVersion to v$newVersion. Flushing cache...",
          );

          // 1. Get all table names existing in the DB
          final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
          );

          // 2. Drop every table to clear the slate
          for (var table in tables) {
            final tableName = table['name'].toString();
            await db.execute("DROP TABLE IF EXISTS $tableName");
          }

          // 3. Re-run onCreate logic to build all tables with the NEW schema
          await LedgerTable.createTable(db);
          await UserTable.createTable(db);
          await BusinessTable.createTable(db);
          await ProductTable.createTable(db);
          await SaleTable.createTable(db);
          await ExpenseTable.createTable(db);
          await SettingsTable.createTable(db);
          await EventLedgerTable.createTable(db);
          await EventParticipantTable.createTable(db);
          await EventTransactionTable.createTable(db);
          await SettlementMilestoneTable.createTable(db);

          dev.log("Cache flushed and tables rebuilt successfully.");
        }

        if (oldVersion < 15) {
          await ParticipantTable.createTable(db);
          dev.log("v15- Particpant Table created");
        }

        if (oldVersion < 16) {
          await NotificationTable.createTable(db);
          dev.log("v16- Particpant Table created");
        }

        if (oldVersion < 17) {
          await EventLedgerTable.createTable(db);
          await EventParticipantTable.createTable(db);
          await EventTransactionTable.createTable(db);
          await SettlementMilestoneTable.createTable(db);

          dev.log("v17- Event Ledger tables created");
        }

        // New Changes Here:
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
