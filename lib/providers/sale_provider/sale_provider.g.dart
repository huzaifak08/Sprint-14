// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SaleNotifier)
final saleProvider = SaleNotifierProvider._();

final class SaleNotifierProvider
    extends $AsyncNotifierProvider<SaleNotifier, List<SaleModel>> {
  SaleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saleNotifierHash();

  @$internal
  @override
  SaleNotifier create() => SaleNotifier();
}

String _$saleNotifierHash() => r'dd3e808e556e45c2cb64bdf0924340dce057308c';

abstract class _$SaleNotifier extends $AsyncNotifier<List<SaleModel>> {
  FutureOr<List<SaleModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<SaleModel>>, List<SaleModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<SaleModel>>, List<SaleModel>>,
              AsyncValue<List<SaleModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
