import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/tables/product_table.dart';
import 'package:sprint_14/models/product_model.dart';
import 'package:sprint_14/providers/user_provider/user_provider.dart';
import 'package:sprint_14/services/product_service.dart';
import 'dart:developer' as dev;

part 'product_provider.g.dart';

@Riverpod(keepAlive: true)
class ProductNotifier extends _$ProductNotifier {
  @override
  FutureOr<List<ProductModel>> build(String businessId) async {
    // 1. Watch user state to clear data on logout
    final userState = ref.watch(userProvider);
    if (userState.value == null) return [];

    // 2. Phase 1: Instant Cache Load (Source of Truth for Offline)
    final cache = await ProductTable.getAllProducts(businessId);
    dev.log(cache[0].title, name: "Cache First Product");

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

  /// Internal helper to sync cloud data without interrupting the user
  Future<void> _performSilentCloudSync(String businessId) async {
    final user = ref.read(userProvider).value;
    if (user == null) return;

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        dev.log(
          "Device offline, skipping product cloud sync.",
          name: "ProductProvider",
        );
        return;
      }

      final service = ProductService(uid: user.uid);
      dev.log("Fetching fresh products from Cloud...", name: "ProductProvider");
      final cloudProducts = await service.getBusinessProducts(businessId);

      // Save new cloud data to local SQLite
      await ProductTable.saveAllProducts(cloudProducts);

      // Update UI live if cloud data is different
      state = AsyncValue.data(cloudProducts);

      // Push any pending local changes (Syncing local to cloud)
      syncPending(businessId);
    } catch (e) {
      dev.log(
        "Silent Product Sync Failed (Normal if offline): $e",
        name: "ProductProvider",
      );
    }
  }

  /// 2. Add Product (Optimistic UI)
  Future<void> addProduct(ProductModel product) async {
    final local = product.copyWith(isSynced: false, isDeleted: false);

    final current = state.value ?? [];
    state = AsyncData([local, ...current]);

    await ProductTable.saveSingleProduct(local);
    _performSilentCloudSync(product.businessId);
  }

  /// 3. Update Product (Optimistic UI)
  Future<void> updateProduct(ProductModel product) async {
    final local = product.copyWith(isSynced: false);

    final current = state.value ?? [];
    state = AsyncData([
      for (final p in current)
        if (p.id == local.id) local else p,
    ]);

    await ProductTable.saveSingleProduct(local);

    await syncPending(local.businessId);

    _performSilentCloudSync(local.businessId);
  }

  /// 4. Delete Product (Optimistic Soft Delete)
  Future<void> deleteProduct(String productId, String businessId) async {
    final current = state.value ?? [];
    final product = current.firstWhere((p) => p.id == productId);
    final deletedMarker = product.copyWith(isDeleted: true, isSynced: false);

    // Remove from UI immediately
    state = AsyncData(current.where((p) => p.id != productId).toList());

    await ProductTable.saveSingleProduct(deletedMarker);
    _performSilentCloudSync(businessId);
  }

  /// 5. Push Local Changes to Cloud
  Future<void> syncPending(String businessId) async {
    final user = ref.read(userProvider).value;
    final connectivity = await Connectivity().checkConnectivity();

    if (user == null || connectivity.contains(ConnectivityResult.none)) return;

    final service = ProductService(uid: user.uid);
    // You should implement getUnsyncedProducts in your ProductTable
    final unsynced = await ProductTable.getUnsyncedProductsByBusiness(
      businessId,
    );

    for (final p in unsynced) {
      try {
        bool success = false;
        if (p.isDeleted) {
          success = await service.deleteProduct(
            businessId: p.businessId,
            productId: p.id,
          );
          if (success) await ProductTable.hardDelete(p.id);
        } else {
          success = await service.saveProduct(product: p);
          if (success) {
            final synced = p.copyWith(isSynced: true);
            await ProductTable.saveSingleProduct(synced);

            // Update UI sync status
            final current = state.value ?? [];
            state = AsyncData([
              for (final item in current)
                if (item.id == synced.id) synced else item,
            ]);
          }
        }
      } catch (e) {
        dev.log("Product Sync Failed: $e", name: "ProductProvider");
      }
    }
  }
}
