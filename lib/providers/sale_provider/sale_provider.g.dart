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
    extends $NotifierProvider<SaleNotifier, List<SaleModel>> {
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

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SaleModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SaleModel>>(value),
    );
  }
}

String _$saleNotifierHash() => r'b730fb1e988fd04d783e3974e6c5aebb2119dac1';

abstract class _$SaleNotifier extends $Notifier<List<SaleModel>> {
  List<SaleModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<SaleModel>, List<SaleModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<SaleModel>, List<SaleModel>>,
              List<SaleModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
