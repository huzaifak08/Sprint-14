import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprint_14/models/app_settings_model.dart';

void main() {
  test('old saved values still load (0 = light, 1 = dark)', () {
    expect(
      AppSettingsModel.fromJsonDb({'isDarkMode': 0}).themeMode,
      ThemeMode.light,
    );
    expect(
      AppSettingsModel.fromJsonDb({'isDarkMode': 1}).themeMode,
      ThemeMode.dark,
    );
  });

  test('system mode round-trips', () {
    const s = AppSettingsModel(
      themeMode: ThemeMode.system,
      defaultBusinessId: 'b1',
    );
    final back = AppSettingsModel.fromJsonDb(s.toJsonDb());
    expect(back.themeMode, ThemeMode.system);
    expect(back.defaultBusinessId, 'b1');
  });

  test('new installs follow the system theme', () {
    expect(const AppSettingsModel().themeMode, ThemeMode.system);
  });

  test('clearing the start screen', () {
    const s = AppSettingsModel(defaultBusinessId: 'b1');
    expect(s.copyWith(clearDefaultBusiness: true).defaultBusinessId, isNull);
    expect(s.copyWith(themeMode: ThemeMode.dark).defaultBusinessId, 'b1');
  });
}
