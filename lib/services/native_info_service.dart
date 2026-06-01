import 'dart:developer' as dev;
import 'package:flutter/services.dart';
import 'package:sprint_14/helpers/constants.dart';

class NativeInfoService {
  static const _channel = MethodChannel(methodChannel);

  static Future<String> getAppVersion() async {
    try {
      final String version = await _channel.invokeMethod(getAppVersionMethod);
      return version;
    } on PlatformException catch (e) {
      dev.log(
        "Failed to fetch native app version: '${e.message}'.",
        name: "NativeInfoService",
      );
      return "Unknown Version";
    }
  }
}
