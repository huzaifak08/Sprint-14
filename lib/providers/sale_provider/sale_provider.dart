import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:digital_munshi/cache/init_cache.dart';
import 'package:digital_munshi/cache/sync/sync_merge.dart';
import 'package:digital_munshi/cache/sync/sync_utils.dart';
import 'package:digital_munshi/cache/tables/product_table.dart';
import 'package:digital_munshi/cache/tables/sale_table.dart';
import 'package:digital_munshi/models/sale_model.dart';
import 'package:digital_munshi/providers/current_user_provider/current_user_provider.dart';
import 'package:digital_munshi/providers/product_provider/product_provider.dart';
import 'package:digital_munshi/services/sale_service.dart';
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

  /// Full refresh: push pending changes, then download every sale.
  /// Only runs on open / manual refresh; edits just push their own change.
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
        // A cloud sale's stock use is already in the cloud stock figures.
        markSynced: (s) =>
            s.copyWith(isSynced: true, syncedStock: s.stockEffects),
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
    final local = sale.copyWith(
      isSynced: false,
      isDeleted: false,
      updatedAt: DateTime.now(),
    );

    // Saved before the state update so stock figures (which read the
    // cache when sales change) already include this sale.
    await SaleTable.saveSingleSale(local);
    state = AsyncData([local, ...?state.value]);

    syncPending(sale.businessId);
  }

  /// 3. Update Sale (Optimistic)
  Future<void> updateSale(SaleModel updatedSale) async {
    final local = updatedSale.copyWith(
      isSynced: false,
      updatedAt: DateTime.now(),
      syncedStock: await _storedSyncedStock(updatedSale.id),
    );

    await SaleTable.saveSaleKeepingSyncedStock(local);
    state = AsyncData([
      for (final s in state.value ?? <SaleModel>[])
        if (s.id == local.id) local else s,
    ]);

    syncPending(local.businessId);
  }

  /// 4. Delete Sale (Optimistic Soft Delete)
  Future<void> deleteSale(String saleId, String businessId) async {
    final currentSales = state.value ?? [];
    final index = currentSales.indexWhere((s) => s.id == saleId);
    if (index == -1) return;
    final deletedMarker = currentSales[index].copyWith(
      isDeleted: true,
      isSynced: false,
      updatedAt: DateTime.now(),
      syncedStock: await _storedSyncedStock(saleId),
    );

    await SaleTable.saveSaleKeepingSyncedStock(deletedMarker);
    state = AsyncData(currentSales.where((s) => s.id != saleId).toList());

    syncPending(businessId);
  }

  /// The cloud stock use recorded in the cache for [saleId]. The copy held
  /// by a screen may be older than a sync that finished meanwhile, so it
  /// must not overwrite this.
  Future<Map<String, double>> _storedSyncedStock(String saleId) async {
    final rows = await LocalCacheManager.queryAllRows(
      SaleTable.tableName,
      where: 'id = ?',
      whereArgs: [saleId],
    );
    if (rows.isEmpty) return const {};
    return SaleModel.fromJsonDb(rows.first).syncedStock;
  }

  /// 5. Background Sync Engine
  Future<void> syncPending(String businessId) {
    return SyncLock.run('sales_$businessId', () => _syncPending(businessId));
  }

  Future<void> _syncPending(String businessId) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || !await isOnline()) return;

    final unsynced = await SaleTable.getUnsyncedSalesByBusiness(businessId);
    if (unsynced.isEmpty) return;

    // Products first: a product created offline must exist in the cloud
    // before a sale can take stock from it.
    await ref
        .read(productProvider(businessId).notifier)
        .syncPending(businessId);

    final service = SaleService(uid: user.uid);
    var stockChanged = false;

    for (final s in unsynced) {
      try {
        final result = await service.syncSale(s);

        if (!result.applied) {
          // Another device edited this sale more recently: keep its version,
          // unless the user changed the sale again meanwhile.
          final cloud = result.newerCloudSale!;
          if (await LocalCacheManager.markSyncedIfUnchanged(
            SaleTable.tableName,
            s.toJsonDb(),
            ignore: const {'syncedStock'},
          )) {
            await SaleTable.saveSingleSale(
              cloud.copyWith(isSynced: true, syncedStock: cloud.stockEffects),
            );
          }
          continue;
        }

        if (result.cloudStock.isNotEmpty) {
          await ProductTable.setCloudStock(result.cloudStock);
          stockChanged = true;
        }

        if (s.isDeleted) {
          await SaleTable.hardDelete(s.id);
        } else {
          // The cloud now has this sale's stock use, whatever happens next.
          await SaleTable.setSyncedStock(s.id, result.syncedStock);
          await LocalCacheManager.markSyncedIfUnchanged(
            SaleTable.tableName,
            s.toJsonDb(),
            ignore: const {'syncedStock'},
          );
        }
      } catch (e) {
        dev.log("Sale Sync Failed: $e", name: "SaleProvider");
      }
    }

    state = AsyncData(await SaleTable.getBusinessSalesFromCache(businessId));
    if (stockChanged) {
      await ref
          .read(productProvider(businessId).notifier)
          .reloadFromCache(businessId);
    }
  }
}
