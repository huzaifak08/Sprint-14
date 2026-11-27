import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:digital_munshi/helpers/backup_code_parser.dart';

/// Reads backup codes from a photo with on-device ML Kit text recognition.
///
/// Runs fully offline: the image never leaves the device, which matters
/// because backup codes are account secrets.
class BackupCodeScannerService {
  /// ML Kit is only available on Android and iOS.
  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  TextRecognizer? _recognizer;

  /// Returns the codes found in the image at [imagePath] (may be empty).
  /// Throws if recognition fails.
  Future<List<String>> scan(String imagePath) async {
    final recognizer = _recognizer ??= TextRecognizer();
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return extractBackupCodes(result.text);
    } catch (e) {
      dev.log("Backup code scan failed: $e", name: "BackupCodeScanner");
      rethrow;
    }
  }

  /// Frees the native recognizer.
  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
