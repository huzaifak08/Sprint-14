import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/tables/business_table.dart';
import 'package:sprint_14/models/business_model.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/providers/current_user_provider/current_user_provider.dart';
import 'package:sprint_14/providers/participant_provider/participant_provider.dart';
import 'package:sprint_14/services/business_service.dart';
import 'dart:developer' as dev;

import 'package:sprint_14/services/storage_service.dart';

part 'business_provider.g.dart';

@Riverpod(keepAlive: true)
class BusinessNotifier extends _$BusinessNotifier {
  @override
  Future<List<BusinessModel>> build() async {
    // Watch user state to auto-refresh on logout/login
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return [];

    // 1. Load from Local Cache immediately
    final cache = await BusinessTable.getAllBusinessesFromCache();

    // 2. Silent background sync
    _fetchAndSyncFromCloud(user.uid);

    return cache;
  }

  /// --- CLOUD LOAD PARTIALLY SCOPED MAPS & MERGE ---
  Future<void> _fetchAndSyncFromCloud(String uid) async {
    try {
      final service = BusinessService(uid: uid);

      // 🔥 STEP A: Ask the service for the business IDs this user belongs to
      final List<String> targetedBusinessIds = await service
          .getParticipantBusinessIds();

      if (targetedBusinessIds.isEmpty) {
        dev.log(
          "No active workspace links found for user: $uid",
          name: "BusinessProvider",
        );
        await BusinessTable.deleteAllBusinesses();
        state = const AsyncData([]);
        return;
      }

      // 🔥 STEP B: Fetch the actual business profiles matching those IDs
      final cloud = await service.getBusinessesByIds(targetedBusinessIds);

      final currentList = state.value ?? [];
      final Map<String, BusinessModel> currentMap = {
        for (final b in currentList) b.id: b,
      };

      final List<BusinessModel> merged = [];

      for (final c in cloud) {
        final local = currentMap[c.id];
        if (local != null && !local.isSynced) {
          merged.add(local);
        } else {
          merged.add(c.copyWith(isSynced: true));
        }
      }

      // 3. Update SQLite and Riverpod state
      await BusinessTable.saveAllFetchedBusinesses(merged);
      state = AsyncData(merged);

      // 4. Fire upstream data sync for pending local changes
      syncPending();
    } catch (e) {
      dev.log(
        "Cloud Participant Workspace Fetch Error: $e",
        name: "BusinessProvider",
      );
    }
  }

  /// --- ADD BUSINESS ---
  Future<void> addBusiness(BusinessModel business) async {
    final local = business.copyWith(isSynced: false, isDeleted: false);

    // Optimistic UI update
    final current = state.value ?? [];
    state = AsyncData([local, ...current]);

    await BusinessTable.saveSingleBusiness(local);
    syncPending();
  }

  /// --- UPDATE BUSINESS ---
  Future<void> updateBusiness(BusinessModel updated) async {
    final local = updated.copyWith(isSynced: false);

    state = AsyncData([
      for (final b in state.value ?? [])
        if (b.id == local.id) local else b,
    ]);

    await BusinessTable.saveSingleBusiness(local);
    syncPending();
  }

  /// --- DELETE BUSINESS (Soft) ---
  Future<void> deleteBusiness(String id) async {
    final current = state.value ?? [];
    final business = current.firstWhere((b) => b.id == id);
    final deletedMarker = business.copyWith(isDeleted: true, isSynced: false);

    // Remove from UI immediately
    state = AsyncData(current.where((b) => b.id != id).toList());

    await BusinessTable.saveSingleBusiness(deletedMarker);
    syncPending();
  }

  /// --- FULL SYNC LOGIC (Storage + Firestore) ---
  Future<void> syncPending() async {
    final authUser = ref.read(authControllerProvider).value;
    if (authUser == null) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;

    final service = BusinessService(uid: authUser.uid);
    final unsynced = await BusinessTable.getUnsyncedBusinesses();

    for (final b in unsynced) {
      try {
        // --- HANDLE DELETION ---
        if (b.isDeleted) {
          // 1. Delete Logo from Storage using the correct path
          await StorageService().deleteBusinessLogo(b.id);

          // 2. Delete Data from Firestore
          final success = await service.deleteBusinessData(businessId: b.id);

          // 3. Remove from Local Cache
          if (success) await BusinessTable.hardDelete(b.id);
          continue;
        }

        // --- HANDLE UPLOAD/SAVE ---
        String? finalLogoUrl = b.logoPath;

        if (b.logoPath != null && !b.logoPath!.startsWith('http')) {
          final file = File(b.logoPath!);
          if (await file.exists()) {
            // 🔥 UPLOAD PATH: businesses/{id}/logo.jpg
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('businesses')
                .child(b.id)
                .child('logo.jpg');

            await storageRef.putFile(file);
            finalLogoUrl = await storageRef.getDownloadURL();
          }
        }

        final toSync = b.copyWith(logoPath: finalLogoUrl);
        final success = await service.saveBusiness(business: toSync);

        if (success) {
          final synced = toSync.copyWith(
            isSynced: true,
            lastSyncAttempt: DateTime.now(),
          );
          await BusinessTable.saveSingleBusiness(synced);

          // Update State
          final current = state.value ?? [];
          state = AsyncData([
            for (final item in current)
              if (item.id == synced.id) synced else item,
          ]);
        }
      } catch (e) {
        dev.log("Sync Failed for ${b.id}: $e", name: "BusinessProvider");
      }
    }
  }

  /// --- MANUAL REFRESH ---
  Future<void> forceRefresh() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    await _fetchAndSyncFromCloud(user.uid);
  }
}

@riverpod
Future<BusinessModel> singleBusiness(Ref ref, String businessId) async {
  List<BusinessModel> businesses = await ref.watch(businessProvider.future);

  BusinessModel buss = businesses.firstWhere(
    (element) => element.id == businessId,
  );

  return buss;
}

/// Represents a completely open-ended user permission mapping profile.
class UserBusinessPermissions {
  final bool isOwner;
  final String role; // Can be 'admin', 'salesman', 'manager', 'auditor', etc.

  UserBusinessPermissions({required this.isOwner, required this.role});

  bool get hasAdminPrivileges => isOwner || role == 'admin';
  bool get isSalesman => !isOwner && role == 'salesman';
}

@riverpod
Future<UserBusinessPermissions> currentBusinessRole(
  Ref ref,
  String businessId,
) async {
  final authUser = ref.watch(authControllerProvider).value;
  if (authUser == null || businessId.isEmpty) {
    dev.log("Auth User empty", name: "RoleProvider");
    return UserBusinessPermissions(isOwner: false, role: 'none');
  }

  // 1. Check direct business ownership from the cache
  try {
    final business = await ref.watch(singleBusinessProvider(businessId).future);

    if (business.ownerId == authUser.uid) {
      dev.log(
        "Current user is owner of ${business.name}",
        name: "RoleProvider",
      );
      return UserBusinessPermissions(isOwner: true, role: 'owner');
    } else {
      final particiants = await ref.watch(
        participantProvider(businessId).future,
      );

      var par = particiants.firstWhere(
        (element) => element.userId == authUser.uid,
      );

      dev.log("User is ${par.role}", name: "RoleProvider");

      return UserBusinessPermissions(
        isOwner: false,
        role: par.role.toLowerCase().trim(),
      );
    }
  } catch (e) {
    dev.log(
      "Business data unavailable for ownership assessment: $e",
      name: "RoleProvider",
    );

    return UserBusinessPermissions(isOwner: false, role: 'none');
  }
}
