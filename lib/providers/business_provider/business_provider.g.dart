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
    extends $NotifierProvider<BusinessNotifier, List<BusinessModel>> {
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

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<BusinessModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<BusinessModel>>(value),
    );
  }
}

String _$businessNotifierHash() => r'0bc797bf52c00579d6b10d7a5a73fd93d2612130';

abstract class _$BusinessNotifier extends $Notifier<List<BusinessModel>> {
  List<BusinessModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<BusinessModel>, List<BusinessModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<BusinessModel>, List<BusinessModel>>,
              List<BusinessModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
