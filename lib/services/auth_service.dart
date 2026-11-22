import 'package:firebase_auth/firebase_auth.dart';
import 'package:sprint_14/models/user_model.dart';
import 'dart:developer' as dev;

import 'package:sprint_14/services/user_service.dart';

enum AuthResult { success, unverified, error }

/// A user-facing auth error. [message] is safe to show in the UI.
class AuthFailure implements Exception {
  final String message;
  final String? code;
  const AuthFailure(this.message, {this.code});

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  /// --- 1. SESSION ---

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _userService.getUserData(user.uid);
  }

  /// --- 2. REGISTRATION & VERIFICATION ---

  /// Creates the account, then (best effort) the profile document and the
  /// verification email. Only account creation can fail the sign-up: if the
  /// profile write fails, the profile is created on the next app start (see
  /// CurrentUserNotifier), so the user never ends up with a half-made
  /// account that can't sign up again ("email already in use").
  Future<AuthResult> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      dev.log("Register error: ${e.code}", name: "AuthService");
      throw _toFailure(e);
    }

    final user = credential.user;
    if (user == null) throw const AuthFailure('Sign up failed. Try again.');

    try {
      await user.updateDisplayName(name);
    } catch (e) {
      dev.log("Display name not set: $e", name: "AuthService");
    }

    try {
      await _userService
          .saveOrUpdateUser(
            UserModel(
              uid: user.uid,
              name: name,
              email: email.trim().toLowerCase(),
              // Passwords are handled by Firebase Auth only; never store them.
              password: '',
              deviceTokens: const [],
              createdAt: DateTime.now(),
              isEmailVerified: false,
              isSynced: true,
            ),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      dev.log("Profile will be created later: $e", name: "AuthService");
    }

    try {
      await user.sendEmailVerification();
    } catch (e) {
      dev.log("Verification email not sent yet: $e", name: "AuthService");
    }

    return AuthResult.unverified;
  }

  /// Resends the verification email. Throws [AuthFailure] on failure.
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('You are signed out.');
    if (user.emailVerified) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _toFailure(e);
    }
  }

  /// Reloads the user from Firebase. Returns true once the email is verified.
  /// Never throws (offline just returns false).
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed == null || !refreshed.emailVerified) return false;

      // Refresh the ID token so the backend sees email_verified = true.
      await refreshed.getIdToken(true);

      try {
        final profile = await getCurrentUserProfile();
        if (profile != null && !profile.isEmailVerified) {
          await _userService.saveOrUpdateUser(
            profile.copyWith(isEmailVerified: true),
          );
        }
      } catch (e) {
        dev.log("Profile verified flag not updated: $e", name: "AuthService");
      }
      return true;
    } catch (e) {
      dev.log("Verification check failed: $e", name: "AuthService");
      return false;
    }
  }

  /// --- 3. SIGN IN / PASSWORD ---

  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final credential = await _signIn(email.trim(), password);
      final user = credential.user;
      if (user != null && !user.emailVerified) return AuthResult.unverified;
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      throw _toFailure(e);
    }
  }

  Future<UserCredential> _signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Older versions trimmed passwords at sign-up; keep those accounts
      // working if the typed password has surrounding spaces.
      final trimmed = password.trim();
      final badCredential =
          e.code == 'invalid-credential' || e.code == 'wrong-password';
      if (badCredential && trimmed != password && trimmed.isNotEmpty) {
        return _auth.signInWithEmailAndPassword(
          email: email,
          password: trimmed,
        );
      }
      rethrow;
    }
  }

  /// Throws [AuthFailure] on failure.
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _toFailure(e);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// --- 4. ERRORS ---

  AuthFailure _toFailure(FirebaseAuthException e) {
    final message = switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'INVALID_LOGIN_CREDENTIALS' => 'Incorrect email or password.',
      'invalid-email' => 'That email address is not valid.',
      'user-disabled' => 'This account has been disabled.',
      'email-already-in-use' =>
        'An account already exists for this email. Try signing in.',
      'weak-password' => 'Password is too weak. Use at least 6 characters.',
      'too-many-requests' =>
        'Too many attempts. Please wait a few minutes and try again.',
      'network-request-failed' =>
        'No internet connection. Check your network and try again.',
      'operation-not-allowed' =>
        'Email sign-in is not enabled. Contact support.',
      'missing-email' || 'channel-error' => 'Please fill in all fields.',
      _ => 'Something went wrong. Please try again.',
    };
    return AuthFailure(message, code: e.code);
  }
}
