import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'biometric_provider.g.dart';

@Riverpod(keepAlive: true)
class SecurityNotifier extends _$SecurityNotifier {
  bool _isSecurityEnabled = false;
  bool get isSecurityEnabled => _isSecurityEnabled;

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    _isSecurityEnabled = prefs.getBool('biometric_enabled') ?? false;

    // If security is NOT enabled, the state is "True" (Unlocked)
    // If security IS enabled, the state is "False" (Locked)
    return !_isSecurityEnabled;
  }

  void setAuthenticated(bool value) {
    state = AsyncData(value);
  }

  Future<void> toggleBiometrics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    _isSecurityEnabled = value;

    // 🔥 Resets the lock state and triggers UI listeners (like the Switch)
    state = AsyncData(!value);
  }
}
