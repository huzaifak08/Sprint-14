import 'package:sqflite/sqflite.dart';
import 'package:sprint_14/models/expense_model.dart';
import 'dart:developer' as dev;

class ExpenseTable {
  static const String tableName = 'expenses';

  /// --- CREATE TABLE ---
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        businessId TEXT NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        amount REAL NOT NULL,
        dateTime TEXT NOT NULL,
        recordedById TEXT NOT NULL,
        isSynced INTEGER NOT NULL,
        lastSyncAttempt TEXT,
        isDeleted INTEGER NOT NULL
      )
    ''');
    dev.log("Expense Table Created", name: "ExpenseTable");
  }

  /// --- SAVE / UPDATE SINGLE EXPENSE ---
  static Future<void> saveSingleExpense(ExpenseModel expense) async {
    final db = await openDatabase('sprint_14.db'); // Ensure path consistency
    await db.insert(
      tableName,
      expense.toJsonDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// --- SAVE ALL (BULK FETCH) ---
  static Future<void> saveAllFetchedExpenses(
    List<ExpenseModel> expenses,
  ) async {
    final db = await openDatabase('sprint_14.db');
    final batch = db.batch();
    for (var e in expenses) {
      batch.insert(
        tableName,
        e.toJsonDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// --- GET ALL EXPENSES FOR A BUSINESS ---
  /// Filters out soft-deleted items automatically
  static Future<List<ExpenseModel>> getAllExpensesFromCache(
    String businessId,
  ) async {
    final db = await openDatabase('sprint_14.db');
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'businessId = ? AND isDeleted = 0',
      whereArgs: [businessId],
      orderBy: 'dateTime DESC',
    );

    return List.generate(maps.length, (i) => ExpenseModel.fromJsonDb(maps[i]));
  }

  /// --- GET UNSYNCED EXPENSES ---
  /// Used by your syncPending() provider logic
  static Future<List<ExpenseModel>> getUnsyncedExpenses() async {
    final db = await openDatabase('sprint_14.db');
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'isSynced = 0',
    );

    return List.generate(maps.length, (i) => ExpenseModel.fromJsonDb(maps[i]));
  }

  /// --- HARD DELETE ---
  /// Called only after successful cloud deletion sync
  static Future<void> hardDelete(String id) async {
    final db = await openDatabase('sprint_14.db');
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// --- CLEAR TABLE ---
  static Future<void> clearTable() async {
    final db = await openDatabase('sprint_14.db');
    await db.delete(tableName);
  }
}
