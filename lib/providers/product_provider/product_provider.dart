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
  FutureOr<List<ProductModel>> build() async {
    // Resets if user logs out
    final userState = ref.watch(userProvider);
    if (userState.value == null) return [];
    return [];
  }

  /// Load: Fetches ALL products for a business regardless of category
  Future<void> loadProducts(String businessId) async {
    state = const AsyncValue.loading();

    try {
      // 1. Instant Cache Load of the full list
      final cache = await ProductTable.getAllProducts(businessId);
      state = AsyncValue.data(cache);

      final user = ref.read(userProvider).value;
      if (user == null) return;

      // 2. Background Cloud Sync
      final service = ProductService(uid: user.uid);
      final cloud = await service.getBusinessProducts(businessId);

      // 3. Update Cache & State with the full unfiltered list
      await ProductTable.saveAllProducts(cloud);
      state = AsyncValue.data(cloud);

      syncPending(businessId);
    } catch (e, stack) {
      dev.log("Product Load Error: $e", name: "ProductProvider");
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addProduct(ProductModel product) async {
    final local = product.copyWith(isSynced: false, isDeleted: false);
    await ProductTable.saveSingleProduct(local);
    final current = state.value ?? [];
    state = AsyncData([local, ...current]);
    syncPending(product.businessId);
  }

  Future<void> updateProduct(ProductModel updated) async {
    final local = updated.copyWith(isSynced: false);
    final current = state.value ?? [];
    state = AsyncData([
      for (final p in current)
        if (p.id == local.id) local else p,
    ]);
    await ProductTable.saveSingleProduct(local);
    syncPending(local.businessId);
  }

  Future<void> deleteProduct(String productId, String businessId) async {
    final current = state.value ?? [];
    final product = current.firstWhere((p) => p.id == productId);
    final deletedMarker = product.copyWith(isDeleted: true, isSynced: false);
    state = AsyncData(current.where((p) => p.id != productId).toList());
    await ProductTable.saveSingleProduct(deletedMarker);
    syncPending(businessId);
  }

  Future<void> syncPending(String businessId) async {
    final user = ref.read(userProvider).value;
    final connectivity = await Connectivity().checkConnectivity();
    if (user == null || connectivity.contains(ConnectivityResult.none)) return;

    final service = ProductService(uid: user.uid);
    final unsynced = await ProductTable.getUnsyncedProductsByBusiness(
      businessId,
    );

    for (final p in unsynced) {
      try {
        final success = await service.saveProduct(product: p);
        if (success) {
          final synced = p.copyWith(
            isSynced: true,
            lastSyncAttempt: DateTime.now(),
          );
          await ProductTable.saveSingleProduct(synced);
          final current = state.value ?? [];
          state = AsyncData([
            for (final item in current)
              if (item.id == synced.id) synced else item,
          ]);
        }
      } catch (e) {
        dev.log("Product Sync Failed: $e", name: "ProductProvider");
      }
    }
  }
}
