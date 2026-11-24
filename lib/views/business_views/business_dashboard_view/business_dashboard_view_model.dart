import 'package:flutter_riverpod/legacy.dart';
import 'package:digital_munshi/models/sale_model.dart';

enum DashboardFilterType { all, daily, monthly, yearly }

/// Whether [date] falls in the period the dashboard is showing.
bool matchesPeriod(DateTime date, DashboardFilterType filter, DateTime selected) {
  switch (filter) {
    case DashboardFilterType.daily:
      return date.year == selected.year &&
          date.month == selected.month &&
          date.day == selected.day;
    case DashboardFilterType.monthly:
      return date.year == selected.year && date.month == selected.month;
    case DashboardFilterType.yearly:
      return date.year == selected.year;
    case DashboardFilterType.all:
      return true;
  }
}

/// Heading for the summary card's profit figure.
String periodProfitLabel(DashboardFilterType filter) {
  switch (filter) {
    case DashboardFilterType.daily:
      return "DAILY NET PROFIT";
    case DashboardFilterType.monthly:
      return "MONTHLY NET PROFIT";
    case DashboardFilterType.yearly:
      return "YEARLY NET PROFIT";
    case DashboardFilterType.all:
      return "ALL-TIME NET PROFIT";
  }
}

/// One point of the revenue trend chart.
class TrendPoint {
  /// Start of the bucket (a day or the first day of a month).
  final DateTime start;
  final double revenue;
  const TrendPoint(this.start, this.revenue);
}

/// Revenue trend buckets for the chosen period:
/// * daily   - the 7 days ending on the selected day
/// * monthly - each day of the selected month
/// * yearly  - each month of the selected year
/// * all     - each month from the first sale to the last
List<TrendPoint> revenueTrend(
  List<SaleModel> sales,
  DashboardFilterType filter,
  DateTime selected, {
  DateTime? now,
}) {
  final List<DateTime> starts;
  final bool byMonth;
  switch (filter) {
    case DashboardFilterType.daily:
      byMonth = false;
      final day = DateTime(selected.year, selected.month, selected.day);
      starts = [
        for (var i = 6; i >= 0; i--) DateTime(day.year, day.month, day.day - i),
      ];
    case DashboardFilterType.monthly:
      byMonth = false;
      final days = DateTime(selected.year, selected.month + 1, 0).day;
      starts = [
        for (var d = 1; d <= days; d++)
          DateTime(selected.year, selected.month, d),
      ];
    case DashboardFilterType.yearly:
      byMonth = true;
      starts = [for (var m = 1; m <= 12; m++) DateTime(selected.year, m)];
    case DashboardFilterType.all:
      byMonth = true;
      if (sales.isEmpty) return const [];
      var first = sales.first.dateTime;
      var last = sales.first.dateTime;
      for (final s in sales) {
        if (s.dateTime.isBefore(first)) first = s.dateTime;
        if (s.dateTime.isAfter(last)) last = s.dateTime;
      }
      starts = [];
      for (
        var m = DateTime(first.year, first.month);
        !m.isAfter(DateTime(last.year, last.month));
        m = DateTime(m.year, m.month + 1)
      ) {
        starts.add(m);
      }
  }

  // Never chart the future (e.g. the rest of the current month or year).
  final today = now ?? DateTime.now();
  final lastStart = byMonth
      ? DateTime(today.year, today.month)
      : DateTime(today.year, today.month, today.day);
  starts.removeWhere((s) => s.isAfter(lastStart));

  final totals = {for (final start in starts) start: 0.0};
  for (final sale in sales) {
    final d = sale.dateTime;
    final key = byMonth ? DateTime(d.year, d.month) : DateTime(d.year, d.month, d.day);
    if (totals.containsKey(key)) totals[key] = totals[key]! + sale.soldAtPrice;
  }
  return [for (final start in starts) TrendPoint(start, totals[start]!)];
}

