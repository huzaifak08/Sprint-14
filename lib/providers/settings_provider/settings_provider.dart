import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/tables/settings_table.dart';
import 'package:sprint_14/models/app_settings_model.dart';
part 'settings_provider.g.dart';

@Riverpod(keepAlive: true)
class AppSettingsNotifier extends _$AppSettingsNotifier {
  @override
  FutureOr<AppSettingsModel> build() async {
    return await SettingsTable.getSettings();
  }

  Future<void> updateTheme(bool isDark) async {
    final current = state.value ?? AppSettingsModel();
    final updated = AppSettingsModel(
      isDarkMode: isDark,
      defaultBusinessId: current.defaultBusinessId,
    );
    state = AsyncData(updated);
    await SettingsTable.saveSettings(updated);
  }

  Future<void> updateLandingPage(String? businessId) async {
    final current = state.value ?? AppSettingsModel();
    final updated = AppSettingsModel(
      isDarkMode: current.isDarkMode,
      defaultBusinessId: businessId,
    );
    state = AsyncData(updated);
    await SettingsTable.saveSettings(updated);
  }
}
