import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/tables/user_table.dart';
import 'package:sprint_14/models/user_model.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/services/storage_service.dart';
import 'package:sprint_14/services/user_service.dart';
import 'dart:developer' as dev;

part 'user_provider.g.dart';

@Riverpod(keepAlive: true)
class UserNotifier extends _$UserNotifier {
  final UserService _userService = UserService();

  @override
  FutureOr<UserModel?> build() async {
    // 1. Listen to Auth State - Rebuilds whenever login/logout happens
    final authUser = ref.watch(authControllerProvider).value;
    if (authUser == null) return null;

    // 2. Load Data using the robust Sync Logic
    return await _initUser(authUser.uid);
  }

  /// Core logic: Cache first, then Cloud, then Sync
  Future<UserModel?> _initUser(String uid) async {
    // A. Check local cache
    final localUser = await UserTable.getUser(uid);

    if (localUser != null) {
      dev.log(
        "UserProvider: Cache hit. Triggering background sync.",
        name: "UserProvider",
      );
      // Return cached data immediately, then sync in background
      _syncUserWithCloud(uid);
      return localUser;
    }

    // B. Cache is empty, fetch from Cloud
    dev.log(
      "UserProvider: Cache empty. Fetching from Cloud.",
      name: "UserProvider",
    );
    return await _syncUserWithCloud(uid);
  }

  /// Fetches from Firestore, updates cache, and pushes to state
  Future<UserModel?> _syncUserWithCloud(String uid) async {
    try {
      final cloudUser = await _userService.getUserData(uid);
      if (cloudUser != null) {
        // Update SQLite
        await UserTable.saveUser(cloudUser.copyWith(isSynced: true));
        // Update State
        state = AsyncData(cloudUser);
        return cloudUser;
      }
    } catch (e) {
      dev.log("UserProvider Sync Error: $e", name: "UserProvider");
    }
    return null;
  }

  // --- CRUD & Sync Methods (Same as Project/Ledger Providers) ---

  Future<void> updateProfile(UserModel updatedUser, {File? imageFile}) async {
    // 1. Optimistic Update (Local first)
    // If we have a new local image, we show the local path temporarily
    final localUpdate = updatedUser.copyWith(
      isSynced: false,
      profilePic: imageFile?.path ?? updatedUser.profilePic,
    );
    state = AsyncData(localUpdate);
    await UserTable.saveUser(localUpdate);

    try {
      String? finalImageUrl = updatedUser.profilePic;

      // 2. Upload to Storage if a new file is provided
      if (imageFile != null) {
        finalImageUrl = await StorageService().uploadProfilePic(
          updatedUser.uid,
          imageFile,
        );
      }

      // 3. Update Firestore with the new URL
      final userToSync = localUpdate.copyWith(profilePic: finalImageUrl);
      await _userService.saveOrUpdateUser(userToSync);

      // 4. Final Sync
      final syncedUser = userToSync.copyWith(isSynced: true);
      await UserTable.saveUser(syncedUser);
      state = AsyncData(syncedUser);
    } catch (e) {
      dev.log("Failed to sync user profile: $e");
    }
  }

  /// Manual Sync Trigger (Useful for "Pull to Refresh" or Network changes)
  Future<void> syncPendingUser() async {
    final currentUser = state.value;
    if (currentUser == null || currentUser.isSynced) return;

    try {
      await _userService.saveOrUpdateUser(currentUser);
      final syncedUser = currentUser.copyWith(isSynced: true);
      await UserTable.saveUser(syncedUser);
      state = AsyncData(syncedUser);
      dev.log("User data synced successfully");
    } catch (e) {
      dev.log("Background User Sync failed: $e");
    }
  }

  /// Permanent Delete (matches your Table logic)
  Future<void> deleteUserDataLocally() async {
    final uid = state.value?.uid;
    if (uid != null) {
      await UserTable.deleteUser(uid);
      state = const AsyncData(null);
    }
  }
}
