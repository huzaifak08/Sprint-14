import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/tables/user_table.dart';
import 'package:sprint_14/models/user_model.dart';
import 'package:sprint_14/services/user_service.dart';
import 'dart:developer' as dev;

part 'user_provider.g.dart';

@Riverpod(keepAlive: true)
class UserNotifier extends _$UserNotifier {
  final UserService _userService = UserService();

  @override
  FutureOr<UserModel?> build(String userId) async {
    if (userId.isEmpty) return null;
    return await _loadUserFile(userId);
  }

  /// --- CACHE-FIRST PROFILE ENGINE ---
  Future<UserModel?> _loadUserFile(String uid) async {
    // 1. Check local SQLite cache first for instant layout rendering
    final localRecord = await UserTable.getUser(uid);
    if (localRecord != null) {
      dev.log("UserProvider [$uid]: Cache Hit.", name: "UserProvider");

      // Silently check for profile modifications in the background
      _refreshUserFileInBackground(uid);
      return localRecord;
    }

    // 2. Cache Miss: Fallback to Firestore
    dev.log(
      "UserProvider [$uid]: Cache Miss. Fetching Cloud.",
      name: "UserProvider",
    );
    return await _refreshUserFileInBackground(uid);
  }

  /// --- BACKGROUND FIREBASE RECONCILIATION ---
  Future<UserModel?> _refreshUserFileInBackground(String uid) async {
    try {
      final cloudRecord = await _userService.getUserData(uid);
      if (cloudRecord != null) {
        // Cache the other user's data securely for future hits
        await UserTable.saveUser(cloudRecord.copyWith(isSynced: true));

        // Push fresh data to components watching this specific profile
        state = AsyncData(cloudRecord);
        return cloudRecord;
      }
    } catch (e) {
      dev.log(
        "Failed to fetch user profile for $uid: $e",
        name: "UserProvider",
      );
    }
    return null;
  }

  /// --- ADMINISTRATIVE FORCE REFRESH ---
  /// Triggered via pull-to-refresh on staff roster views
  Future<void> forceRefreshUserFile() async {
    // 🔥 FIX: 'arg' is replaced by the actual named parameter variable 'userId'
    if (userId.isEmpty) return;

    state = const AsyncLoading();
    await _refreshUserFileInBackground(userId);
  }
}
