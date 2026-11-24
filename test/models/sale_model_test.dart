import 'package:flutter_test/flutter_test.dart';
import 'package:digital_munshi/models/sale_model.dart';

SaleItem item(
  String id, {
  String unit = 'Piece',
  double qty = 1,
  double measurement = 1,
  double cost = 100,
  double msrp = 150,
  bool tracks = true,
}) => SaleItem(
  productId: id,
  title: 'Item $id',
  unitType: unit,
  quantity: qty,
  measurement: measurement,
  unitCost: cost,
  unitMsrp: msrp,
  tracksStock: tracks,
);

SaleModel sale({
  List<SaleItem> items = const [],
  bool tracked = true,
  bool deleted = false,
  List<String>? titles,
}) => SaleModel(
  id: 's1',
  businessId: 'b1',
  productIds: items.map((i) => i.productId).toList(),
  productTitles: titles ?? items.map((i) => i.title).toList(),
  soldAtPrice: 500,
  profit: 100,
  quantity: 1,
  measurement: 1,
  dateTime: DateTime(2026, 5, 1, 10),
  items: items,
  stockTracked: tracked,
  isSynced: false,
  isDeleted: deleted,
);

void main() {
  group('SaleItem', () {
    test('linear units consume quantity × measurement', () {
      final cloth = item('a', unit: 'Meter', qty: 2, measurement: 2.5);
      expect(cloth.effectiveQuantity, 5);
      expect(cloth.totalCost, 500);
    });

    test('pieces consume their quantity only', () {
      expect(item('a', qty: 3, measurement: 9).effectiveQuantity, 3);
    });
  });

  group('stockEffects', () {
    test('sums tracked items per product', () {
      final s = sale(
        items: [
          item('a', qty: 2),
          item('b', unit: 'Gazz', qty: 1, measurement: 3),
          item('m', qty: 4, tracks: false), // Matching: unlimited
        ],
      );
      expect(s.stockEffects, {'a': 2.0, 'b': 3.0});
    });

    test('untracked (pre-stock) and deleted sales take no stock', () {
      expect(sale(items: [item('a')], tracked: false).stockEffects, isEmpty);
      expect(sale(items: [item('a')], deleted: true).stockEffects, isEmpty);
    });
  });

  group('SQLite round trip', () {
    test('keeps items, titles with commas and synced stock', () {
      final original = sale(
        items: [item('a', qty: 2), item('b', unit: 'Meter', measurement: 1.5)],
        titles: ['Lawn, 3-PC', 'Silk'],
      ).copyWith(syncedStock: {'a': 2.0}, recordedById: 'u1');

      final restored = SaleModel.fromJsonDb(original.toJsonDb());

      expect(restored.productTitles, ['Lawn, 3-PC', 'Silk']);
      expect(restored.items.length, 2);
      expect(restored.items[1].measurement, 1.5);
      expect(restored.items[1].unitType, 'Meter');
      expect(restored.syncedStock, {'a': 2.0});
      expect(restored.recordedById, 'u1');
      expect(restored.stockTracked, isTrue);
    });

    test('reads legacy comma-separated rows', () {
      final row = sale(items: [item('a')]).toJsonDb()
        ..['productIds'] = 'p1,p2'
        ..['productTitles'] = 'One,Two'
        ..remove('items')
        ..remove('syncedStock')
        ..remove('stockTracked');

      final restored = SaleModel.fromJsonDb(row);
      expect(restored.productIds, ['p1', 'p2']);
      expect(restored.productTitles, ['One', 'Two']);
      expect(restored.items, isEmpty);
      expect(restored.stockTracked, isFalse);
    });
  });

  test('quantityLabel describes the basket', () {
    expect(sale(items: [item('a', qty: 3)]).quantityLabel, '3 pcs');
    expect(
      sale(
        items: [item('a', unit: 'Meter', qty: 2, measurement: 2.5)],
      ).quantityLabel,
      '2 × 2.50 Meter',
    );
    expect(sale(items: [item('a'), item('b')]).quantityLabel, '2 items');
  });
}
