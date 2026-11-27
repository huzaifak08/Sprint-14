// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// True only for the app owner's account, which gets the Projects screen.

@ProviderFor(isAppOwner)
final isAppOwnerProvider = IsAppOwnerProvider._();

/// True only for the app owner's account, which gets the Projects screen.

final class IsAppOwnerProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// True only for the app owner's account, which gets the Projects screen.
  IsAppOwnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isAppOwnerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isAppOwnerHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isAppOwner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isAppOwnerHash() => r'e4aae6325d0abdca97ac1caf522eea0709d5e368';

/// Project service for the signed-in user, or null when signed out.

@ProviderFor(projectService)
final projectServiceProvider = ProjectServiceProvider._();

/// Project service for the signed-in user, or null when signed out.

final class ProjectServiceProvider
    extends
        $FunctionalProvider<ProjectService?, ProjectService?, ProjectService?>
    with $Provider<ProjectService?> {
  /// Project service for the signed-in user, or null when signed out.
  ProjectServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectServiceHash();

  @$internal
  @override
  $ProviderElement<ProjectService?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProjectService? create(Ref ref) {
    return projectService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectService? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProjectService?>(value),
    );
  }
}

String _$projectServiceHash() => r'7c6e636b649df5c843b3c53877c2df4102ee5b53';

/// On-device backup-code reader; its native recognizer is closed when no
/// screen uses it any more.

@ProviderFor(backupCodeScanner)
final backupCodeScannerProvider = BackupCodeScannerProvider._();

/// On-device backup-code reader; its native recognizer is closed when no
/// screen uses it any more.

final class BackupCodeScannerProvider
    extends
        $FunctionalProvider<
          BackupCodeScannerService,
          BackupCodeScannerService,
          BackupCodeScannerService
        >
    with $Provider<BackupCodeScannerService> {
  /// On-device backup-code reader; its native recognizer is closed when no
  /// screen uses it any more.
  BackupCodeScannerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupCodeScannerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupCodeScannerHash();

  @$internal
  @override
  $ProviderElement<BackupCodeScannerService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackupCodeScannerService create(Ref ref) {
    return backupCodeScanner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupCodeScannerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupCodeScannerService>(value),
    );
  }
}

String _$backupCodeScannerHash() => r'6b729879c81b4eaec08fb3c27b49f1302cece007';

/// Builds and shares one-page project PDFs (stateless).

@ProviderFor(projectPdfService)
final projectPdfServiceProvider = ProjectPdfServiceProvider._();

/// Builds and shares one-page project PDFs (stateless).

final class ProjectPdfServiceProvider
    extends
        $FunctionalProvider<
          ProjectPdfService,
          ProjectPdfService,
          ProjectPdfService
        >
    with $Provider<ProjectPdfService> {
  /// Builds and shares one-page project PDFs (stateless).
  ProjectPdfServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectPdfServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectPdfServiceHash();

  @$internal
  @override
  $ProviderElement<ProjectPdfService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProjectPdfService create(Ref ref) {
    return projectPdfService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectPdfService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProjectPdfService>(value),
    );
  }
}

String _$projectPdfServiceHash() => r'05f5503dd0211168cf5a8120c401aea637ca08b4';

/// The signed-in user's projects, newest first.
///
/// Cache-first: the SQLite copy is shown at once (also offline), live
/// server snapshots are merged into it, and local edits are written to the
/// cache immediately and uploaded in the background (newest edit wins).

@ProviderFor(ProjectNotifier)
final projectProvider = ProjectNotifierProvider._();

/// The signed-in user's projects, newest first.
///
/// Cache-first: the SQLite copy is shown at once (also offline), live
/// server snapshots are merged into it, and local edits are written to the
/// cache immediately and uploaded in the background (newest edit wins).
final class ProjectNotifierProvider
    extends $AsyncNotifierProvider<ProjectNotifier, List<ProjectModel>> {
  /// The signed-in user's projects, newest first.
  ///
  /// Cache-first: the SQLite copy is shown at once (also offline), live
  /// server snapshots are merged into it, and local edits are written to the
  /// cache immediately and uploaded in the background (newest edit wins).
  ProjectNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectNotifierHash();

  @$internal
  @override
  ProjectNotifier create() => ProjectNotifier();
}

String _$projectNotifierHash() => r'065df2f403b8be54d11a2ce5001a6c1dcc837423';

/// The signed-in user's projects, newest first.
///
/// Cache-first: the SQLite copy is shown at once (also offline), live
/// server snapshots are merged into it, and local edits are written to the
/// cache immediately and uploaded in the background (newest edit wins).

abstract class _$ProjectNotifier extends $AsyncNotifier<List<ProjectModel>> {
  FutureOr<List<ProjectModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ProjectModel>>, List<ProjectModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ProjectModel>>, List<ProjectModel>>,
              AsyncValue<List<ProjectModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
