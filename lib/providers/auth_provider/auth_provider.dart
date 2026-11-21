import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:developer' as dev;

import 'package:sprint_14/cache/cache_owner.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/cache/sync/pending_sync.dart';
import 'package:sprint_14/providers/current_user_provider/current_user_provider.dart';
import 'package:sprint_14/services/auth_service.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  // Access the service layer. A field initializer (not `late final` set in
  // build) so rebuilding the provider can't throw LateInitializationError.
  final AuthService _authService = AuthService();

  @override
  FutureOr<User?> build() {
    // Cache ownership for an existing session is checked in main() before
    // the app starts, so this can stay synchronous.
    return FirebaseAuth.instance.currentUser;
  }

  /// --- Sign In Logic ---
  Future<AuthResult?> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authService.signInWithEmail(email, password);

      final signedIn = FirebaseAuth.instance.currentUser;
      if (signedIn != null) await CacheOwner.ensureOwner(signedIn.uid);

      // Update the global state so other parts of the app know the user is here
      state = AsyncValue.data(FirebaseAuth.instance.currentUser);

      return result; // 🔥 Return the specific result to the UI
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return AuthResult.error;
    }
  }

  /// --- Registration Logic ---
  Future<AuthResult?> signUp(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authService.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );

      // Refresh local state with the new user object
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) await CacheOwner.ensureOwner(currentUser.uid);
      state = AsyncValue.data(currentUser);

      // Logic: New users are always unverified initially
      return AuthResult.unverified;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return AuthResult.error;
    }
  }

  /// --- Check Verification Status ---
  /// Updates the state if the user has verified their email
  Future<void> refreshUserStatus() async {
    final isVerified = await _authService.checkEmailVerified();
    if (isVerified) {
      // Trigger a rebuild by getting the updated user object
      state = AsyncValue.data(FirebaseAuth.instance.currentUser);
    }
  }

  Future<void> passwordReset(String email) async {
    state = const AsyncValue.loading();
    await AsyncValue.guard(() => _authService.resetPassword(email));
    state = AsyncValue.data(FirebaseAuth.instance.currentUser);
  }

  Future<void> resendVerification() async {
    // We don't necessarily want to set the whole app to a "loading" state
    // for a resend, so we just call the service.
    try {
      await _authService.sendVerificationEmail();
    } catch (e, st) {
      // You could optionally set the state to error here if you want
      // the global listener to catch it.
      dev.log("Resend error: $e $st");
    }
  }

  /// --- Sign Out ---
  /// 1. Tries to upload pending changes (max 10 s).
  /// 2. Removes this device's push token from the profile.
  /// 3. Wipes the local cache only if everything reached the cloud; otherwise
  ///    the cache is kept so the same account gets its changes back on the
  ///    next sign-in (a different account wipes it, see [CacheOwner]).
  Future<void> logout() async {
    // Stay signed in (no loading state yet) while syncing: dependent
    // providers need the current user to upload and to remove the token.
    try {
      await syncAllPending(ref.read).timeout(const Duration(seconds: 10));
    } catch (e) {
      dev.log("Pre-logout sync incomplete: $e", name: "AuthController");
    }

    try {
      await ref
          .read(currentUserProvider.notifier)
          .clearUser()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      dev.log("Device token cleanup skipped: $e", name: "AuthController");
    }

    try {
      if (!await LocalCacheManager.hasUnsyncedData()) {
        await LocalCacheManager.deleteAllCacheData();
        await CacheOwner.clear();
      } else {
        dev.log(
          "Unsynced changes kept on device for next sign-in.",
          name: "AuthController",
        );
      }
    } catch (e) {
      dev.log("Cache cleanup failed: $e", name: "AuthController");
    }

    state = const AsyncValue.loading();
    await _authService.logout();
    state = const AsyncValue.data(null);
  }
}
