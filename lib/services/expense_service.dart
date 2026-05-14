import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sprint_14/helpers/constants.dart';
import 'package:sprint_14/models/expense_model.dart';
import 'dart:developer' as dev;

class ExpenseService {
  final String businessId;

  ExpenseService({required this.businessId});

  // Expense Collection Reference:
  CollectionReference<Map<String, dynamic>> get expensesRef => FirebaseFirestore
      .instance
      .collection(businessesCollection)
      .doc(businessId)
      .collection(expensesCollection);

  /// --- 1. SAVE OR UPDATE EXPENSE ---
  /// Used for both initial sync and editing existing expenses
  Future<bool> saveExpense({required ExpenseModel expense}) async {
    try {
      dev.log(
        "Syncing Expense to cloud: ${expense.category}",
        name: "ExpenseService",
      );

      await expensesRef
          .doc(expense.id)
          .set(expense.toMap(), SetOptions(merge: true));

      return true;
    } catch (err) {
      dev.log("Cloud Expense Sync Error: $err", name: "ExpenseService");
      return false;
    }
  }

  /// --- 2. FETCH ALL EXPENSES ---
  /// Retrieves all records for this business (useful for initial data hydration)
  Future<List<ExpenseModel>> getAllExpenses() async {
    try {
      final snapshot = await expensesRef
          .orderBy('dateTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      dev.log("Error fetching expenses: $e", name: "ExpenseService");
      return [];
    }
  }

  /// --- 3. DELETE EXPENSE DATA ---
  /// Physically removes the document from Firestore after a soft-delete sync
  Future<bool> deleteExpenseData({required String expenseId}) async {
    try {
      dev.log(
        "Permanently deleting expense from cloud: $expenseId",
        name: "ExpenseService",
      );

      await expensesRef.doc(expenseId).delete();

      return true;
    } catch (err) {
      dev.log("Cloud Expense Deletion Error: $err", name: "ExpenseService");
      return false;
    }
  }

  /// --- 4. FETCH EXPENSES BY DATE RANGE ---
  /// Strategic for "Daily Net Profit" calculations
  Future<List<ExpenseModel>> getExpensesByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final snapshot = await expensesRef
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      dev.log("Date range fetch error: $e", name: "ExpenseService");
      return [];
    }
  }
}
