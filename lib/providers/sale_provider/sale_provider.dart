import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/cache/sync/sync_merge.dart';
import 'package:sprint_14/cache/sync/sync_utils.dart';
import 'package:sprint_14/cache/tables/sale_table.dart';
import 'package:sprint_14/models/sale_model.dart';
import 'package:sprint_14/providers/current_user_provider/current_user_provider.dart';
import 'package:sprint_14/services/sale_service.dart';
import 'dart:developer' as dev;

part 'sale_provider.g.dart';

@Riverpod(keepAlive: true)
class SaleNotifier extends _$SaleNotifier {
  @override
  FutureOr<List<SaleModel>> build(String businessId) async {
    // Watches the user to reset state on logout/login
    final userState = ref.watch(currentUserProvider);
    if (userState.value == null) return [];

    // Phase 1: Load from cache immediately during initialization
    final cache = await SaleTable.getBusinessSalesFromCache(businessId);

    // Phase 2: Fire and forget the cloud sync so it doesn't block the UI
    _performSilentCloudSync(businessId);

    return cache;
  }

  /// 1. Primary Load Logic (Used for manual refreshes or initial trigger)
  Future<void> loadSales(String businessId) async {
    // Phase 1: Immediate Cache Delivery
    try {
      final cache = await SaleTable.getBusinessSalesFromCache(businessId);
      state = AsyncValue.data(cache);
      dev.log("UI updated with local cache", name: "SaleProvider");
    } catch (e, stack) {
      dev.log("Cache Read Error: $e", name: "SaleProvider");
      state = AsyncValue.error(e, stack);
      return;
    }

    // Phase 2: Silent Cloud Sync
    _performSilentCloudSync(businessId);
  }

  /// Internal helper to sync cloud data without interrupting the user
  Future<void> _performSilentCloudSync(String businessId) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      if (!await isOnline()) return;

      // 1. Push local changes first so the fetch already contains them.
      await syncPending(businessId);

      // 2. Fetch fresh cloud data
      final cloudSales = await SaleService(
        uid: user.uid,
      ).getBusinessSales(businessId);

      // 3. Merge with every local row (incl. unsynced / soft-deleted) so the
      //    cloud copy never overwrites changes that haven't been uploaded.
      final localRows = await LocalCacheManager.queryAllRows(
        SaleTable.tableName,
        where: 'businessId = ?',
        whereArgs: [businessId],
      );
      final local = localRows.map(SaleModel.fromJsonDb).toList();

      final result = mergeCloudWithLocal<SaleModel>(
        cloud: cloudSales,
        local: local,
        idOf: (s) => s.id,
        isSynced: (s) => s.isSynced,
        isDeleted: (s) => s.isDeleted,
        markSynced: (s) => s.copyWith(isSynced: true),
        sort: (a, b) => b.dateTime.compareTo(a.dateTime),
      );

      await SaleTable.saveAllSales(result.toSave);
      await LocalCacheManager.deleteByIds(SaleTable.tableName, result.toRemove);

      state = AsyncValue.data(result.visible);
    } catch (e) {
      dev.log("Silent Cloud Sync Failed: $e", name: "SaleProvider");
    }
  }

  /// 2. Record Sale (Optimistic)
  Future<void> recordSale(SaleModel sale) async {
    final local = sale.copyWith(isSynced: false, isDeleted: false);

    // Update State Optimistically
    final currentSales = state.value ?? [];
    state = AsyncData([local, ...currentSales]);

    await SaleTable.saveSingleSale(local);
    _performSilentCloudSync(sale.businessId);
  }

  /// 3. Update Sale (Optimistic)
  Future<void> updateSale(SaleModel updatedSale) async {
    final local = updatedSale.copyWith(isSynced: false);

    final currentSales = state.value ?? [];
    state = AsyncData([
      for (final s in currentSales)
        if (s.id == local.id) local else s,
    ]);

    await SaleTable.saveSingleSale(local);
    _performSilentCloudSync(local.businessId);
  }

  /// 4. Delete Sale (Optimistic Soft Delete)
  Future<void> deleteSale(String saleId, String businessId) async {
    final currentSales = state.value ?? [];
    final index = currentSales.indexWhere((s) => s.id == saleId);
    if (index == -1) return;
    final sale = currentSales[index];
    final deletedMarker = sale.copyWith(isDeleted: true, isSynced: false);

    // Remove from UI immediately
    state = AsyncData(currentSales.where((s) => s.id != saleId).toList());

    await SaleTable.saveSingleSale(deletedMarker);
    _performSilentCloudSync(businessId);
  }

  /// 5. Background Sync Engine
  Future<void> syncPending(String businessId) {
    return SyncLock.run('sales_$businessId', () => _syncPending(businessId));
  }

  Future<void> _syncPending(String businessId) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || !await isOnline()) return;

    final service = SaleService(uid: user.uid);
    final unsynced = await SaleTable.getUnsyncedSalesByBusiness(businessId);

    for (final s in unsynced) {
      try {
        if (s.isDeleted) {
          final success = await service.deleteSaleData(
            businessId: s.businessId,
            saleId: s.id,
          );
          if (success) await SaleTable.hardDelete(s.id);
        } else {
          final success = await service.recordSale(sale: s);
          if (success &&
              await LocalCacheManager.markSyncedIfUnchanged(
                SaleTable.tableName,
                s.toJsonDb(),
              )) {
            final current = state.value ?? [];
            state = AsyncData([
              for (final item in current)
                if (item.id == s.id) item.copyWith(isSynced: true) else item,
            ]);
          }
        }
      } catch (e) {
        dev.log("Sale Sync Failed: $e", name: "SaleProvider");
      }
    }
  }
}
