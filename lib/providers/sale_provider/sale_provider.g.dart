// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SaleNotifier)
final saleProvider = SaleNotifierFamily._();

final class SaleNotifierProvider
    extends $AsyncNotifierProvider<SaleNotifier, List<SaleModel>> {
  SaleNotifierProvider._({
    required SaleNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'saleProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$saleNotifierHash();

  @override
  String toString() {
    return r'saleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SaleNotifier create() => SaleNotifier();

  @override
  bool operator ==(Object other) {
    return other is SaleNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$saleNotifierHash() => r'93404a7bb2e14f69a6f8be6c4aef7b99e91d9047';

final class SaleNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SaleNotifier,
          AsyncValue<List<SaleModel>>,
          List<SaleModel>,
          FutureOr<List<SaleModel>>,
          String
        > {
  SaleNotifierFamily._()
    : super(
        retry: null,
        name: r'saleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  SaleNotifierProvider call(String businessId) =>
      SaleNotifierProvider._(argument: businessId, from: this);

  @override
  String toString() => r'saleProvider';
}

abstract class _$SaleNotifier extends $AsyncNotifier<List<SaleModel>> {
  late final _$args = ref.$arg as String;
  String get businessId => _$args;

  FutureOr<List<SaleModel>> build(String businessId);
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
    element.handleCreate(ref, () => build(_$args));
  }
}
