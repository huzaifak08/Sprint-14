import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/tables/ledger_table.dart';
import 'dart:developer' as dev;

import 'package:sprint_14/models/ledger_model.dart';
import 'package:sprint_14/providers/user_provider/user_provider.dart';
import 'package:sprint_14/services/ledger_service.dart';

part 'ledger_provider.g.dart';

@Riverpod(keepAlive: true)
class LedgerNotifier extends _$LedgerNotifier {
  // 🔥 Helper to get UID safely from the current state
  String? get _currentUid => ref.read(userProvider).value?.uid;

  @override
  List<LedgerModel> build() {
    // 1️⃣ Watch the user state.
    // This makes the Ledger list react automatically to login/logout.
    final userState = ref.watch(userProvider);

    userState.whenData((user) {
      if (user != null) {
        _loadLedgers(user.uid);
      } else {
        state = []; // Clear state immediately on logout
      }
    });

    return [];
  }

  /// 1. Initialization Logic (Cache -> Cloud -> Merge)
  Future<void> _loadLedgers(String uid) async {
    // 1️⃣ Load from local SQLite cache first
    final cacheLedgers = await LedgerTable.getAllLedgersFromCache();

    if (cacheLedgers.isNotEmpty) {
      state = cacheLedgers;
    }

    try {
      final service = LedgerService(uid: uid);
      final cloudLedgers = await service.getAllLedgers();

      if (cloudLedgers.isEmpty && cacheLedgers.isEmpty) return;

      final Map<String, LedgerModel> cacheMap = {
        for (final l in cacheLedgers) l.id!: l,
      };

      final List<LedgerModel> mergedLedgers = [];

      for (final cloud in cloudLedgers) {
        final local = cacheMap[cloud.id];

        if (local != null && local.isSynced == false) {
          mergedLedgers.add(local);
        } else {
          mergedLedgers.add(cloud.copyWith(isSynced: true));
        }
      }

      // 4️⃣ Persist results
      await LedgerTable.saveAllFetchedLedgers(mergedLedgers);

      // 🔥 5️⃣ ONLY update state if the data is actually different
      // This prevents unnecessary UI rebuilds if cache and cloud are identical
      if (!_areLedgersEqual(state, mergedLedgers)) {
        state = mergedLedgers;
      }

      syncPendingLedgers();
    } catch (e) {
      dev.log("LedgerNotifier Load Error: $e");
    }
  }

  /// 2. Add Transaction
  Future<void> addLedger(LedgerModel ledger) async {
    final offlineLedger = ledger.copyWith(isSynced: false);

    await LedgerTable.saveSingleLedger(offlineLedger);
    state = [offlineLedger, ...state];

    syncPendingLedgers();
  }

  /// 3. Update Transaction
  Future<void> updateLedger(LedgerModel updatedLedger) async {
    final localUpdated = updatedLedger.copyWith(
      isSynced: false,
      lastSyncAttempt: null,
    );

    state = [
      for (final l in state)
        if (l.id == localUpdated.id) localUpdated else l,
    ];

    await LedgerTable.saveSingleLedger(localUpdated);
    syncPendingLedgers();
  }

  /// 4. Delete Transaction
  Future<void> deleteLedger(String ledgerId) async {
    final ledger = state.firstWhere((l) => l.id == ledgerId);

    final deletedMarker = ledger.copyWith(
      isDeleted: true,
      isSynced: false,
      lastSyncAttempt: null,
    );

    // Update UI immediately (Optimistic UI)
    state = state.where((l) => l.id != ledgerId).toList();

    // Mark for deletion in local cache
    await LedgerTable.saveSingleLedger(deletedMarker);

    await syncPendingLedgers();
  }

  /// 5. Background Synchronization Logic
  Future<void> syncPendingLedgers() async {
    final uid = _currentUid;
    if (uid == null) return;

    final connectivity = await Connectivity().checkConnectivity();
    // Check if any active connection exists (modern connectivity_plus API)
    final isOnline = connectivity.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi,
    );

    if (!isOnline) return;

    final service = LedgerService(uid: uid);
    final unsyncedLedgers = await LedgerTable.getUnsyncedLedgers();

    for (final ledger in unsyncedLedgers) {
      try {
        if (ledger.isDeleted) {
          final bool success = await service.deleteLedgerData(
            ledgerId: ledger.id!,
          );
          if (success) {
            await LedgerTable.hardDelete(ledger.id!);
          }
        } else {
          final bool success = await service.saveLedger(ledger: ledger);

          if (success) {
            final syncedLedger = ledger.copyWith(
              isSynced: true,
              lastSyncAttempt: DateTime.now(),
            );

            await LedgerTable.saveSingleLedger(syncedLedger);

            // Update UI state with the sync success
            state = [
              for (final l in state)
                if (l.id == syncedLedger.id) syncedLedger else l,
            ];
          }
        }
      } catch (e) {
        dev.log("Ledger Sync failed for ${ledger.id}: $e");
        await LedgerTable.saveSingleLedger(
          ledger.copyWith(lastSyncAttempt: DateTime.now()),
        );
      }
    }
  }

  /// Helper: Deep equality check for list state
  bool _areLedgersEqual(List<LedgerModel> a, List<LedgerModel> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
