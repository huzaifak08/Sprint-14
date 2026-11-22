import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/sync/sync_utils.dart';
import 'package:sprint_14/cache/tables/user_table.dart';
import 'package:sprint_14/models/user_model.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/services/storage_service.dart';
import 'package:sprint_14/services/user_service.dart';
import 'package:sprint_14/clients/notifications/notification_cloud_service.dart';
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
      error: (_, _) => null,
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
      cloudUser ??= await _createMissingProfile(uid);
      if (cloudUser != null) {
        final token = await NotificationCloudService().getDeviceToken();

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

  /// The account exists but its profile document doesn't (e.g. the write
  /// failed during sign-up). Recreate it from the Firebase Auth user.
  Future<UserModel?> _createMissingProfile(String uid) async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null || fbUser.uid != uid) return null;
    // Offline, a missing cached doc doesn't mean it's missing on the server.
    if (!await isOnline()) return null;

    final email = fbUser.email ?? '';
    final profile = UserModel(
      uid: uid,
      name: (fbUser.displayName?.trim().isNotEmpty ?? false)
          ? fbUser.displayName!.trim()
          : email.split('@').first,
      email: email.toLowerCase(),
      password: '',
      deviceTokens: const [],
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
      isEmailVerified: fbUser.emailVerified,
      isSynced: true,
    );
    try {
      await _userService
          .saveOrUpdateUser(profile)
          .timeout(const Duration(seconds: 15));
      dev.log("Recreated missing profile.", name: "CurrentUserProvider");
      return profile;
    } catch (e) {
      dev.log("Couldn't recreate profile: $e", name: "CurrentUserProvider");
      return null;
    }
  }

  /// --- PROFILE ACTIONS ---
  /// All edits are saved locally first and shown immediately, then uploaded
  /// in the background. (Waiting for Firestore made edits hang offline,
  /// because a Firestore write only completes once it reaches the server.)

  Future<void> _applyLocal(UserModel updated) async {
    final local = updated.copyWith(isSynced: false);
    state = AsyncData(local);
    await UserTable.saveUser(local);
  }

  Future<void> updateName(String name) async {
    final user = state.value;
    if (user == null || name.trim().isEmpty || name.trim() == user.name) return;
    await _applyLocal(user.copyWith(name: name.trim()));
    syncPendingData();
  }

  /// Returns true if the photo reached the cloud now; false means it is saved
  /// on this device and will upload once online.
  Future<bool> updateProfilePicture(File imageFile) async {
    final user = state.value;
    if (user == null) return false;
    await _applyLocal(user.copyWith(profilePic: imageFile.path));
    await syncPendingData();
    return state.value?.isSynced ?? false;
  }

  Future<void> removeProfilePicture() async {
    final user = state.value;
    if (user == null || user.profilePic == null) return;
    final hadCloudPhoto = user.profilePic!.startsWith('http');
    await _applyLocal(user.copyWith(clearProfilePic: true));
    if (hadCloudPhoto) StorageService().deleteProfilePic(user.uid);
    syncPendingData();
  }

  /// --- UPLOAD PENDING PROFILE CHANGES ---
  Future<void> syncPendingData() {
    return SyncLock.run('profile', _syncPendingProfile);
  }

  Future<void> _syncPendingProfile() async {
    final user = state.value;
    if (user == null || user.isSynced) return;
    if (!await isOnline()) return;

    try {
      var toUpload = user;
      final pic = user.profilePic;

      // A local file path must be uploaded first; never store a device path
      // in Firestore (other devices can't open it).
      if (pic != null && pic.isNotEmpty && !pic.startsWith('http')) {
        final file = File(pic);
        if (!await file.exists()) {
          toUpload = toUpload.copyWith(clearProfilePic: true);
        } else {
          final url = await StorageService().uploadProfilePic(user.uid, file);
          if (url == null) return; // stay unsynced, retry later
          toUpload = toUpload.copyWith(profilePic: url);
        }
      }

      await _userService
          .saveOrUpdateUser(toUpload)
          .timeout(const Duration(seconds: 20));

      // Only mark synced if nothing changed while uploading; otherwise the
      // newer edit stays pending and is uploaded on the next pass.
      final latest = state.value;
      if (latest == null ||
          latest.name != user.name ||
          latest.profilePic != user.profilePic) {
        return;
      }
      final synced = toUpload.copyWith(isSynced: true);
      await UserTable.saveUser(synced);
      state = AsyncData(synced);
    } catch (e) {
      dev.log("Profile sync failed: $e", name: "CurrentUserProvider");
    }
  }

  /// --- CLEANUP ---
  Future<void> clearUser() async {
    final uid = state.value?.uid;
    if (uid != null) {
      final token = await NotificationCloudService().getDeviceToken();
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
