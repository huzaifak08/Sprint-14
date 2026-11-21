import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Serialises sync jobs per key so the same records are never uploaded twice
/// in parallel. If a job is requested while one is running, a single extra
/// pass is scheduled after it, so changes made mid-sync are still picked up.
class SyncLock {
  SyncLock._();

  static final Map<String, Future<void>> _running = {};
  static final Set<String> _rerunRequested = {};

  static Future<void> run(String key, Future<void> Function() task) {
    final existing = _running[key];
    if (existing != null) {
      _rerunRequested.add(key);
      return existing;
    }

    final future = () async {
      try {
        do {
          _rerunRequested.remove(key);
          await task();
        } while (_rerunRequested.contains(key));
      } finally {
        _running.remove(key);
        _rerunRequested.remove(key);
      }
    }();

    _running[key] = future;
    return future;
  }

  static bool isRunning(String key) => _running.containsKey(key);
}

/// True when the device has any network connection.
Future<bool> isOnline() async {
  final results = await Connectivity().checkConnectivity();
  return results.any((r) => r != ConnectivityResult.none);
}

/// Splits [items] into chunks of at most [size] (Firestore `whereIn` allows 30).
List<List<T>> chunked<T>(List<T> items, [int size = 30]) {
  return [
    for (var i = 0; i < items.length; i += size)
      items.sublist(i, i + size > items.length ? items.length : i + size),
  ];
}
