// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Global session state: the signed-in Firebase user, or null.
///
/// It never holds an error: sign-in / sign-up failures are thrown to the
/// calling screen as [AuthFailure]. (Putting errors in this shared state made
/// every screen listening to it react, e.g. duplicate snackbars.)

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// Global session state: the signed-in Firebase user, or null.
///
/// It never holds an error: sign-in / sign-up failures are thrown to the
/// calling screen as [AuthFailure]. (Putting errors in this shared state made
/// every screen listening to it react, e.g. duplicate snackbars.)
final class AuthControllerProvider
    extends $AsyncNotifierProvider<AuthController, User?> {
  /// Global session state: the signed-in Firebase user, or null.
  ///
  /// It never holds an error: sign-in / sign-up failures are thrown to the
  /// calling screen as [AuthFailure]. (Putting errors in this shared state made
  /// every screen listening to it react, e.g. duplicate snackbars.)
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();
}

String _$authControllerHash() => r'685d08bcb46d2ddba466643607764d79376fc735';

/// Global session state: the signed-in Firebase user, or null.
///
/// It never holds an error: sign-in / sign-up failures are thrown to the
/// calling screen as [AuthFailure]. (Putting errors in this shared state made
/// every screen listening to it react, e.g. duplicate snackbars.)

abstract class _$AuthController extends $AsyncNotifier<User?> {
  FutureOr<User?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<User?>, User?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<User?>, User?>,
              AsyncValue<User?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
