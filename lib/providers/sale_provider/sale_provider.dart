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
  FutureOr<List<SaleModel>> build(String businessId) async {
    // Watches the user to reset state on logout/login
    final userState = ref.watch(userProvider);
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
    final user = ref.read(userProvider).value;
    if (user == null) return;

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        dev.log("Device offline, cloud sync skipped.", name: "SaleProvider");
        return;
      }

      final service = SaleService(uid: user.uid);
      dev.log("Fetching fresh cloud data...", name: "SaleProvider");
      final cloudSales = await service.getBusinessSales(businessId);

      // Persist to local DB
      await SaleTable.saveAllSales(cloudSales);

      // 🔥 UPDATE UI LIVE: If there are changes, they pop up now
      state = AsyncValue.data(cloudSales);
      dev.log("UI updated with fresh cloud data", name: "SaleProvider");

      // Push any local changes that were made while offline
      syncPending(businessId);
    } catch (e) {
      dev.log("Silent Cloud Sync Failed: $e", name: "SaleProvider");
      // We don't update 'state' with an error here because the user
      // is already looking at perfectly fine cache data.
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
    final sale = currentSales.firstWhere((s) => s.id == saleId);
    final deletedMarker = sale.copyWith(isDeleted: true, isSynced: false);

    // Remove from UI immediately
    state = AsyncData(currentSales.where((s) => s.id != saleId).toList());

    await SaleTable.saveSingleSale(deletedMarker);
    _performSilentCloudSync(businessId);
  }

  /// 5. Background Sync Engine
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

            // Update UI with the new sync status (shows the cloud icon)
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
