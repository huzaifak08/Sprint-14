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
  String? get _currentUid => ref.read(userProvider).value?.uid;

  @override
  List<ProductModel> build() => [];

  /// 1. Load: Based on Business ID and Theya status
  Future<void> loadProducts(String businessId, bool isTheya) async {
    final cache = await ProductTable.getProductsByBusiness(businessId, isTheya);
    state = cache;

    final uid = _currentUid;
    if (uid == null) return;

    try {
      final service = ProductService(uid: uid);
      final cloud = await service.getBusinessProducts(businessId);

      await ProductTable.saveAllProducts(cloud);
      state = cloud.where((p) => p.isTheya == isTheya).toList();
      syncPending(businessId);
    } catch (e) {
      dev.log("Product Load Error: $e");
    }
  }

  /// 2. Add Product
  Future<void> addProduct(ProductModel product) async {
    final local = product.copyWith(isSynced: false, isDeleted: false);
    await ProductTable.saveSingleProduct(local);
    state = [local, ...state];
    syncPending(product.businessId);
  }

  /// 3. Update Product
  Future<void> updateProduct(ProductModel updated) async {
    final local = updated.copyWith(isSynced: false);
    state = [
      for (final p in state)
        if (p.id == local.id) local else p,
    ];
    await ProductTable.saveSingleProduct(local);
    syncPending(local.businessId);
  }

  /// 4. Delete Product (Soft Delete)
  Future<void> deleteProduct(String productId, String businessId) async {
    final product = state.firstWhere((p) => p.id == productId);
    final deletedMarker = product.copyWith(isDeleted: true, isSynced: false);

    state = state.where((p) => p.id != productId).toList();
    await ProductTable.saveSingleProduct(deletedMarker);
    syncPending(businessId);
  }

  /// 5. Background Sync
  Future<void> syncPending(String businessId) async {
    final uid = _currentUid;
    final connectivity = await Connectivity().checkConnectivity();
    if (uid == null || connectivity.contains(ConnectivityResult.none)) return;

    final service = ProductService(uid: uid);
    final unsynced = await ProductTable.getUnsyncedProductsByBusiness(
      businessId,
    ); // Needs implementation in Table

    for (final p in unsynced) {
      try {
        final success = await service.saveProduct(product: p);
        if (success) {
          final synced = p.copyWith(
            isSynced: true,
            lastSyncAttempt: DateTime.now(),
          );
          await ProductTable.saveSingleProduct(synced);
          // Only update state if the product belongs to the current view's Theya status
          state = [
            for (final item in state)
              if (item.id == synced.id) synced else item,
          ];
        }
      } catch (e) {
        dev.log("Product Sync Failed: $e");
      }
    }
  }
}
