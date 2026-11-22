import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:developer' as dev;

import 'package:sprint_14/cache/cache_owner.dart';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/cache/sync/pending_sync.dart';
import 'package:sprint_14/providers/current_user_provider/current_user_provider.dart';
import 'package:sprint_14/services/auth_service.dart';

part 'auth_provider.g.dart';

/// Global session state: the signed-in Firebase user, or null.
///
/// It never holds an error: sign-in / sign-up failures are thrown to the
/// calling screen as [AuthFailure]. (Putting errors in this shared state made
/// every screen listening to it react, e.g. duplicate snackbars.)
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  // A field initializer (not `late final` set in build) so rebuilding the
  // provider can't throw LateInitializationError.
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSub;
  bool _loggingOut = false;

  @override
  FutureOr<User?> build() {
    // React to sessions ended outside the app (account disabled or deleted,
    // password changed elsewhere, token revoked). Only sign-OUTS are handled
    // here: sign-ins are applied by signIn/signUp after the cache owner
    // check, so dependent providers never read another account's cache.
    _authSub?.cancel();
    _authSub = _authService.authStateChanges.listen((user) {
      if (user == null && !_loggingOut && state.value != null) {
        dev.log("Session ended outside the app.", name: "AuthController");
        state = const AsyncData(null);
      }
    });
    ref.onDispose(() => _authSub?.cancel());

    // Cache ownership for an existing session is checked in main() before
    // the app starts, so this can stay synchronous.
    return FirebaseAuth.instance.currentUser;
  }

  /// Signs in. Returns [AuthResult.success] or [AuthResult.unverified];
  /// throws [AuthFailure] with a user-friendly message on failure.
  Future<AuthResult> signIn(String email, String password) async {
    final result = await _authService.signInWithEmail(email, password);
    await _applySignedInUser();
    return result;
  }

  /// Creates an account (always unverified at first). Throws [AuthFailure].
  Future<AuthResult> signUp(String name, String email, String password) async {
    final result = await _authService.registerWithEmail(
      name: name,
      email: email,
      password: password,
    );
    await _applySignedInUser();
    return result;
  }

  Future<void> _applySignedInUser() async {
    final user = FirebaseAuth.instance.currentUser;
    // Wipe another account's cache BEFORE dependents rebuild for this user.
    if (user != null) await CacheOwner.ensureOwner(user.uid);
    state = AsyncData(user);
  }

  /// Reloads the user; returns true once the email is verified.
  Future<bool> refreshUserStatus() async {
    final isVerified = await _authService.checkEmailVerified();
    if (isVerified) state = AsyncData(FirebaseAuth.instance.currentUser);
    return isVerified;
  }

  /// Throws [AuthFailure] if the email couldn't be sent.
  Future<void> resendVerification() => _authService.resendVerificationEmail();

  /// --- Sign Out ---
  /// 1. Tries to upload pending changes (max 10 s).
  /// 2. Removes this device's push token from the profile.
  /// 3. Wipes the local cache only if everything reached the cloud; otherwise
  ///    the cache is kept so the same account gets its changes back on the
  ///    next sign-in (a different account wipes it, see [CacheOwner]).
  Future<void> logout() async {
    _loggingOut = true;
    try {
      await _logout();
    } finally {
      _loggingOut = false;
    }
  }

  Future<void> _logout() async {
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
