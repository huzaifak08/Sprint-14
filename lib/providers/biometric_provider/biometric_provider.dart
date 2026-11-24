import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digital_munshi/services/biometric_service.dart';

part 'biometric_provider.g.dart';

const String _prefKey = 'biometric_enabled';

enum BiometricToggleResult { done, unsupported, cancelled }

/// State = "is the app unlocked right now".
/// Lock disabled -> always true. Lock enabled -> false until verified.
@Riverpod(keepAlive: true)
class SecurityNotifier extends _$SecurityNotifier {
  final BiometricService _service = BiometricService();
  bool _isSecurityEnabled = false;
  bool get isSecurityEnabled => _isSecurityEnabled;

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    _isSecurityEnabled = prefs.getBool(_prefKey) ?? false;
    return !_isSecurityEnabled;
  }

  void setAuthenticated(bool value) {
    state = AsyncData(value);
  }

  /// Re-locks the app (e.g. after it was in the background).
  void lock() {
    if (_isSecurityEnabled) state = const AsyncData(false);
  }

  /// Turning the lock on or off always requires verifying the owner first,
  /// so nobody can disable it on an unlocked phone and nobody can enable it
  /// on a device that can't verify them (which would lock them out).
  Future<BiometricToggleResult> setEnabled(bool value) async {
    if (value == _isSecurityEnabled) return BiometricToggleResult.done;
    if (value && !await _service.canAuthenticate()) {
      return BiometricToggleResult.unsupported;
    }

    final verified = await _service.authenticate(
      reason: value
          ? 'Confirm it\'s you to turn on the app lock'
          : 'Confirm it\'s you to turn off the app lock',
    );
    if (!verified) return BiometricToggleResult.cancelled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    _isSecurityEnabled = value;
    // Just verified, so stay unlocked either way.
    state = const AsyncData(true);
    return BiometricToggleResult.done;
  }
}

/// Whether this device can use the app lock at all.
@riverpod
Future<bool> biometricAvailable(Ref ref) =>
    BiometricService().canAuthenticate();
