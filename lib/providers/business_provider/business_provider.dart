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
  String? get _currentUid => ref.read(userProvider).value?.uid;

  @override
  List<BusinessModel> build() {
    final userState = ref.watch(userProvider);

    userState.whenData((user) {
      if (user != null) {
        _loadBusinesses(user.uid);
      } else {
        state = [];
      }
    });

    return [];
  }

  /// 1. Load: Cache -> Cloud -> Merge
  Future<void> _loadBusinesses(String uid) async {
    final cache = await BusinessTable.getAllBusinessesFromCache();
    if (cache.isNotEmpty) state = cache;

    try {
      final service = BusinessService(uid: uid);
      final cloud = await service.getAllBusinesses();

      if (cloud.isEmpty && cache.isEmpty) return;

      final Map<String, BusinessModel> cacheMap = {
        for (final b in cache) b.id: b,
      };
      final List<BusinessModel> merged = [];

      for (final c in cloud) {
        final local = cacheMap[c.id];
        if (local != null && !local.isSynced) {
          merged.add(local);
        } else {
          merged.add(c.copyWith(isSynced: true));
        }
      }

      await BusinessTable.saveAllFetchedBusinesses(merged);
      state = merged;
      syncPending();
    } catch (e) {
      dev.log("Business Load Error: $e");
    }
  }

  /// 2. Add Business
  Future<void> addBusiness(BusinessModel business) async {
    final local = business.copyWith(isSynced: false, isDeleted: false);
    await BusinessTable.saveSingleBusiness(local);
    state = [local, ...state];
    syncPending();
  }

  /// 3. Update Business
  Future<void> updateBusiness(BusinessModel updated) async {
    final local = updated.copyWith(isSynced: false);
    state = [
      for (final b in state)
        if (b.id == local.id) local else b,
    ];
    await BusinessTable.saveSingleBusiness(local);
    syncPending();
  }

  /// 4. Delete Business (Soft Delete)
  Future<void> deleteBusiness(String id) async {
    final business = state.firstWhere((b) => b.id == id);
    final deletedMarker = business.copyWith(isDeleted: true, isSynced: false);

    state = state.where((b) => b.id != id).toList();
    await BusinessTable.saveSingleBusiness(deletedMarker);
    syncPending();
  }

  /// 5. Background Sync
  Future<void> syncPending() async {
    final uid = _currentUid;
    if (uid == null) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;

    final service = BusinessService(uid: uid);
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
            state = [
              for (final item in state)
                if (item.id == synced.id) synced else item,
            ];
          }
        }
      } catch (e) {
        dev.log("Business Sync Failed: $e");
      }
    }
  }
}
