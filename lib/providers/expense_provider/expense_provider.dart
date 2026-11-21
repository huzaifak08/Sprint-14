import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/cache/sync/sync_merge.dart';
import 'package:sprint_14/cache/sync/sync_utils.dart';
import 'package:sprint_14/cache/tables/expense_table.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/models/expense_model.dart';
import 'package:sprint_14/services/expense_service.dart';
import 'dart:developer' as dev;

part 'expense_provider.g.dart';

@Riverpod(keepAlive: true)
class ExpenseNotifier extends _$ExpenseNotifier {
  @override
  Future<List<ExpenseModel>> build(String businessId) async {
    // Rebuild on login/logout so another account's data is never shown.
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return [];

    // 1. Load from Local Cache immediately for fast UI response
    final cache = await ExpenseTable.getAllExpensesFromCache(businessId);

    // 2. Trigger silent background sync from cloud
    _fetchAndSyncFromCloud(businessId);

    return cache;
  }

  /// --- 1. Cloud Fetch & Merge ---
  Future<void> _fetchAndSyncFromCloud(String businessId) async {
    try {
      // Offline, Firestore answers from its partial cache; skip so nothing
      // is mistaken for a remote deletion.
      if (!await isOnline()) return;

      // Push pending local changes first so the fetch reflects them.
      await syncPending(businessId);

      final cloud = await ExpenseService(
        businessId: businessId,
      ).getAllExpenses();

      final localRows = await LocalCacheManager.queryAllRows(
        ExpenseTable.tableName,
        where: 'businessId = ?',
        whereArgs: [businessId],
      );
      final local = localRows.map(ExpenseModel.fromJsonDb).toList();

      final result = mergeCloudWithLocal<ExpenseModel>(
        cloud: cloud,
        local: local,
        idOf: (e) => e.id,
        isSynced: (e) => e.isSynced,
        isDeleted: (e) => e.isDeleted,
        markSynced: (e) => e.copyWith(isSynced: true),
        sort: (a, b) => b.dateTime.compareTo(a.dateTime),
      );

      await ExpenseTable.saveAllFetchedExpenses(result.toSave);
      await LocalCacheManager.deleteByIds(
        ExpenseTable.tableName,
        result.toRemove,
      );
      state = AsyncData(result.visible);
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
    final index = current.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final expense = current[index];
    final deletedMarker = expense.copyWith(isDeleted: true, isSynced: false);

    // Remove from UI list immediately
    state = AsyncData(current.where((e) => e.id != id).toList());

    await ExpenseTable.saveSingleExpense(deletedMarker);
    syncPending(businessId);
  }

  /// --- 5. Background Sync Logic ---
  Future<void> syncPending(String businessId) {
    return SyncLock.run('expenses_$businessId', () => _syncPending(businessId));
  }

  Future<void> _syncPending(String businessId) async {
    if (!await isOnline()) return;

    final service = ExpenseService(businessId: businessId);
    // Only this business's rows: uploading another business's expenses here
    // would write them into the wrong Firestore collection.
    final unsynced = (await ExpenseTable.getUnsyncedExpenses())
        .where((e) => e.businessId == businessId)
        .toList();

    for (final e in unsynced) {
      try {
        if (e.isDeleted) {
          final success = await service.deleteExpenseData(expenseId: e.id);
          if (success) await ExpenseTable.hardDelete(e.id);
          continue;
        }

        final success = await service.saveExpense(expense: e);
        if (success &&
            await LocalCacheManager.markSyncedIfUnchanged(
              ExpenseTable.tableName,
              e.toJsonDb(),
            )) {
          final current = state.value ?? [];
          state = AsyncData([
            for (final item in current)
              if (item.id == e.id) item.copyWith(isSynced: true) else item,
          ]);
        }
      } catch (err) {
        dev.log(
          "Sync failed for expense ${e.id}: $err",
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
