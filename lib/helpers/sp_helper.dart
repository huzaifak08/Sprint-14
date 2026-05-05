import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprint_14/helpers/constants.dart';

class SpHelper {
  // Save Theme Mode:
  static void addOrUpdateThemeMode(String modeName) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString(themeKey, modeName);
  }

  // Get Theme Mode:
  static Future<String?> getThemeMode() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final theme = sp.getString(themeKey);
    return theme;
  }
}
