import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:digital_munshi/cache/init_cache.dart';
import 'package:digital_munshi/cache/sync/sync_merge.dart';
import 'package:digital_munshi/cache/sync/sync_utils.dart';
import 'package:digital_munshi/cache/tables/product_table.dart';
import 'package:digital_munshi/helpers/app_data.dart';
import 'package:digital_munshi/models/product_model.dart';
import 'package:digital_munshi/providers/current_user_provider/current_user_provider.dart';
import 'package:digital_munshi/services/product_service.dart';
import 'dart:developer' as dev;

part 'product_provider.g.dart';

@Riverpod(keepAlive: true)
class ProductNotifier extends _$ProductNotifier {
  @override
  FutureOr<List<ProductModel>> build(String businessId) async {
    // 1. Watch user state to clear data on logout
    final userState = ref.watch(currentUserProvider);
    if (userState.value == null) return [];

    // 2. Phase 1: Instant Cache Load (Source of Truth for Offline)
    final cache = await ProductTable.getAllProducts(businessId);

    // 3. Phase 2: Fire and forget the cloud sync
    _performSilentCloudSync(businessId);

    return cache;
  }

  /// Refreshes data manually if needed (e.g., Pull-to-refresh)
  Future<void> loadProducts(String businessId) async {
    try {
      final cache = await ProductTable.getAllProducts(businessId);
      state = AsyncValue.data(cache);
    } catch (e, stack) {
      dev.log("Product Cache Load Error", error: e, name: "ProductProvider");
      state = AsyncValue.error(e, stack);
      return;
    }

    _performSilentCloudSync(businessId);
  }

  /// Re-reads products from the cache (e.g. after a sale moved stock).
  Future<void> reloadFromCache(String businessId) async {
    state = AsyncData(await ProductTable.getAllProducts(businessId));
  }

  /// Full refresh: push pending changes, then download every product.
  /// Only runs on open / manual refresh; edits just push their own change.
  Future<void> _performSilentCloudSync(String businessId) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      if (!await isOnline()) return;

      // 1. Push local changes first so the fetch already contains them.
      await syncPending(businessId);

      // 2. Fetch fresh products from Cloud
      final cloudProducts = await ProductService(
        uid: user.uid,
      ).getBusinessProducts(businessId);

      // 3. Merge so the cloud copy never overwrites un-uploaded local edits.
      final localRows = await LocalCacheManager.queryAllRows(
        ProductTable.tableName,
        where: 'businessId = ?',
        whereArgs: [businessId],
      );
      final local = localRows.map(ProductModel.fromJsonDb).toList();

      final result = mergeCloudWithLocal<ProductModel>(
        cloud: cloudProducts,
        local: local,
        idOf: (p) => p.id,
        isSynced: (p) => p.isSynced,
        isDeleted: (p) => p.isDeleted,
        markSynced: (p) => p.copyWith(isSynced: true),
      );

      await ProductTable.saveAllProducts(result.toSave);
      await LocalCacheManager.deleteByIds(
        ProductTable.tableName,
        result.toRemove,
      );

      // Local rows with pending edits keep their details, but their stock
      // mirror must still follow the cloud (other devices' sales).
      final pendingIds = {
        for (final p in local)
          if (!p.isSynced) p.id,
      };
      await ProductTable.setCloudStock({
        for (final c in cloudProducts)
          if (pendingIds.contains(c.id)) c.id: c.currentStock,
      });

