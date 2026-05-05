import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'biometric_provider.g.dart';

@Riverpod(keepAlive: true)
class SecurityNotifier extends _$SecurityNotifier {
  // We use a private variable to track the "Setting"
  // while the State (bool) tracks "Is the user currently Unlocked?"
  bool _isSecurityEnabled = false;
  bool get isSecurityEnabled => _isSecurityEnabled;

  @override
  Future<bool> build() async {
    // 1. Wait for preferences to load BEFORE returning the initial state
    final prefs = await SharedPreferences.getInstance();
    _isSecurityEnabled = prefs.getBool('biometric_enabled') ?? false;

    // 2. If security is NOT enabled, the state is "True" (Unlocked)
    // If security IS enabled, the state is "False" (Locked)
    return !_isSecurityEnabled;
  }

  /// Manually update authentication status (e.g., after a successful fingerprint scan)
  void setAuthenticated(bool value) {
    state = AsyncData(value);
  }

  /// Updates the user's preference and resets the lock state
  Future<void> toggleBiometrics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    _isSecurityEnabled = value;

    // 🔥 This line is what triggers the UI to refresh!
    state = AsyncData(!value);
  }
}
