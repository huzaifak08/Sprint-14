import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/tables/user_table.dart';
import 'package:sprint_14/models/user_model.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/services/storage_service.dart';
import 'package:sprint_14/services/user_service.dart';
import 'package:sprint_14/clients/notifications/notification_service.dart';
import 'dart:developer' as dev;

part 'current_user_provider.g.dart';

@Riverpod(keepAlive: true)
class CurrentUserNotifier extends _$CurrentUserNotifier {
  final UserService _userService = UserService();

  @override
  FutureOr<UserModel?> build() async {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      data: (user) {
        if (user == null) return null;
        return _initUser(user.uid);
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  /// --- INITIALIZATION & SYNC ---
  Future<UserModel?> _initUser(String uid) async {
    final localUser = await UserTable.getUser(uid);

    if (localUser != null) {
      dev.log("CurrentUser: Cache Hit.", name: "CurrentUserProvider");
      _syncWithCloud(uid);
      return localUser;
    }

    dev.log(
      "CurrentUser: Cache Empty. Fetching Cloud.",
      name: "CurrentUserProvider",
    );
    return await _syncWithCloud(uid);
  }

  Future<UserModel?> _syncWithCloud(String uid) async {
    try {
      var cloudUser = await _userService.getUserData(uid);
      if (cloudUser != null) {
        final token = await NotificationService().getDeviceToken();

        if (token != null && !cloudUser.deviceTokens.contains(token)) {
          await _userService.updateDeviceToken(
            uid: uid,
            token: token,
            isAdding: true,
          );

          // 🔥 FIX: Instead of calling _syncWithCloud recursively, append the token
          // locally to minimize network roundtrips and eliminate infinite loops.
          final updatedTokens = List<String>.from(cloudUser.deviceTokens)
            ..add(token);
          cloudUser = cloudUser.copyWith(deviceTokens: updatedTokens);
        }

        await UserTable.saveUser(cloudUser.copyWith(isSynced: true));
        state = AsyncData(cloudUser);
        return cloudUser;
      }
    } catch (e) {
      dev.log("Sync Error: $e", name: "CurrentUserProvider");
    }
    return null;
  }

  /// --- PROFILE ACTIONS ---
  Future<void> updateProfile({
    required UserModel updatedUser,
    File? imageFile,
  }) async {
    final previousState = state;

    final localUpdate = updatedUser.copyWith(
      isSynced: false,
      profilePic: imageFile?.path ?? updatedUser.profilePic,
    );
    state = AsyncData(localUpdate);
    await UserTable.saveUser(localUpdate);

    try {
      String? finalImageUrl = updatedUser.profilePic;

      if (imageFile != null) {
        finalImageUrl = await StorageService().uploadProfilePic(
          updatedUser.uid,
          imageFile,
        );
      }

      final userToSync = localUpdate.copyWith(
        profilePic: finalImageUrl,
        isSynced: true,
      );
      await _userService.saveOrUpdateUser(userToSync);

      await UserTable.saveUser(userToSync);
      state = AsyncData(userToSync);
    } catch (e) {
      dev.log("Update Failed: $e");
      state = previousState;
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
