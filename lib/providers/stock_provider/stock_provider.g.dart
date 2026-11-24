// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stock on hand per product (productId -> units) for a business, counting
/// sales and stock adjustments that haven't been uploaded yet.
/// Products that don't track stock ('Matching') are included but meaningless.

@ProviderFor(stockLevels)
final stockLevelsProvider = StockLevelsFamily._();

/// Stock on hand per product (productId -> units) for a business, counting
/// sales and stock adjustments that haven't been uploaded yet.
/// Products that don't track stock ('Matching') are included but meaningless.

final class StockLevelsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, double>>,
          Map<String, double>,
          FutureOr<Map<String, double>>
        >
    with
        $FutureModifier<Map<String, double>>,
        $FutureProvider<Map<String, double>> {
  /// Stock on hand per product (productId -> units) for a business, counting
  /// sales and stock adjustments that haven't been uploaded yet.
  /// Products that don't track stock ('Matching') are included but meaningless.
  StockLevelsProvider._({
    required StockLevelsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'stockLevelsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stockLevelsHash();

  @override
  String toString() {
    return r'stockLevelsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, double>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, double>> create(Ref ref) {
    final argument = this.argument as String;
    return stockLevels(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StockLevelsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stockLevelsHash() => r'd19fa7e8aac86c5c8cddf72cc9ea7b5b622e1787';

/// Stock on hand per product (productId -> units) for a business, counting
/// sales and stock adjustments that haven't been uploaded yet.
/// Products that don't track stock ('Matching') are included but meaningless.

final class StockLevelsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, double>>, String> {
  StockLevelsFamily._()
    : super(
        retry: null,
        name: r'stockLevelsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stock on hand per product (productId -> units) for a business, counting
  /// sales and stock adjustments that haven't been uploaded yet.
  /// Products that don't track stock ('Matching') are included but meaningless.

  StockLevelsProvider call(String businessId) =>
      StockLevelsProvider._(argument: businessId, from: this);

  @override
  String toString() => r'stockLevelsProvider';
}
