import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sprint_14/helpers/sp_helper.dart';

final themeNotifier = ChangeNotifierProvider((ref) => ThemeState());

class ThemeState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeState() {
    _loadThemeFromSP();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    SpHelper.addOrUpdateThemeMode(mode.name);
  }

  Future<void> _loadThemeFromSP() async {
    try {
      final themeName = await SpHelper.getThemeMode();
      if (themeName != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (element) => element.name == themeName,
          orElse: () => ThemeMode.system,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Theme Load Error: $e");
    }
  }
}
