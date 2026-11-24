import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_munshi/cache/sync/sync_utils.dart';
import 'package:digital_munshi/helpers/constants.dart';
import 'package:digital_munshi/models/expense_model.dart';
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
  /// Writes the expense unless the cloud copy was edited more recently, in
  /// which case nothing is written and the newer cloud copy is returned.
  /// Returns null when the local copy was saved. Throws on failure.
  Future<ExpenseModel?> saveExpense({required ExpenseModel expense}) {
    final doc = expensesRef.doc(expense.id);
    return FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final data = snap.data();
      if (data != null) {
        final cloud = ExpenseModel.fromMap({...data, 'id': snap.id});
        if (isNewerEdit(cloud.updatedAt, expense.updatedAt)) return cloud;
      }
      tx.set(doc, expense.toMap(), SetOptions(merge: true));
      return null;
    });
  }

  /// --- 2. FETCH ALL EXPENSES ---
  /// Retrieves all records for this business. Throws on failure: returning
  /// an empty list would make the sync think every expense was deleted.
  Future<List<ExpenseModel>> getAllExpenses() async {
    try {
      final snapshot = await expensesRef
          .orderBy('dateTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      dev.log("Error fetching expenses: $e", name: "ExpenseService");
      rethrow;
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
}
