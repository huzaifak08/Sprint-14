import 'package:shared_preferences/shared_preferences.dart';

/// Emails that signed in on this device, newest first (for suggestions).
class RecentEmails {
  RecentEmails._();

  static const _key = 'sprint-14-recent-emails';
  static const _max = 5;

  static Future<List<String>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> remember(String email) async {
    final value = email.trim().toLowerCase();
    if (value.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = [
        value,
        ...(prefs.getStringList(_key) ?? const <String>[]).where(
          (e) => e != value,
        ),
      ].take(_max).toList();
      await prefs.setStringList(_key, list);
    } catch (_) {}
  }
}
