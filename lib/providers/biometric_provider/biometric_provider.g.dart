// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biometric_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SecurityNotifier)
final securityProvider = SecurityNotifierProvider._();

final class SecurityNotifierProvider
    extends $AsyncNotifierProvider<SecurityNotifier, bool> {
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

String _$securityNotifierHash() => r'6aba44afd2b6995be550b9cce040da90a9dbbf12';

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