/// Chart heading for the chosen period.
String trendTitle(DashboardFilterType filter) {
  switch (filter) {
    case DashboardFilterType.daily:
      return "REVENUE • LAST 7 DAYS";
    case DashboardFilterType.monthly:
      return "REVENUE • BY DAY";
    case DashboardFilterType.yearly:
    case DashboardFilterType.all:
      return "REVENUE • BY MONTH";
  }
}

class DashboardUiState {
  final bool isSearching;
  final bool isSelectionMode;
  final String searchQuery;
  final DashboardFilterType activeFilter;
  final DateTime selectedDate;
  final Set<String> selectedIds;

  DashboardUiState({
    this.isSearching = false,
    this.isSelectionMode = false,
    this.searchQuery = "",
    this.activeFilter = DashboardFilterType.daily,
    DateTime? selectedDate,
    this.selectedIds = const {},
  }) : selectedDate = selectedDate ?? DateTime.now();

  DashboardUiState copyWith({
    bool? isSearching,
    bool? isSelectionMode,
    String? searchQuery,
    DashboardFilterType? activeFilter,
    DateTime? selectedDate,
    Set<String>? selectedIds,
  }) {
    return DashboardUiState(
      isSearching: isSearching ?? this.isSearching,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class DashboardUiNotifier extends StateNotifier<DashboardUiState> {
  DashboardUiNotifier() : super(DashboardUiState());

  void toggleSearch() =>
      state = state.copyWith(isSearching: !state.isSearching, searchQuery: "");
  void updateSearch(String q) => state = state.copyWith(searchQuery: q);
  void setFilter(DashboardFilterType t) =>
      state = state.copyWith(activeFilter: t, selectedIds: {});

  void toggleSelectionMode() {
    state = state.copyWith(
      isSelectionMode: !state.isSelectionMode,
      selectedIds: {},
    );
  }

  void toggleId(String id) {
    final newIds = Set<String>.from(state.selectedIds);
    if (newIds.contains(id)) {
      newIds.remove(id);
    } else {
      newIds.add(id);
    }
    state = state.copyWith(selectedIds: newIds);
  }

  /// Steps the selected period back (-1) or forward (+1).
  ///
  /// Daily: moves to the nearest past day in [saleDays] (days with at least
  /// one sale), or forward to today, which is always reachable. Months and
  /// years step one at a time. The future is never selectable.
  void adjustDate(int offset, {Set<DateTime> saleDays = const {}}) {
    final next = steppedDate(
      state.activeFilter,
      state.selectedDate,
      offset,
      saleDays,
    );
    if (next == null) return;
    state = state.copyWith(selectedDate: next, selectedIds: {});
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Calendar days (date only) on which at least one sale was made.
Set<DateTime> saleDaysOf(Iterable<SaleModel> sales) =>
    {for (final s in sales) _dateOnly(s.dateTime)};

/// Where the ‹ / › arrows lead from [current], or null if nowhere
/// (see [DashboardUiNotifier.adjustDate]).
DateTime? steppedDate(
  DashboardFilterType filter,
  DateTime current,
  int offset,
  Set<DateTime> saleDays, {
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  switch (filter) {
    case DashboardFilterType.daily:
      final day = _dateOnly(current);
      if (offset < 0) {
        DateTime? best;
        for (final d in saleDays) {
          if (d.isBefore(day) && (best == null || d.isAfter(best))) best = d;
        }
        return best;
      }
      if (!day.isBefore(today)) return null;
      var best = today;
      for (final d in saleDays) {
        if (d.isAfter(day) && d.isBefore(best)) best = d;
      }
      return best;
    case DashboardFilterType.monthly:
      final next = DateTime(current.year, current.month + offset);
      return next.isAfter(DateTime(today.year, today.month)) ? null : next;
    case DashboardFilterType.yearly:
      final next = DateTime(current.year + offset);
      return next.year > today.year ? null : next;
    case DashboardFilterType.all:
      return null;
  }
}

/// Disposed when the dashboard closes, so filters and selections never carry
/// over from one business to another.
final dashboardUiProvider =
    StateNotifierProvider.autoDispose<DashboardUiNotifier, DashboardUiState>(
      (ref) => DashboardUiNotifier(),
    );
