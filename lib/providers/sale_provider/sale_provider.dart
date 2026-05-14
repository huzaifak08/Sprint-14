import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) return;

      final service = SaleService(uid: user.uid);

      // 1. 🔥 PUSH LOCAL CHANGES FIRST
      // This ensures that when we fetch cloud data next, our new sale is likely already there.
      await syncPending(businessId);

      // 2. Fetch fresh cloud data
      dev.log("Fetching fresh cloud data...", name: "SaleProvider");
      final cloudSales = await service.getBusinessSales(businessId);

      // 3. Persist to local DB
      await SaleTable.saveAllSales(cloudSales);

      // 4. 🔥 SMART MERGE: Check for local sales that are still 'isSynced = false'
      // This handles the case where syncPending is still running or failed.
      final unsynced = await SaleTable.getUnsyncedSalesByBusiness(businessId);

      if (unsynced.isEmpty) {
        state = AsyncValue.data(cloudSales);
      } else {
        dev.log(
          "Merging ${unsynced.length} unsynced sales into UI",
          name: "SaleProvider",
        );

        // Create a map of cloud sales for quick lookup
        final merged = [...cloudSales];

        for (var local in unsynced) {
          final index = merged.indexWhere((s) => s.id == local.id);
          if (index != -1) {
            // If it exists in both, prefer the local version (it has the correct sync status)
            merged[index] = local;
          } else if (!local.isDeleted) {
            // If it's a brand new local sale not yet on the cloud, insert it at the top
            merged.insert(0, local);
          }
        }

        // Sort the final list by date to ensure the UI stays ordered
        merged.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        state = AsyncValue.data(merged);
      }

      dev.log("UI updated with Smart Merge data", name: "SaleProvider");
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
    final sale = currentSales.firstWhere((s) => s.id == saleId);
    final deletedMarker = sale.copyWith(isDeleted: true, isSynced: false);

    // Remove from UI immediately
    state = AsyncData(currentSales.where((s) => s.id != saleId).toList());

    await SaleTable.saveSingleSale(deletedMarker);
    _performSilentCloudSync(businessId);
  }

  /// 5. Background Sync Engine
  Future<void> syncPending(String businessId) async {
    final user = ref.read(currentUserProvider).value;
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
