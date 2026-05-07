// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProductNotifier)
final productProvider = ProductNotifierFamily._();

final class ProductNotifierProvider
    extends $AsyncNotifierProvider<ProductNotifier, List<ProductModel>> {
  ProductNotifierProvider._({
    required ProductNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productNotifierHash();

  @override
  String toString() {
    return r'productProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProductNotifier create() => ProductNotifier();

  @override
  bool operator ==(Object other) {
    return other is ProductNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productNotifierHash() => r'b25dbcecb7fa1ac7782ccb32217628d40909e126';

final class ProductNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ProductNotifier,
          AsyncValue<List<ProductModel>>,
          List<ProductModel>,
          FutureOr<List<ProductModel>>,
          String
        > {
  ProductNotifierFamily._()
    : super(
        retry: null,
        name: r'productProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ProductNotifierProvider call(String businessId) =>
      ProductNotifierProvider._(argument: businessId, from: this);

  @override
  String toString() => r'productProvider';
}

abstract class _$ProductNotifier extends $AsyncNotifier<List<ProductModel>> {
  late final _$args = ref.$arg as String;
  String get businessId => _$args;

  FutureOr<List<ProductModel>> build(String businessId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ProductModel>>, List<ProductModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ProductModel>>, List<ProductModel>>,
              AsyncValue<List<ProductModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
