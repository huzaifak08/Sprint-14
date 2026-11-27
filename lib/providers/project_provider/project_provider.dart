import 'dart:async';
import 'dart:developer' as dev;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:digital_munshi/cache/init_cache.dart';
import 'package:digital_munshi/cache/sync/sync_merge.dart';
import 'package:digital_munshi/cache/sync/sync_utils.dart';
import 'package:digital_munshi/cache/tables/project_table.dart';
import 'package:digital_munshi/helpers/constants.dart';
import 'package:digital_munshi/models/project_model.dart';
import 'package:digital_munshi/providers/auth_provider/auth_provider.dart';
import 'package:digital_munshi/services/backup_code_scanner_service.dart';
import 'package:digital_munshi/services/project_pdf_service.dart';
import 'package:digital_munshi/services/project_service.dart';

part 'project_provider.g.dart';

/// True only for the app owner's account, which gets the Projects screen.
@riverpod
bool isAppOwner(Ref ref) {
  final email = ref.watch(authControllerProvider).value?.email;
  return email != null && email.trim().toLowerCase() == appOwnerEmail;
}

/// Project service for the signed-in user, or null when signed out.
@Riverpod(keepAlive: true)
ProjectService? projectService(Ref ref) {
  final uid = ref.watch(authControllerProvider).value?.uid;
  return uid == null ? null : ProjectService(uid: uid);
}

/// On-device backup-code reader; its native recognizer is closed when no
/// screen uses it any more.
@riverpod
BackupCodeScannerService backupCodeScanner(Ref ref) {
  final scanner = BackupCodeScannerService();
  ref.onDispose(scanner.dispose);
  return scanner;
}

/// Builds and shares one-page project PDFs (stateless).
@Riverpod(keepAlive: true)
ProjectPdfService projectPdfService(Ref ref) => ProjectPdfService();

/// The signed-in user's projects, newest first.
///
/// Cache-first: the SQLite copy is shown at once (also offline), live
/// server snapshots are merged into it, and local edits are written to the
/// cache immediately and uploaded in the background (newest edit wins).
@Riverpod(keepAlive: true)
class ProjectNotifier extends _$ProjectNotifier {
  static const _firstLoadTimeout = Duration(seconds: 15);

  /// Merges run one at a time, in snapshot order.
  Future<void> _mergeQueue = Future.value();

  /// Bumped on every build, so callbacks from a previous session (e.g.
  /// before a sign-out) never touch the current state.
  int _generation = 0;

  @override
  Future<List<ProjectModel>> build() async {
    final generation = ++_generation;
    final service = ref.watch(projectServiceProvider);
    if (service == null) return const [];

    final cached = await ProjectTable.getProjects();
    var built = false;
    final firstSync = Completer<void>();
    // Handled even when nobody waits for it (cache already had data).
    firstSync.future.ignore();
    bool isCurrent() => ref.mounted && generation == _generation;

    final sub = service.watchProjects().listen(
      (cloud) => _mergeQueue = _mergeQueue.then((_) async {
        if (!isCurrent()) return;
        try {
          await _mergeCloud(cloud);
          if (built && isCurrent()) {
            state = AsyncData(await ProjectTable.getProjects());
          }
        } catch (e) {
          dev.log("Project merge failed: $e", name: "ProjectProvider");
        } finally {
          if (!firstSync.isCompleted) firstSync.complete();
        }
      }),
      onError: (Object e, StackTrace st) {
        dev.log("Project stream error: $e", name: "ProjectProvider");
        if (!firstSync.isCompleted) {
          firstSync.completeError(e, st);
        } else if (built && isCurrent() && (state.value?.isEmpty ?? true)) {
          state = AsyncError(e, st);
        }
      },
    );
    ref.onDispose(sub.cancel);

    // Nothing cached yet (first open): wait briefly for the cloud so the
    // screen doesn't flash "No projects". Errors here surface on screen.
    if (cached.isEmpty && await isOnline()) {
      await firstSync.future.timeout(_firstLoadTimeout, onTimeout: () {});
    }
    built = true;
    syncPending();
    return cached.isEmpty ? ProjectTable.getProjects() : cached;
  }

  /// --- 1. Cloud → Cache Merge ---
  Future<void> _mergeCloud(List<ProjectModel> cloud) async {
    final result = mergeCloudWithLocal<ProjectModel>(
      cloud: cloud,
      local: await ProjectTable.getAllRows(),
      idOf: (p) => p.id,
      isSynced: (p) => p.isSynced,
      isDeleted: (p) => p.isDeleted,
      markSynced: (p) => p.copyWith(isSynced: true),
    );
    await ProjectTable.saveFromCloud(result.toSave);
    await ProjectTable.removeSynced(result.toRemove);
  }

  /// --- 2. Create / Update Project ---
  /// Shown and cached immediately; uploaded in the background.
  Future<void> saveProject(ProjectModel project) async {
    final local = project.copyWith(
      isSynced: false,
      isDeleted: false,
      updatedAt: DateTime.now(),
    );
    state = AsyncData(
      [local, ...?state.value?.where((p) => p.id != local.id)]
        ..sort(_newestFirst),
    );
    await ProjectTable.save(local);
    syncPending();
  }

  /// --- 3. Delete Project (Soft Delete until uploaded) ---
  Future<void> deleteProject(String id) async {
    final current = state.value ?? const <ProjectModel>[];
    final project = current.where((p) => p.id == id).firstOrNull;
    if (project == null) return;

    state = AsyncData(current.where((p) => p.id != id).toList());
    await ProjectTable.save(
      project.copyWith(
        isDeleted: true,
        isSynced: false,
        updatedAt: DateTime.now(),
      ),
    );
    syncPending();
  }

  /// --- 4. Background Sync ---
  Future<void> syncPending() => SyncLock.run('projects', _syncPending);

  Future<void> _syncPending() async {
    final service = ref.read(projectServiceProvider);
    if (service == null || !await isOnline()) return;

    final unsynced = await ProjectTable.getUnsynced();
    if (unsynced.isEmpty) return;

    for (final p in unsynced) {
      try {
        if (p.isDeleted) {
          await service.deleteProject(p.id);
          await ProjectTable.hardDelete(p.id);
          continue;
        }

        final newerCloud = await service.saveProject(p);
        final unchanged = await LocalCacheManager.markSyncedIfUnchanged(
          ProjectTable.tableName,
          p.toJsonDb(),
        );
        if (newerCloud != null && unchanged) {
          // Another device edited it more recently: keep their version.
          await ProjectTable.save(newerCloud.copyWith(isSynced: true));
        }
      } catch (e) {
        dev.log("Sync failed for project ${p.id}: $e", name: "ProjectProvider");
      }
    }

    if (ref.mounted) state = AsyncData(await ProjectTable.getProjects());
  }

  static int _newestFirst(ProjectModel a, ProjectModel b) =>
      b.createdAt.compareTo(a.createdAt);
}
