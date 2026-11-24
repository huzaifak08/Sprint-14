import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:digital_munshi/cache/tables/ledger_table.dart';
import 'package:digital_munshi/models/ledger_model.dart';
import 'package:digital_munshi/providers/auth_provider/auth_provider.dart';
import 'package:digital_munshi/cache/init_cache.dart';
import 'package:digital_munshi/cache/sync/sync_merge.dart';
import 'package:digital_munshi/cache/sync/sync_utils.dart';
import 'package:digital_munshi/services/ledger_service.dart';
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
      // Offline, Firestore answers from its partial cache; skip so nothing
      // is mistaken for a remote deletion.
      if (!await isOnline()) return;

      // Push pending local changes first so the fetch reflects them.
      await syncPendingLedgers();

      final cloudLedgers = await LedgerService(uid: uid).getAllLedgers();
      final localRows = await LocalCacheManager.queryAllRows(
        LedgerTable.tableName,
      );
      final local = localRows.map(LedgerModel.fromJsonDb).toList();

      final result = mergeCloudWithLocal<LedgerModel>(
        cloud: cloudLedgers,
        local: local,
        idOf: (l) => l.id ?? '',
        isSynced: (l) => l.isSynced,
        isDeleted: (l) => l.isDeleted,
        markSynced: (l) => l.copyWith(isSynced: true),
        sort: (a, b) => b.dateTime.compareTo(a.dateTime),
      );

      await LedgerTable.saveAllFetchedLedgers(result.toSave);
      await LocalCacheManager.deleteByIds(
        LedgerTable.tableName,
        result.toRemove,
      );

      state = AsyncData(result.visible);
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
    final index = current.indexWhere((l) => l.id == ledgerId);
    if (index == -1) return;
    final ledger = current[index];

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
  /// Serialised with [SyncLock] so overlapping calls never double-upload.
  Future<void> syncPendingLedgers() {
    return SyncLock.run('ledgers', _syncPendingLedgers);
  }

  Future<void> _syncPendingLedgers() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;
    if (!await isOnline()) return;

    final service = LedgerService(uid: user.uid);
    final unsyncedLedgers = await LedgerTable.getUnsyncedLedgers();

    for (final ledger in unsyncedLedgers) {
      try {
        // --- PROCESS DELETIONS ---
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
          final marked = await LocalCacheManager.markSyncedIfUnchanged(
            LedgerTable.tableName,
            ledger.toJsonDb(),
          );
          if (marked) _setSyncedInState(ledger.id);
        } else {
          await LedgerTable.saveSingleLedger(
            ledger.copyWith(lastSyncAttempt: DateTime.now()),
          );
        }
      } catch (e) {
        dev.log(
          "Outbound sync failed for ledger ${ledger.id}: $e",
          name: "LedgerProvider",
        );
        await LedgerTable.saveSingleLedger(
          ledger.copyWith(lastSyncAttempt: DateTime.now()),
        );
      }
    }
  }

  /// Flips the sync flag of the CURRENT on-screen item (never replaces it
  /// with the uploaded copy, which may be older than the latest edit).
  void _setSyncedInState(String? id) {
    final currentList = state.value ?? [];
    state = AsyncData([
      for (final l in currentList)
        if (l.id == id) l.copyWith(isSynced: true) else l,
    ]);
  }

  /// --- FORCE REFRESH CONTROLLER ---
  Future<void> forceRefresh() async {
    final user = ref.read(authControllerProvider).value;
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