      state = AsyncValue.data(await ProductTable.getAllProducts(businessId));
    } catch (e) {
      dev.log("Silent Product Sync Failed: $e", name: "ProductProvider");
    }
  }

  /// 2. Add Product (Optimistic UI)
  /// [initialStock] is uploaded as a stock adjustment, added to the cloud
  /// figure (which starts at 0).
  Future<void> addProduct(ProductModel product, {double initialStock = 0}) async {
    final hasStock = product.tracksStock && initialStock != 0;
    final local = product.copyWith(
      currentStock: 0,
      pendingStockDelta: hasStock ? initialStock : 0,
      stockAdjustmentId: hasStock ? AppData.shared.uuid.v4() : null,
      clearStockAdjustment: !hasStock,
      isSynced: false,
      isDeleted: false,
      updatedAt: DateTime.now(),
    );

    await ProductTable.saveSingleProduct(local);
    state = AsyncData([local, ...?state.value]);

    syncPending(product.businessId);
  }

  /// 3. Update Product (Optimistic UI)
  /// Saves the product's details. A stock change (restock or correction)
  /// is passed as [stockDelta] units and added to the cloud figure, so it
  /// can't overwrite stock moved by sales on other devices.
  Future<void> updateProduct(ProductModel product, {double stockDelta = 0}) async {
    final local = product.copyWith(isSynced: false, updatedAt: DateTime.now());

    await ProductTable.saveProductKeepingStock(local);
    if (stockDelta.abs() > 1e-9) {
      await ProductTable.addStockAdjustment(
        productId: local.id,
        delta: stockDelta,
        adjustmentId: AppData.shared.uuid.v4(),
      );
    }
    state = AsyncData(await ProductTable.getAllProducts(local.businessId));

    syncPending(local.businessId);
  }

  /// 4. Delete Product (Optimistic Soft Delete)
  Future<void> deleteProduct(String productId, String businessId) async {
    final current = state.value ?? [];
    final index = current.indexWhere((p) => p.id == productId);
    if (index == -1) return;
    final deletedMarker = current[index].copyWith(
      isDeleted: true,
      isSynced: false,
      updatedAt: DateTime.now(),
    );

    await ProductTable.saveProductKeepingStock(deletedMarker);
    state = AsyncData(current.where((p) => p.id != productId).toList());

    syncPending(businessId);
  }

  /// 5. Push Local Changes to Cloud
  Future<void> syncPending(String businessId) {
    return SyncLock.run('products_$businessId', () => _syncPending(businessId));
  }

  Future<void> _syncPending(String businessId) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || !await isOnline()) return;

    final service = ProductService(uid: user.uid);
    final unsynced = await ProductTable.getUnsyncedProductsByBusiness(
      businessId,
    );
    if (unsynced.isEmpty) return;

    for (final p in unsynced) {
      try {
        if (p.isDeleted) {
          final success = await service.deleteProduct(
            businessId: p.businessId,
            productId: p.id,
          );
          if (success) await ProductTable.hardDelete(p.id);
          continue;
        }

        final result = await service.syncProduct(p);
        await ProductTable.setCloudStock({p.id: result.cloudStock});
        if (result.adjustmentSettled) {
          await ProductTable.settleStockAdjustment(
            productId: p.id,
            adjustmentId: p.stockAdjustmentId!,
            uploadedDelta: p.pendingStockDelta,
          );
        }

        // Re-read: the user may have edited the product during the upload,
        // in which case it stays pending and the newer edit goes next pass.
        final row = await ProductTable.getById(p.id);
        if (row == null || row.isDeleted || !_sameDetails(row, p)) continue;
        final noPendingStock = row.pendingStockDelta.abs() < 1e-9;

        if (!result.fieldsApplied) {
          // Another device edited the details more recently: keep theirs.
          final cloud = result.newerCloudProduct!;
          await ProductTable.saveProductKeepingStock(
            row.copyWith(
              title: cloud.title,
              isTheya: cloud.isTheya,
              classification: cloud.classification,
              retailPrice: cloud.retailPrice,
              msrpPrice: cloud.msrpPrice,
              unitType: cloud.unitType,
              updatedAt: cloud.updatedAt,
              isSynced: noPendingStock,
              lastSyncAttempt: DateTime.now(),
            ),
          );
        } else if (noPendingStock) {
          await ProductTable.saveProductKeepingStock(
            row.copyWith(isSynced: true, lastSyncAttempt: DateTime.now()),
          );
        }
      } catch (e) {
        dev.log("Product Sync Failed: $e", name: "ProductProvider");
      }
    }

    state = AsyncData(await ProductTable.getAllProducts(businessId));
  }

  static bool _sameDetails(ProductModel a, ProductModel b) {
    return a.title == b.title &&
        a.isTheya == b.isTheya &&
        a.classification == b.classification &&
        a.retailPrice == b.retailPrice &&
        a.msrpPrice == b.msrpPrice &&
        a.unitType == b.unitType &&
        a.updatedAt == b.updatedAt;
  }
}
