import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/tables/expense_table.dart';
import 'package:sprint_14/models/expense_model.dart';
import 'package:sprint_14/services/expense_service.dart';
import 'dart:developer' as dev;

part 'expense_provider.g.dart';

@Riverpod(keepAlive: true)
class ExpenseNotifier extends _$ExpenseNotifier {
  @override
  Future<List<ExpenseModel>> build(String businessId) async {
    // 1. Load from Local Cache immediately for fast UI response
    final cache = await ExpenseTable.getAllExpensesFromCache(businessId);

    // 2. Trigger silent background sync from cloud
    _fetchAndSyncFromCloud(businessId);

    return cache;
  }

  /// --- 1. Cloud Fetch & Merge ---
  Future<void> _fetchAndSyncFromCloud(String businessId) async {
    try {
      final service = ExpenseService(businessId: businessId);
      final cloud = await service.getAllExpenses();
      final currentList = state.value ?? [];

      final Map<String, ExpenseModel> currentMap = {
        for (final e in currentList) e.id: e,
      };
      final List<ExpenseModel> merged = [];

      for (final c in cloud) {
        final local = currentMap[c.id];
        // If local exists and is not synced, keep local (it has pending changes)
        if (local != null && !local.isSynced) {
          merged.add(local);
        } else {
          merged.add(c.copyWith(isSynced: true));
        }
      }

      await ExpenseTable.saveAllFetchedExpenses(merged);
      state = AsyncData(merged);

      // Attempt to push any locally created/edited expenses to the cloud
      syncPending(businessId);
    } catch (e) {
      dev.log("Cloud Expense Fetch Error: $e", name: "ExpenseProvider");
    }
  }

  /// --- 2. Add Expense ---
  Future<void> addExpense(ExpenseModel expense) async {
    final local = expense.copyWith(isSynced: false, isDeleted: false);

    // Update UI immediately
    final current = state.value ?? [];
    state = AsyncData([local, ...current]);

    await ExpenseTable.saveSingleExpense(local);
    syncPending(expense.businessId);
  }

  /// --- 3. Update Expense ---
  Future<void> updateExpense(ExpenseModel updated) async {
    final local = updated.copyWith(isSynced: false);

    state = AsyncData([
      for (final e in state.value ?? [])
        if (e.id == local.id) local else e,
    ]);

    await ExpenseTable.saveSingleExpense(local);
    syncPending(updated.businessId);
  }

  /// --- 4. Delete Expense (Soft Delete) ---
  Future<void> deleteExpense(String id, String businessId) async {
    final current = state.value ?? [];
    final expense = current.firstWhere((e) => e.id == id);
    final deletedMarker = expense.copyWith(isDeleted: true, isSynced: false);

    // Remove from UI list immediately
    state = AsyncData(current.where((e) => e.id != id).toList());

    await ExpenseTable.saveSingleExpense(deletedMarker);
    syncPending(businessId);
  }

  /// --- 5. Background Sync Logic ---
  Future<void> syncPending(String businessId) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;

    final service = ExpenseService(businessId: businessId);
    final unsynced = await ExpenseTable.getUnsyncedExpenses();

    for (final e in unsynced) {
      try {
        if (e.isDeleted) {
          final success = await service.deleteExpenseData(expenseId: e.id);
          if (success) await ExpenseTable.hardDelete(e.id);
          continue;
        }

        final success = await service.saveExpense(expense: e);
        if (success) {
          final synced = e.copyWith(
            isSynced: true,
            lastSyncAttempt: DateTime.now(),
          );
          await ExpenseTable.saveSingleExpense(synced);

          // Update local state to reflect synced checkmark (if UI uses it)
          final current = state.value ?? [];
          state = AsyncData([
            for (final item in current)
              if (item.id == synced.id) synced else item,
          ]);
        }
      } catch (e) {
        dev.log(
          "Sync Failed for expense ${e.toString()}: $e",
          name: "ExpenseProvider",
        );
      }
    }
  }

  /// --- 6. Totals & Reports ---
  /// Helper to get the total sum of expenses currently in state
  double getTotalExpenses() {
    final list = state.value ?? [];
    return list.fold(0, (sum, item) => sum + item.amount);
  }
}
