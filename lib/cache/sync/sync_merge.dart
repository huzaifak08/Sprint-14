/// Result of reconciling a fresh cloud snapshot with the local SQLite rows.
class MergeResult<T> {
  /// Items the UI should show (pending deletes are excluded).
  final List<T> visible;

  /// Cloud items that should be written to the local cache.
  /// Local rows with pending (unsynced) changes are never in here, so a cloud
  /// fetch can't overwrite edits that haven't been uploaded yet.
  final List<T> toSave;

  /// IDs of synced local rows that no longer exist in the cloud
  /// (deleted on another device) and should be removed from the cache.
  final List<String> toRemove;

  const MergeResult({
    required this.visible,
    required this.toSave,
    required this.toRemove,
  });
}

/// Reconciles [cloud] with [local] (every local row in the same scope,
/// including unsynced and soft-deleted rows).
///
/// Rules:
/// * A local row with pending changes (`isSynced == false`) always wins.
/// * Otherwise the cloud copy wins and is cached as synced.
/// * Unsynced local rows missing from the cloud are kept (not uploaded yet).
/// * Synced local rows missing from the cloud were deleted elsewhere and are
///   removed, unless [pruneMissing] is false (use that when the cloud query is
///   partial, e.g. limited or filtered, so "missing" doesn't mean "deleted").
MergeResult<T> mergeCloudWithLocal<T>({
  required List<T> cloud,
  required List<T> local,
  required String Function(T item) idOf,
  required bool Function(T item) isSynced,
  required bool Function(T item) isDeleted,
  required T Function(T item) markSynced,
  bool pruneMissing = true,
  int Function(T a, T b)? sort,
}) {
  final localById = {for (final item in local) idOf(item): item};
  final cloudIds = {for (final item in cloud) idOf(item)};

  final merged = <T>[];
  final toSave = <T>[];
  final toRemove = <String>[];

  // Pending local creations go first so new items stay at the top.
  for (final item in local) {
    if (!isSynced(item) && !cloudIds.contains(idOf(item))) {
      merged.add(item);
    }
  }

  for (final cloudItem in cloud) {
    final id = idOf(cloudItem);
    final localItem = localById[id];

    if (localItem != null && !isSynced(localItem)) {
      merged.add(localItem);
    } else {
      final synced = markSynced(cloudItem);
      merged.add(synced);
      toSave.add(synced);
    }
  }

  if (pruneMissing) {
    for (final item in local) {
      final id = idOf(item);
      if (isSynced(item) && !cloudIds.contains(id)) toRemove.add(id);
    }
  }

  final visible = merged.where((item) => !isDeleted(item)).toList();
  if (sort != null) visible.sort(sort);

  return MergeResult(visible: visible, toSave: toSave, toRemove: toRemove);
}
