import 'package:flutter/material.dart';

class AppSettingsModel {
  final ThemeMode themeMode;
  final String? defaultBusinessId;

  const AppSettingsModel({
    this.themeMode = ThemeMode.system,
    this.defaultBusinessId,
  });

  bool get isDarkMode => themeMode == ThemeMode.dark;

  AppSettingsModel copyWith({
    ThemeMode? themeMode,
    String? defaultBusinessId,
    bool clearDefaultBusiness = false,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      defaultBusinessId: clearDefaultBusiness
          ? null
          : (defaultBusinessId ?? this.defaultBusinessId),
    );
  }

  // The column is still called `isDarkMode` (no migration needed):
  // 0 = light, 1 = dark (same values as before), 2 = follow system.
  static int _encode(ThemeMode m) => switch (m) {
    ThemeMode.light => 0,
    ThemeMode.dark => 1,
    ThemeMode.system => 2,
  };

  static ThemeMode _decode(Object? v) => switch (v) {
    1 => ThemeMode.dark,
    2 => ThemeMode.system,
    _ => ThemeMode.light,
  };

  Map<String, dynamic> toJsonDb() => {
    'isDarkMode': _encode(themeMode),
    'defaultBusinessId': defaultBusinessId,
  };

  factory AppSettingsModel.fromJsonDb(Map<String, dynamic> map) =>
      AppSettingsModel(
        themeMode: _decode(map['isDarkMode']),
        defaultBusinessId: map['defaultBusinessId'] as String?,
      );
}
