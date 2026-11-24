import 'package:flutter_test/flutter_test.dart';
import 'package:digital_munshi/helpers/number_input.dart';
import 'package:digital_munshi/helpers/stock_ledger.dart';
import 'package:digital_munshi/models/product_model.dart';
import 'package:digital_munshi/models/sale_model.dart';

ProductModel product({double stock = 10, double pending = 0}) => ProductModel(
  id: 'p',
  businessId: 'b',
  title: 'Suit',
  isTheya: false,
  classification: 'Fixed',
  retailPrice: 100,
  msrpPrice: 150,
  unitType: 'Piece',
  currentStock: stock,
  pendingStockDelta: pending,
  isSynced: true,
  isDeleted: false,
);

SaleModel sale(
  String id,
  double qty, {
  Map<String, double> synced = const {},
  bool deleted = false,
}) => SaleModel(
  id: id,
  businessId: 'b',
  productIds: const ['p'],
  productTitles: const ['Suit'],
  soldAtPrice: 150,
  profit: 50,
  quantity: qty,
  measurement: 1,
  dateTime: DateTime(2026, 1, 1),
  items: [
    SaleItem(
      productId: 'p',
      title: 'Suit',
      unitType: 'Piece',
      quantity: qty,
      measurement: 1,
      unitCost: 100,
      unitMsrp: 150,
      tracksStock: true,
    ),
  ],
  stockTracked: true,
  syncedStock: synced,
  isSynced: false,
  isDeleted: deleted,
);

void main() {
  test('new unsynced sale takes its full quantity', () {
    expect(pendingStockUse([sale('s', 3)]), {'p': 3.0});
  });

  test('edited sale only counts the difference from the cloud', () {
    // Cloud already has 3 taken; edited down to 2 gives one back.
    expect(pendingStockUse([sale('s', 2, synced: {'p': 3})]), {'p': -1.0});
  });

  test('deleted sale returns what the cloud took', () {
    expect(
      pendingStockUse([sale('s', 3, synced: {'p': 3}, deleted: true)]),
      {'p': -3.0},
    );
  });

  test('unchanged synced figures cancel out', () {
    expect(pendingStockUse([sale('s', 3, synced: {'p': 3})]), isEmpty);
  });

  test('available stock adds pending adjustments and subtracts pending sales',
      () {
    final use = pendingStockUse([sale('a', 2), sale('b', 1)]);
    expect(availableStock(product(stock: 10, pending: 5), use), 12);
  });

  test('stockDelta leaves out unchanged products', () {
    expect(
      stockDelta({'a': 1, 'b': 2}, {'a': 1, 'b': 5, 'c': 1}),
      {'b': 3.0, 'c': 1.0},
    );
  });

  group('availability', () {
    test('fixed products leave the picker when out of stock', () {
      expect(product().isAvailableForSale(0), isFalse);
      expect(product().isAvailableForSale(1), isTrue);
    });

    test('open and matching products stay listed', () {
      final open = product().copyWith(classification: 'Open');
      final matching = product().copyWith(classification: 'Matching');
      expect(open.isAvailableForSale(0), isTrue);
      expect(matching.isAvailableForSale(0), isTrue);
      expect(matching.tracksStock, isFalse);
    });
  });

  group('parseAmount', () {
    test('accepts separators and spaces', () {
      expect(parseAmount('12,000'), 12000);
      expect(parseAmount(' 1 500.5 '), 1500.5);
    });

    test('rejects junk', () {
      expect(parseAmount(''), isNull);
      expect(parseAmount('.'), isNull);
      expect(parseAmount('abc'), isNull);
    });
  });
}
