import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/tables/ledger_table.dart';
import 'package:sprint_14/models/ledger_model.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/providers/current_user_provider/current_user_provider.dart';
import 'package:sprint_14/services/ledger_service.dart';
import 'dart:developer' as dev;

part 'ledger_provider.g.dart';

@Riverpod(keepAlive: true)
class LedgerNotifier extends _$LedgerNotifier {
  @override
  Future<List<LedgerModel>> build() async {
    // 1️⃣ Watch the user state directly at the top level to cleanly trigger complete provider rebuilds on auth changes
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return [];

    // 2️⃣ Load from local SQLite cache instantly so the user never looks at a blank loading spinner
    final localCache = await LedgerTable.getAllLedgersFromCache();

    // 3️⃣ Fire silent background cloud alignment pass
    _fetchAndSyncFromCloud(user.uid);

    return localCache;
  }

  /// --- CLOUD SYNC & DIFFERENTIAL CACHE MERGE ---
  Future<void> _fetchAndSyncFromCloud(String uid) async {
    try {
      final service = LedgerService(uid: uid);
      final cloudLedgers = await service.getAllLedgers();

      final currentLocalList = state.value ?? [];

      if (cloudLedgers.isEmpty && currentLocalList.isEmpty) return;

      final Map<String, LedgerModel> localMap = {
        for (final l in currentLocalList) l.id!: l,
      };

      final List<LedgerModel> mergedLedgers = [];

      for (final cloud in cloudLedgers) {
        final local = localMap[cloud.id];

        // If local record exists but hasn't pushed its changes up yet, preserve local edits
        if (local != null && !local.isSynced) {
          mergedLedgers.add(local);
        } else {
          mergedLedgers.add(cloud.copyWith(isSynced: true));
        }
      }

      // Persist merged data to local cache
      await LedgerTable.saveAllFetchedLedgers(mergedLedgers);

      // Update the active state with AsyncData wrapper matching async notifier principles
      state = AsyncData(mergedLedgers);

      // Trigger standard outbound sync process for dirty mutations left over from offline usage
      syncPendingLedgers();
    } catch (e) {
      dev.log(
        "Cloud Ledger Synchronization Disruption: $e",
        name: "LedgerProvider",
      );
    }
  }

  /// --- ADD TRANSACTION ---
  Future<void> addLedger(LedgerModel ledger) async {
    final localItem = ledger.copyWith(isSynced: false, isDeleted: false);

    // Optimistic UI update wrapper
    final current = state.value ?? [];
    state = AsyncData([localItem, ...current]);

    await LedgerTable.saveSingleLedger(localItem);
    syncPendingLedgers();
  }

  /// --- UPDATE TRANSACTION ---
  Future<void> updateLedger(LedgerModel updatedLedger) async {
    final localItem = updatedLedger.copyWith(
      isSynced: false,
      lastSyncAttempt: null,
    );

    state = AsyncData([
      for (final l in state.value ?? [])
        if (l.id == localItem.id) localItem else l,
    ]);

    await LedgerTable.saveSingleLedger(localItem);
    syncPendingLedgers();
  }

  /// --- DELETE TRANSACTION (Soft) ---
  Future<void> deleteLedger(String ledgerId) async {
    final current = state.value ?? [];
    final ledger = current.firstWhere((l) => l.id == ledgerId);

    final deletedMarker = ledger.copyWith(
      isDeleted: true,
      isSynced: false,
      lastSyncAttempt: null,
    );

    // Optimistic extraction from active view layer maps
    state = AsyncData(current.where((l) => l.id != ledgerId).toList());

    await LedgerTable.saveSingleLedger(deletedMarker);
    syncPendingLedgers();
  }

  /// --- BACKGROUND CLOUD SYNC PIPELINE ENGINE ---
  Future<void> syncPendingLedgers() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity.any(
      (result) => result != ConnectivityResult.none,
    );
    if (!isOnline) return;

    final service = LedgerService(uid: user.uid);
    final unsyncedLedgers = await LedgerTable.getUnsyncedLedgers();

    for (final ledger in unsyncedLedgers) {
      try {
        // --- PROCESSS DELETIONS ---
        if (ledger.isDeleted) {
          final bool success = await service.deleteLedgerData(
            ledgerId: ledger.id!,
          );
          if (success) {
            await LedgerTable.hardDelete(ledger.id!);
          }
          continue;
        }

        // --- PROCESS UPSERTS ---
        final bool success = await service.saveLedger(ledger: ledger);

        if (success) {
          final syncedLedger = ledger.copyWith(
            isSynced: true,
            lastSyncAttempt: DateTime.now(),
          );

          await LedgerTable.saveSingleLedger(syncedLedger);

          // Update localized element data mapping parameters inside live running arrays
          final currentList = state.value ?? [];
          state = AsyncData([
            for (final l in currentList)
              if (l.id == syncedLedger.id) syncedLedger else l,
          ]);
        }
      } catch (e) {
        dev.log(
          "Outbound Sync failure for record tracking node ${ledger.id}: $e",
          name: "LedgerProvider",
        );
        await LedgerTable.saveSingleLedger(
          ledger.copyWith(lastSyncAttempt: DateTime.now()),
        );
      }
    }
  }

  /// --- FORCE REFRESH CONTROLLER ---
  Future<void> forceRefresh() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    state = const AsyncLoading();
    await _fetchAndSyncFromCloud(user.uid);
  }
}

// =========================================================================
// FUNCTIONAL HIGH-SPEED SCOPED ITEM TARGET FAMILY PROVIDER
// =========================================================================
@riverpod
Future<LedgerModel> singleLedger(Ref ref, String ledgerId) async {
  final List<LedgerModel> ledgers = await ref.watch(ledgerProvider.future);
  return ledgers.firstWhere((element) => element.id == ledgerId);
}
