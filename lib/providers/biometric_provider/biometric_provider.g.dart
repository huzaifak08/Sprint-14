// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biometric_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// State = "is the app unlocked right now".
/// Lock disabled -> always true. Lock enabled -> false until verified.

@ProviderFor(SecurityNotifier)
final securityProvider = SecurityNotifierProvider._();

/// State = "is the app unlocked right now".
/// Lock disabled -> always true. Lock enabled -> false until verified.
final class SecurityNotifierProvider
    extends $AsyncNotifierProvider<SecurityNotifier, bool> {
  /// State = "is the app unlocked right now".
  /// Lock disabled -> always true. Lock enabled -> false until verified.
  SecurityNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'securityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$securityNotifierHash();

  @$internal
  @override
  SecurityNotifier create() => SecurityNotifier();
}

String _$securityNotifierHash() => r'388ead7b18d5152acb513568743c0c4e0b65a263';

/// State = "is the app unlocked right now".
/// Lock disabled -> always true. Lock enabled -> false until verified.

abstract class _$SecurityNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Whether this device can use the app lock at all.

@ProviderFor(biometricAvailable)
final biometricAvailableProvider = BiometricAvailableProvider._();

/// Whether this device can use the app lock at all.

final class BiometricAvailableProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether this device can use the app lock at all.
  BiometricAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricAvailableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricAvailableHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return biometricAvailable(ref);
  }
}

String _$biometricAvailableHash() =>
    r'f13542c442f8908121f307a18f8bb1e0dc73a281';
