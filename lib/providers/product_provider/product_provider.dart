import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/tables/product_table.dart';
import 'package:sprint_14/models/product_model.dart';
import 'package:sprint_14/providers/user_provider/user_provider.dart'; // Using UserProvider for consistency
import 'package:sprint_14/services/product_service.dart';
import 'dart:developer' as dev;

part 'product_provider.g.dart';

@Riverpod(keepAlive: true)
class ProductNotifier extends _$ProductNotifier {
  @override
  FutureOr<List<ProductModel>> build() async {
    // 🔥 Linking to UserProvider: If user logs out/in, this resets.
    final userState = ref.watch(userProvider);
    final user = userState.value;

    if (user == null) {
      return [];
    }

    // By default, we return an empty list until a specific business context is provided via loadProducts
    return [];
  }

  /// 1. Load: Based on Business ID and Theya status
  /// Call this in your View's build or initState
  Future<void> loadProducts(String businessId, bool isTheya) async {
    // Start with a loading state for a smooth UI transition
    state = const AsyncValue.loading();

    try {
      // 1. Instant Cache Load
      final cache = await ProductTable.getProductsByBusiness(
        businessId,
        isTheya,
      );
      state = AsyncValue.data(cache);

      final user = ref.read(userProvider).value;
      if (user == null) return;

      // 2. Background Cloud Sync
      final service = ProductService(uid: user.uid);
      final cloud = await service.getBusinessProducts(businessId);

      // 3. Update Cache and local state
      await ProductTable.saveAllProducts(cloud);

      // Filter for the specific view (Theya vs Inside)
      final filtered = cloud.where((p) => p.isTheya == isTheya).toList();
      state = AsyncValue.data(filtered);

      syncPending(businessId);
    } catch (e, stack) {
      dev.log("Product Load Error: $e", name: "ProductProvider");
      state = AsyncValue.error(e, stack);
    }
  }

  /// 2. Add Product
  Future<void> addProduct(ProductModel product) async {
    final local = product.copyWith(isSynced: false, isDeleted: false);
    await ProductTable.saveSingleProduct(local);

    // Update local state if it's currently showing data
    final currentProducts = state.value ?? [];
    state = AsyncData([local, ...currentProducts]);

    syncPending(product.businessId);
  }

  /// 3. Update Product
  Future<void> updateProduct(ProductModel updated) async {
    final local = updated.copyWith(isSynced: false);
    final currentProducts = state.value ?? [];

    state = AsyncData([
      for (final p in currentProducts)
        if (p.id == local.id) local else p,
    ]);

    await ProductTable.saveSingleProduct(local);
    syncPending(local.businessId);
  }

  /// 4. Delete Product (Soft Delete)
  Future<void> deleteProduct(String productId, String businessId) async {
    final currentProducts = state.value ?? [];
    final product = currentProducts.firstWhere((p) => p.id == productId);
    final deletedMarker = product.copyWith(isDeleted: true, isSynced: false);

    state = AsyncData(currentProducts.where((p) => p.id != productId).toList());

    await ProductTable.saveSingleProduct(deletedMarker);
    syncPending(businessId);
  }

  /// 5. Background Sync
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

          // Refresh state to show "Synced" status icons if applicable
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
