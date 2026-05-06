import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/tables/sale_table.dart';
import 'package:sprint_14/models/sale_model.dart';
import 'package:sprint_14/providers/user_provider/user_provider.dart';
import 'package:sprint_14/services/sale_service.dart';
import 'dart:developer' as dev;

part 'sale_provider.g.dart';

@Riverpod(keepAlive: true)
class SaleNotifier extends _$SaleNotifier {
  @override
  FutureOr<List<SaleModel>> build() async {
    // Watches the user to reset state on logout/login
    final userState = ref.watch(userProvider);
    if (userState.value == null) return [];
    return [];
  }

  /// 1. Load Sales (Cache First, Cloud Sync Background)
  Future<void> loadSales(String businessId) async {
    state = const AsyncValue.loading();
    try {
      // Instant Cache Load
      final cache = await SaleTable.getBusinessSalesFromCache(businessId);
      state = AsyncValue.data(cache);

      final user = ref.read(userProvider).value;
      if (user == null) return;

      // Background Cloud Fetch
      final service = SaleService(uid: user.uid);
      final cloud = await service.getBusinessSales(businessId);

      // Save to cache and update state
      // Implement saveAllFetchedSales in your SaleTable to handle bulk inserts
      await SaleTable.saveAllSales(cloud);
      state = AsyncValue.data(cloud);

      syncPending(businessId);
    } catch (e, stack) {
      dev.log("Sale Load Error: $e", name: "SaleProvider");
      state = AsyncValue.error(e, stack);
    }
  }

  /// 2. Record Sale
  Future<void> recordSale(SaleModel sale) async {
    final local = sale.copyWith(isSynced: false, isDeleted: false);

    // Update State Optimistically
    final currentSales = state.value ?? [];
    state = AsyncData([local, ...currentSales]);

    await SaleTable.saveSingleSale(local);
    syncPending(sale.businessId);
  }

  /// 3. Update Sale (New)
  Future<void> updateSale(SaleModel updatedSale) async {
    final local = updatedSale.copyWith(isSynced: false);

    final currentSales = state.value ?? [];
    state = AsyncData([
      for (final s in currentSales)
        if (s.id == local.id) local else s,
    ]);

    await SaleTable.saveSingleSale(local);
    syncPending(local.businessId);
  }

  /// 4. Delete Sale (Soft Delete)
  Future<void> deleteSale(String saleId, String businessId) async {
    final currentSales = state.value ?? [];
    final sale = currentSales.firstWhere((s) => s.id == saleId);
    final deletedMarker = sale.copyWith(isDeleted: true, isSynced: false);

    // Remove from UI immediately
    state = AsyncData(currentSales.where((s) => s.id != saleId).toList());

    await SaleTable.saveSingleSale(deletedMarker);
    syncPending(businessId);
  }

  /// 5. Background Sync
  Future<void> syncPending(String businessId) async {
    final user = ref.read(userProvider).value;
    final connectivity = await Connectivity().checkConnectivity();

    if (user == null || connectivity.contains(ConnectivityResult.none)) return;

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
          if (success) {
            final synced = s.copyWith(
              isSynced: true,
              lastSyncAttempt: DateTime.now(),
            );
            await SaleTable.saveSingleSale(synced);

            // Optional: Update state to show sync indicator in UI
            final current = state.value ?? [];
            state = AsyncData([
              for (final item in current)
                if (item.id == synced.id) synced else item,
            ]);
          }
        }
      } catch (e) {
        dev.log("Sale Sync Failed: $e", name: "SaleProvider");
      }
    }
  }
}
