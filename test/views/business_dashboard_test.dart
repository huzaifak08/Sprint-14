import 'package:flutter_test/flutter_test.dart';
import 'package:digital_munshi/models/sale_model.dart';
import 'package:digital_munshi/views/business_views/business_dashboard_view/business_dashboard_view_model.dart';

SaleModel sale(DateTime at, double bill) => SaleModel(
  id: '${at.toIso8601String()}-$bill',
  businessId: 'b',
  productIds: const ['p'],
  productTitles: const ['Suit'],
  soldAtPrice: bill,
  profit: 0,
  quantity: 1,
  measurement: 1,
  dateTime: at,
  isSynced: true,
  isDeleted: false,
);

void main() {
  group('matchesPeriod', () {
    final selected = DateTime(2026, 3, 15);
    test('daily / monthly / yearly / all', () {
      final sameDay = DateTime(2026, 3, 15, 23, 59);
      final sameMonth = DateTime(2026, 3, 1);
      final sameYear = DateTime(2026, 12, 31);
      final other = DateTime(2025, 3, 15);

      expect(matchesPeriod(sameDay, DashboardFilterType.daily, selected), isTrue);
      expect(matchesPeriod(sameMonth, DashboardFilterType.daily, selected), isFalse);
      expect(matchesPeriod(sameMonth, DashboardFilterType.monthly, selected), isTrue);
      expect(matchesPeriod(sameYear, DashboardFilterType.monthly, selected), isFalse);
      expect(matchesPeriod(sameYear, DashboardFilterType.yearly, selected), isTrue);
      expect(matchesPeriod(other, DashboardFilterType.yearly, selected), isFalse);
      expect(matchesPeriod(other, DashboardFilterType.all, selected), isTrue);
    });
  });

  group('revenueTrend', () {
    test('daily shows the 7 days ending on the selected day', () {
      final points = revenueTrend(
        [
          sale(DateTime(2026, 3, 15, 9), 100),
          sale(DateTime(2026, 3, 15, 18), 50),
          sale(DateTime(2026, 3, 9), 70), // the first of the 7 days
          sale(DateTime(2026, 3, 8), 999), // outside the window
        ],
        DashboardFilterType.daily,
        DateTime(2026, 3, 15),
      );
      expect(points.length, 7);
      expect(points.first.start, DateTime(2026, 3, 9));
      expect(points.first.revenue, 70);
      expect(points.last.revenue, 150);
    });

    test('monthly has one point per day of the month', () {
      final points = revenueTrend(
        [sale(DateTime(2026, 2, 10), 40)],
        DashboardFilterType.monthly,
        DateTime(2026, 2, 1),
      );
      expect(points.length, 28);
      expect(points[9].revenue, 40);
    });

    test('yearly does not merge the same weekday across weeks', () {
      // Two Mondays in different months must land in different buckets.
      final points = revenueTrend(
        [sale(DateTime(2026, 1, 5), 10), sale(DateTime(2026, 2, 2), 20)],
        DashboardFilterType.yearly,
        DateTime(2026, 6, 1),
        now: DateTime(2027, 1, 1),
      );
      expect(points.length, 12);
      expect(points[0].revenue, 10);
      expect(points[1].revenue, 20);
    });

    test('never charts the future', () {
      final now = DateTime(2026, 3, 10, 15);
      final monthly = revenueTrend(
        const [],
        DashboardFilterType.monthly,
        DateTime(2026, 3, 1),
        now: now,
      );
      expect(monthly.length, 10);
      expect(monthly.last.start, DateTime(2026, 3, 10));

      final yearly = revenueTrend(
        const [],
        DashboardFilterType.yearly,
        DateTime(2026, 1, 1),
        now: now,
      );
      expect(yearly.length, 3);
    });
  });

  group('steppedDate', () {
    final now = DateTime(2026, 3, 20, 10);
    final saleDays = {
      DateTime(2026, 3, 2),
      DateTime(2026, 3, 12),
      DateTime(2026, 3, 22), // future, ignored going forward past today
    };
    DateTime? step(DashboardFilterType f, DateTime from, int offset) =>
        steppedDate(f, from, offset, saleDays, now: now);

    test('daily back skips days without sales', () {
      expect(step(DashboardFilterType.daily, DateTime(2026, 3, 20), -1),
          DateTime(2026, 3, 12));
      expect(step(DashboardFilterType.daily, DateTime(2026, 3, 12), -1),
          DateTime(2026, 3, 2));
      expect(step(DashboardFilterType.daily, DateTime(2026, 3, 2), -1), isNull);
    });

    test('daily forward goes to the next sale day, then today, never past', () {
      expect(step(DashboardFilterType.daily, DateTime(2026, 3, 2), 1),
          DateTime(2026, 3, 12));
      expect(step(DashboardFilterType.daily, DateTime(2026, 3, 12), 1),
          DateTime(2026, 3, 20));
      expect(step(DashboardFilterType.daily, DateTime(2026, 3, 20), 1), isNull);
    });

    test('monthly and yearly stop at the current period', () {
      expect(step(DashboardFilterType.monthly, DateTime(2026, 2), 1),
          DateTime(2026, 3));
      expect(step(DashboardFilterType.monthly, DateTime(2026, 3), 1), isNull);
      expect(step(DashboardFilterType.yearly, DateTime(2026), 1), isNull);
      expect(step(DashboardFilterType.yearly, DateTime(2026), -1),
          DateTime(2025));
    });

    test('all spans first to last sale month', () {
      final points = revenueTrend(
        [sale(DateTime(2025, 11, 3), 5), sale(DateTime(2026, 1, 20), 7)],
        DashboardFilterType.all,
        DateTime(2026, 1, 1),
      );
      expect(points.map((p) => p.start), [
        DateTime(2025, 11),
        DateTime(2025, 12),
        DateTime(2026, 1),
      ]);
      expect(points.map((p) => p.revenue), [5, 0, 7]);
    });
  });
}
