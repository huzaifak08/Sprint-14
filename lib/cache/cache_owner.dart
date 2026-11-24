import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digital_munshi/cache/init_cache.dart';

/// Tracks which account the local SQLite cache belongs to.
///
/// Cache tables have no user column, so when a *different* account signs in
/// the cache is wiped before anything reads it. The same account signing back
/// in keeps its cache, including changes that weren't uploaded before logout.
class CacheOwner {
  CacheOwner._();

  static const String _key = 'dm-cache-owner-uid';

  static Future<void> ensureOwner(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final owner = prefs.getString(_key);

      if (owner != null && owner != uid) {
        dev.log(
          'Different account signed in, clearing previous cache.',
          name: 'CacheOwner',
        );
        await LocalCacheManager.deleteAllCacheData();
      }

      // First run after this change: before it, logout always wiped the
      // cache, so anything left over belongs to the signed-in user.
      if (owner != uid) await prefs.setString(_key, uid);
    } catch (e) {
      dev.log('Cache owner check failed: $e', name: 'CacheOwner');
    }
  }

  /// Forget the owner (used after the cache has been wiped on logout).
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
