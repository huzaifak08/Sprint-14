import 'package:local_auth/local_auth.dart';
import 'package:digital_munshi/helpers/constants.dart';
import 'dart:developer' as dev;

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// True if the device can verify the owner (biometrics or screen lock).
  Future<bool> canAuthenticate() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      dev.log("Biometric availability check failed: $e");
      return false;
    }
  }

  Future<bool> authenticate({
    String reason = 'Unlock $appName to access your ledgers',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        // Allow the device PIN/pattern as a fallback so a failing
        // fingerprint sensor can never lock the user out of the app.
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      dev.log("Biometric Auth Error: $e");
      return false;
    }
  }
}
