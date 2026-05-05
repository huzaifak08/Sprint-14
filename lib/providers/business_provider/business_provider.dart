import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/tables/business_table.dart';
import 'package:sprint_14/models/business_model.dart';
import 'package:sprint_14/providers/user_provider/user_provider.dart';
import 'package:sprint_14/services/business_service.dart';
import 'dart:developer' as dev;

part 'business_provider.g.dart';

@Riverpod(keepAlive: true)
class BusinessNotifier extends _$BusinessNotifier {
  @override
  Future<List<BusinessModel>> build() async {
    // 🔥 Watch the user state. If user changes, build() re-runs.
    final userState = ref.watch(userProvider);
    final user = userState.value;

    if (user == null) {
      dev.log(
        "No user found in BusinessNotifier, returning empty list",
        name: "BusinessProvider",
      );
      return [];
    }

    // Load initial data from local cache immediately for fast UI response
    final cache = await BusinessTable.getAllBusinessesFromCache();

    // Trigger background sync/cloud fetch without blocking the UI return
    _fetchAndSyncFromCloud(user.uid);

    return cache;
  }

  /// 1. Cloud Fetch & Merge (Silent background update)
  Future<void> _fetchAndSyncFromCloud(String uid) async {
    try {
      final service = BusinessService(uid: uid);
      final cloud = await service.getAllBusinesses();
      final currentList = state.value ?? [];

      if (cloud.isEmpty && currentList.isEmpty) return;

      final Map<String, BusinessModel> currentMap = {
        for (final b in currentList) b.id: b,
      };

      final List<BusinessModel> merged = [];
      for (final c in cloud) {
        final local = currentMap[c.id];
        // If local exists and is not synced, keep local. Otherwise take cloud version.
        if (local != null && !local.isSynced) {
          merged.add(local);
        } else {
          merged.add(c.copyWith(isSynced: true));
        }
      }

      await BusinessTable.saveAllFetchedBusinesses(merged);
      state = AsyncData(merged);
      syncPending();
    } catch (e) {
      dev.log("Cloud Fetch Error: $e", name: "BusinessProvider");
    }
  }

  /// 2. Add Business
  Future<void> addBusiness(BusinessModel business) async {
    final local = business.copyWith(isSynced: false, isDeleted: false);
    await BusinessTable.saveSingleBusiness(local);

    final current = state.value ?? [];
    state = AsyncData([local, ...current]);
    syncPending();
  }

  /// 3. Update Business
  Future<void> updateBusiness(BusinessModel updated) async {
    final local = updated.copyWith(isSynced: false);
    final current = state.value ?? [];

    state = AsyncData([
      for (final b in current)
        if (b.id == local.id) local else b,
    ]);

    await BusinessTable.saveSingleBusiness(local);
    syncPending();
  }

  /// 4. Delete Business (Soft Delete)
  Future<void> deleteBusiness(String id) async {
    final current = state.value ?? [];
    final business = current.firstWhere((b) => b.id == id);
    final deletedMarker = business.copyWith(isDeleted: true, isSynced: false);

    state = AsyncData(current.where((b) => b.id != id).toList());
    await BusinessTable.saveSingleBusiness(deletedMarker);
    syncPending();
  }

  /// 5. Manual Sync Trigger (Useful for Splash)
  Future<List<BusinessModel>> forceRefresh() async {
    final user = ref.read(userProvider).value;
    if (user == null) return [];

    final businesses = await BusinessTable.getAllBusinessesFromCache();
    state = AsyncData(businesses);
    return businesses;
  }

  /// 6. Background Sync Logic
  Future<void> syncPending() async {
    final user = ref.read(userProvider).value;
    if (user == null) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;

    final service = BusinessService(uid: user.uid);
    final unsynced = await BusinessTable.getUnsyncedBusinesses();

    for (final b in unsynced) {
      try {
        if (b.isDeleted) {
          final success = await service.deleteBusinessData(businessId: b.id);
          if (success) await BusinessTable.hardDelete(b.id);
        } else {
          final success = await service.saveBusiness(business: b);
          if (success) {
            final synced = b.copyWith(
              isSynced: true,
              lastSyncAttempt: DateTime.now(),
            );
            await BusinessTable.saveSingleBusiness(synced);

            final current = state.value ?? [];
            state = AsyncData([
              for (final item in current)
                if (item.id == synced.id) synced else item,
            ]);
          }
        }
      } catch (e) {
        dev.log("Sync Failed for ${b.id}: $e", name: "BusinessProvider");
      }
    }
  }
}
