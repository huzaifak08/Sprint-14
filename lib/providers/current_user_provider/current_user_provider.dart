import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/tables/user_table.dart';
import 'package:sprint_14/models/user_model.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/services/storage_service.dart';
import 'package:sprint_14/services/user_service.dart';
import 'package:sprint_14/clients/notifications/notification_service.dart'; // 🔥 Added
import 'dart:developer' as dev;

part 'current_user_provider.g.dart';

@Riverpod(keepAlive: true)
class CurrentUserNotifier extends _$CurrentUserNotifier {
  final UserService _userService = UserService();

  @override
  FutureOr<UserModel?> build() async {
    // 1. Watch Auth State
    // When authController changes (login/logout), this build method re-runs automatically.
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      data: (user) {
        if (user == null) return null;
        return _initUser(user.uid);
      },
      loading: () => null,
      error: (_, _) => null,
    );
  }

  /// --- INITIALIZATION & SYNC ---

  Future<UserModel?> _initUser(String uid) async {
    // A. Try Local Cache first for instant UI loading
    final localUser = await UserTable.getUser(uid);

    if (localUser != null) {
      dev.log("UserProvider: Cache Hit", name: "UserProvider");
      // Trigger background sync to get latest cloud data (like new device tokens)
      _syncWithCloud(uid);
      return localUser;
    }

    // B. Cache empty? Fetch from Cloud
    dev.log("UserProvider: Cache Empty, Fetching Cloud", name: "UserProvider");
    return await _syncWithCloud(uid);
  }

  Future<UserModel?> _syncWithCloud(String uid) async {
    try {
      final cloudUser = await _userService.getUserData(uid);
      if (cloudUser != null) {
        // 🔥 Multi-Device Token Check: Ensure this device's token is in the list
        final token = await NotificationService().getDeviceToken();
        if (token != null && !cloudUser.deviceTokens.contains(token)) {
          await _userService.updateDeviceToken(
            uid: uid,
            token: token,
            isAdding: true,
          );
          // Re-fetch to get the model with the updated token list
          return _syncWithCloud(uid);
        }

        await UserTable.saveUser(cloudUser.copyWith(isSynced: true));
        state = AsyncData(cloudUser);
        return cloudUser;
      }
    } catch (e) {
      dev.log("Sync Error: $e", name: "UserProvider");
    }
    return null;
  }

  /// --- PROFILE ACTIONS ---

  Future<void> updateProfile({
    required UserModel updatedUser,
    File? imageFile,
  }) async {
    final previousState = state;

    // 1. Optimistic Update (UI updates immediately)
    final localUpdate = updatedUser.copyWith(
      isSynced: false,
      profilePic: imageFile?.path ?? updatedUser.profilePic,
    );
    state = AsyncData(localUpdate);
    await UserTable.saveUser(localUpdate);

    try {
      String? finalImageUrl = updatedUser.profilePic;

      // 2. Upload Image if changed
      if (imageFile != null) {
        finalImageUrl = await StorageService().uploadProfilePic(
          updatedUser.uid,
          imageFile,
        );
      }

      // 3. Push to Firestore
      final userToSync = localUpdate.copyWith(
        profilePic: finalImageUrl,
        isSynced: true,
      );
      await _userService.saveOrUpdateUser(userToSync);

      // 4. Update Local DB & State
      await UserTable.saveUser(userToSync);
      state = AsyncData(userToSync);
    } catch (e) {
      dev.log("Update Failed: $e");
      state = previousState; // Rollback on failure
    }
  }

  /// --- MANUAL SYNC ---

  Future<void> syncPendingData() async {
    final user = state.value;
    if (user == null || user.isSynced) return;

    try {
      await _userService.saveOrUpdateUser(user);
      final synced = user.copyWith(isSynced: true);
      await UserTable.saveUser(synced);
      state = AsyncData(synced);
    } catch (e) {
      dev.log("Manual Sync Failed: $e");
    }
  }

  /// --- CLEANUP ---

  Future<void> clearUser() async {
    final uid = state.value?.uid;
    if (uid != null) {
      final token = await NotificationService().getDeviceToken();
      if (token != null) {
        await _userService.updateDeviceToken(
          uid: uid,
          token: token,
          isAdding: false,
        );
      }
    }
    state = const AsyncData(null);
  }
}
