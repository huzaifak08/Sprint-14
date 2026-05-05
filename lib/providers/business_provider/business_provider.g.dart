// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BusinessNotifier)
final businessProvider = BusinessNotifierProvider._();

final class BusinessNotifierProvider
    extends $AsyncNotifierProvider<BusinessNotifier, List<BusinessModel>> {
  BusinessNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'businessProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$businessNotifierHash();

  @$internal
  @override
  BusinessNotifier create() => BusinessNotifier();
}

String _$businessNotifierHash() => r'825fe57600f9a08a2f0bc90d300c0a3dfd05c411';

abstract class _$BusinessNotifier extends $AsyncNotifier<List<BusinessModel>> {
  FutureOr<List<BusinessModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<BusinessModel>>, List<BusinessModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BusinessModel>>, List<BusinessModel>>,
              AsyncValue<List<BusinessModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
