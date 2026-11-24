import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_munshi/models/ledger_model.dart';
import 'package:digital_munshi/views/ledger_view/ledger_view_model.dart';

LedgerModel l(
  String id,
  String title,
  double amount, {
  bool income = false,
  String category = 'Food',
  String method = 'Cash',
  String? note,
  DateTime? at,
}) {
  return LedgerModel(
    id: id,
    title: title,
    amount: amount,
    category: category,
    isIncome: income,
    note: note,
    paymentMethod: method,
    isSynced: true,
    isDeleted: false,
    dateTime: at ?? DateTime(2026, 11, 10),
  );
}

void main() {
  final now = DateTime(2026, 11, 21);
  final data = [
    l(
      '1',
      'Petrol Shell',
      3000,
      category: 'Fuel',
      method: 'Card',
      at: DateTime(2026, 11, 5),
    ),
    l('2', 'Lunch', 450, note: 'with Ali', at: DateTime(2026, 11, 20)),
    l(
      '3',
      'Salary',
      150000,
      income: true,
      category: 'Salary',
      method: 'Bank',
      at: DateTime(2026, 11, 1),
    ),
    l('4', 'Groceries', 5200, category: 'Shopping', at: DateTime(2026, 10, 15)),
    l('5', 'Fuel top-up', 2500, category: 'Fuel', at: DateTime(2025, 12, 31)),
  ];

  List<String> ids(LedgerQuery q) =>
      applyLedgerQuery(data, q, now: now).map((e) => e.id!).toList();

  test('words must all match across title/category/note/method', () {
    expect(ids(const LedgerQuery(text: 'fuel')), ['1', '5']);
    expect(ids(const LedgerQuery(text: 'fuel card')), ['1']);
    expect(ids(const LedgerQuery(text: 'ali')), ['2']); // from note
  });

  test('number matches amount, operators set a range', () {
    expect(ids(const LedgerQuery(text: '450')), ['2']);
    expect(ids(const LedgerQuery(text: '>3000')), ['1', '3', '4']);
    expect(ids(const LedgerQuery(text: '>1000 <4000')), ['1', '5']);
  });

  test('type, period, category, method and amount filters', () {
    expect(ids(const LedgerQuery(type: LedgerTypeFilter.income)), ['3']);
    expect(ids(const LedgerQuery(period: LedgerPeriod.thisMonth)), [
      '2',
      '1',
      '3',
    ]);
    expect(ids(const LedgerQuery(period: LedgerPeriod.lastMonth)), ['4']);
    expect(ids(const LedgerQuery(categories: {'Fuel'})), ['1', '5']);
    expect(ids(const LedgerQuery(paymentMethods: {'Bank'})), ['3']);
    expect(ids(const LedgerQuery(minAmount: 2600, maxAmount: 6000)), [
      '1',
      '4',
    ]);
    expect(
      ids(
        LedgerQuery(
          period: LedgerPeriod.custom,
          customRange: DateTimeRange(
            start: DateTime(2025, 12, 31),
            end: DateTime(2026, 11, 1),
          ),
        ),
      ),
      ['3', '4', '5'],
    );
  });

  test('sorting', () {
    expect(ids(const LedgerQuery(sort: LedgerSort.highest)).first, '3');
    expect(ids(const LedgerQuery(sort: LedgerSort.lowest)).first, '2');
    expect(ids(const LedgerQuery(sort: LedgerSort.oldest)).first, '5');
  });

  test('monthly flow covers the last 6 months', () {
    final flow = monthlyFlow(data, now: now);
    expect(flow.length, 6);
    expect(flow.last.month, DateTime(2026, 11));
    expect(flow.last.income, 150000);
    expect(flow.last.expense, 3450);
    expect(flow[4].expense, 5200);
  });

  test('top expense categories ignore income', () {
    final top = topExpenseCategories(data);
    expect(top.first.key, 'Fuel');
    expect(top.first.value, 5500);
    expect(top.any((e) => e.key == 'Salary'), isFalse);
  });

  test('active filter count', () {
    const q = LedgerQuery(
      type: LedgerTypeFilter.expense,
      categories: {'Fuel'},
      minAmount: 10,
      text: 'x',
    );
    expect(q.activeFilterCount, 3);
  });
}
