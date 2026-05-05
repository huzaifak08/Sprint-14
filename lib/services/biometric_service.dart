import 'package:local_auth/local_auth.dart';
import 'dart:developer' as dev;

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canAuthenticate() async {
    final bool canCheck = await _auth.canCheckBiometrics;
    final bool isSupported = await _auth.isDeviceSupported();
    return canCheck || isSupported;
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access your projects and ledger',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      dev.log("Biometric Auth Error: $e");
      return false;
    }
  }
}
