import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/tables/settings_table.dart';
import 'package:sprint_14/models/app_settings_model.dart';
import 'package:sprint_14/services/native_info_service.dart';
part 'settings_provider.g.dart';

@Riverpod(keepAlive: true)
class AppSettingsNotifier extends _$AppSettingsNotifier {
  @override
  FutureOr<AppSettingsModel> build() async {
    return await SettingsTable.getSettings();
  }

  Future<void> _save(AppSettingsModel updated) async {
    state = AsyncData(updated);
    await SettingsTable.saveSettings(updated);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final current = state.value ?? const AppSettingsModel();
    if (current.themeMode == mode) return;
    await _save(current.copyWith(themeMode: mode));
  }

  /// [businessId] null = open the normal Home screen on launch.
  Future<void> updateLandingPage(String? businessId) async {
    final current = state.value ?? const AppSettingsModel();
    await _save(
      current.copyWith(
        defaultBusinessId: businessId,
        clearDefaultBusiness: businessId == null,
      ),
    );
  }
}

/// App version from the native side, or null when it can't be read.
@riverpod
Future<String?> appVersion(Ref ref) async {
  final version = await NativeInfoService.getAppVersion();
  return version == NativeInfoService.unknownVersion ? null : version;
}
