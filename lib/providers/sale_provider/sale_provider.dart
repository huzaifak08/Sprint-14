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
  String? get _currentUid => ref.read(userProvider).value?.uid;

  @override
  List<SaleModel> build() => [];

  /// 1. Load: Fetch all sales for the specific shop
  Future<void> loadSales(String businessId) async {
    final cache = await SaleTable.getBusinessSalesFromCache(businessId);
    state = cache;

    final uid = _currentUid;
    if (uid == null) return;

    try {
      final service = SaleService(uid: uid);
      final cloud = await service.getBusinessSales(businessId);

      // Persist cloud data to local cache
      // You may need to implement saveAllFetchedSales in SaleTable
      state = cloud;
      syncPending(businessId);
    } catch (e) {
      dev.log("Sale Load Error: $e");
    }
  }

  /// 2. Record Sale (Blast Off)
  Future<void> recordSale(SaleModel sale) async {
    final local = sale.copyWith(isSynced: false, isDeleted: false);

    // Optimistic UI update: Insert at the top of the list
    state = [local, ...state];

    await SaleTable.saveSingleSale(local);
    syncPending(sale.businessId);
  }

  /// 3. Delete Sale (Voiding a transaction)
  Future<void> deleteSale(String saleId, String businessId) async {
    final sale = state.firstWhere((s) => s.id == saleId);
    final deletedMarker = sale.copyWith(isDeleted: true, isSynced: false);

    state = state.where((s) => s.id != saleId).toList();
    await SaleTable.saveSingleSale(deletedMarker);
    syncPending(businessId);
  }

  /// 4. Background Sync
  Future<void> syncPending(String businessId) async {
    final uid = _currentUid;
    final connectivity = await Connectivity().checkConnectivity();
    if (uid == null || connectivity.contains(ConnectivityResult.none)) return;

    final service = SaleService(uid: uid);
    final unsynced =
        await SaleTable.getUnsyncedSales(); // Filter by businessId in Table logic

    for (final s in unsynced) {
      try {
        if (s.isDeleted) {
          // You may need to add deleteSaleData to SaleService
          await SaleTable.hardDelete(s.id);
        } else {
          final success = await service.recordSale(sale: s);
          if (success) {
            final synced = s.copyWith(
              isSynced: true,
              lastSyncAttempt: DateTime.now(),
            );
            await SaleTable.saveSingleSale(synced);
            state = [
              for (final item in state)
                if (item.id == synced.id) synced else item,
            ];
          }
        }
      } catch (e) {
        dev.log("Sale Sync Failed: $e");
      }
    }
  }
}
