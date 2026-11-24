import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:digital_munshi/models/ledger_model.dart';
import 'package:digital_munshi/providers/ledger_provider/ledger_provider.dart';

// =========================================================================
// QUERY MODEL
// =========================================================================

enum LedgerTypeFilter { all, income, expense }

enum LedgerPeriod { allTime, thisMonth, lastMonth, thisYear, custom }

enum LedgerSort { newest, oldest, highest, lowest }

extension LedgerPeriodLabel on LedgerPeriod {
  String get label => switch (this) {
    LedgerPeriod.allTime => 'All time',
    LedgerPeriod.thisMonth => 'This month',
    LedgerPeriod.lastMonth => 'Last month',
    LedgerPeriod.thisYear => 'This year',
    LedgerPeriod.custom => 'Custom',
  };
}

extension LedgerSortLabel on LedgerSort {
  String get label => switch (this) {
    LedgerSort.newest => 'Newest first',
    LedgerSort.oldest => 'Oldest first',
    LedgerSort.highest => 'Highest amount',
    LedgerSort.lowest => 'Lowest amount',
  };
}

/// Everything the user can search / filter / sort by.
class LedgerQuery {
  final String text;
  final LedgerTypeFilter type;
  final LedgerPeriod period;
  final DateTimeRange? customRange;
  final Set<String> categories;
  final Set<String> paymentMethods;
  final double? minAmount;
  final double? maxAmount;
  final LedgerSort sort;

  const LedgerQuery({
    this.text = '',
    this.type = LedgerTypeFilter.all,
    this.period = LedgerPeriod.allTime,
    this.customRange,
    this.categories = const {},
    this.paymentMethods = const {},
    this.minAmount,
    this.maxAmount,
    this.sort = LedgerSort.newest,
  });

  /// Number of active filters (search text and sort not counted).
  int get activeFilterCount =>
      (type != LedgerTypeFilter.all ? 1 : 0) +
      (period != LedgerPeriod.allTime ? 1 : 0) +
      (categories.isNotEmpty ? 1 : 0) +
      (paymentMethods.isNotEmpty ? 1 : 0) +
      (minAmount != null || maxAmount != null ? 1 : 0);

  bool get isEmpty => text.trim().isEmpty && activeFilterCount == 0;

  LedgerQuery copyWith({
    String? text,
    LedgerTypeFilter? type,
    LedgerPeriod? period,
    DateTimeRange? customRange,
    Set<String>? categories,
    Set<String>? paymentMethods,
    double? minAmount,
    double? maxAmount,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
    LedgerSort? sort,
  }) {
    return LedgerQuery(
      text: text ?? this.text,
      type: type ?? this.type,
      period: period ?? this.period,
      customRange: customRange ?? this.customRange,
      categories: categories ?? this.categories,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      sort: sort ?? this.sort,
    );
  }
}

// =========================================================================
// PURE FILTER LOGIC (unit tested)
// =========================================================================

/// Date range (inclusive start, exclusive end) for a period, or null for all.
({DateTime start, DateTime end})? periodBounds(
  LedgerPeriod period,
  DateTime now, {
  DateTimeRange? custom,
}) {
  switch (period) {
    case LedgerPeriod.allTime:
      return null;
    case LedgerPeriod.thisMonth:
      return (
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month + 1),
      );
    case LedgerPeriod.lastMonth:
      return (
        start: DateTime(now.year, now.month - 1),
        end: DateTime(now.year, now.month),
      );
    case LedgerPeriod.thisYear:
      return (start: DateTime(now.year), end: DateTime(now.year + 1));
    case LedgerPeriod.custom:
      if (custom == null) return null;
      final s = custom.start;
      final e = custom.end;
      return (
        start: DateTime(s.year, s.month, s.day),
        end: DateTime(e.year, e.month, e.day + 1),
      );
  }
}

/// Parsed search text: free-text words plus amount operators.
///
/// * `rent cash`  -> every word must match title / category / note / payment
/// * `500`        -> also matches amounts containing 500
/// * `>500`, `<2000`, `>=500`, `<=2000` -> amount range
class ParsedSearch {
  final List<String> words;
  final double? min;
  final double? max;
  const ParsedSearch(this.words, this.min, this.max);

  static final _op = RegExp(r'^(>=|<=|>|<)(\d+(?:\.\d+)?)$');

  factory ParsedSearch.parse(String text) {
    final words = <String>[];
    double? min;
    double? max;
    for (final raw in text.toLowerCase().split(RegExp(r'\s+'))) {
      if (raw.isEmpty) continue;
      final m = _op.firstMatch(raw);
      if (m != null) {
        final value = double.parse(m.group(2)!);
        final op = m.group(1)!;
        if (op.startsWith('>')) {
          min = value;
        } else {
          max = value;
        }
      } else {
        words.add(raw);
      }
    }
    return ParsedSearch(words, min, max);
  }
}

bool _matchesWord(LedgerModel l, String word) {
  if (l.title.toLowerCase().contains(word)) return true;
  if (l.category.toLowerCase().contains(word)) return true;
  if (l.paymentMethod.toLowerCase().contains(word)) return true;
  if ((l.note ?? '').toLowerCase().contains(word)) return true;
  if (word == 'income' && l.isIncome) return true;
  if (word == 'expense' && !l.isIncome) return true;
  final numeric = double.tryParse(word);
  if (numeric != null) {
    final amountText = l.amount.toStringAsFixed(
      l.amount == l.amount.roundToDouble() ? 0 : 2,
    );
    if (amountText.contains(word)) return true;
  }
  return false;
}

/// Applies [query] to [all] and returns the matching, sorted list.
List<LedgerModel> applyLedgerQuery(
  List<LedgerModel> all,
  LedgerQuery query, {
  DateTime? now,
}) {
  final bounds = periodBounds(
    query.period,
    now ?? DateTime.now(),
    custom: query.customRange,
  );
  final search = ParsedSearch.parse(query.text);
  final min = search.min ?? query.minAmount;
  final max = search.max ?? query.maxAmount;

  final result = all.where((l) {
    if (l.isDeleted) return false;
    if (query.type == LedgerTypeFilter.income && !l.isIncome) return false;
    if (query.type == LedgerTypeFilter.expense && l.isIncome) return false;
    if (bounds != null &&
        (l.dateTime.isBefore(bounds.start) ||
            !l.dateTime.isBefore(bounds.end))) {
      return false;
    }
    if (query.categories.isNotEmpty && !query.categories.contains(l.category)) {
      return false;
    }
    if (query.paymentMethods.isNotEmpty &&
        !query.paymentMethods.contains(l.paymentMethod)) {
      return false;
    }
    if (min != null && l.amount < min) return false;
    if (max != null && l.amount > max) return false;
    for (final word in search.words) {
      if (!_matchesWord(l, word)) return false;
    }
    return true;
  }).toList();

  switch (query.sort) {
    case LedgerSort.newest:
      result.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    case LedgerSort.oldest:
      result.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    case LedgerSort.highest:
      result.sort((a, b) => b.amount.compareTo(a.amount));
    case LedgerSort.lowest:
      result.sort((a, b) => a.amount.compareTo(b.amount));
  }
  return result;
}

class LedgerTotals {
  final double income;
  final double expense;
  const LedgerTotals(this.income, this.expense);
  double get net => income - expense;
}

LedgerTotals totalsOf(Iterable<LedgerModel> items) {
  double inc = 0, exp = 0;
  for (final t in items) {
    if (t.isIncome) {
      inc += t.amount;
    } else {
      exp += t.amount;
    }
  }
  return LedgerTotals(inc, exp);
}

/// One month of the cash-flow chart.
class MonthFlow {
  final DateTime month;
  final double income;
  final double expense;
  const MonthFlow(this.month, this.income, this.expense);
}

/// Income vs expense for the last [count] months (oldest first).
List<MonthFlow> monthlyFlow(
  List<LedgerModel> all, {
  int count = 6,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final months = [
    for (var i = count - 1; i >= 0; i--) DateTime(today.year, today.month - i),
  ];
  final income = {for (final m in months) m: 0.0};
  final expense = {for (final m in months) m: 0.0};

  for (final l in all) {
    if (l.isDeleted) continue;
    final key = DateTime(l.dateTime.year, l.dateTime.month);
    if (!income.containsKey(key)) continue;
    if (l.isIncome) {
      income[key] = income[key]! + l.amount;
    } else {
      expense[key] = expense[key]! + l.amount;
    }
  }
  return [for (final m in months) MonthFlow(m, income[m]!, expense[m]!)];
}

/// Expense totals per category, biggest first.
List<MapEntry<String, double>> topExpenseCategories(
  Iterable<LedgerModel> items, {
  int limit = 5,
}) {
  final map = <String, double>{};
  for (final l in items) {
    if (l.isIncome) continue;
    map[l.category] = (map[l.category] ?? 0) + l.amount;
  }
  final entries = map.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries.take(limit).toList();
}

/// Values sorted by how often they appear (most used first).
List<String> byFrequency(Iterable<String> values) {
  final counts = <String, int>{};
  for (final v in values) {
    if (v.trim().isEmpty) continue;
    counts[v] = (counts[v] ?? 0) + 1;
  }
  final keys = counts.keys.toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  return keys;
}

// =========================================================================
// STATE
// =========================================================================

class LedgerUiState {
  final LedgerQuery query;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final bool showInsights;
  final bool isSearchOpen;

  const LedgerUiState({
    this.query = const LedgerQuery(),
    this.isSelectionMode = false,
    this.selectedIds = const {},
    this.showInsights = true,
    this.isSearchOpen = false,
  });

  LedgerUiState copyWith({
    LedgerQuery? query,
    bool? isSelectionMode,
    Set<String>? selectedIds,
    bool? showInsights,
    bool? isSearchOpen,
  }) {
    return LedgerUiState(
      query: query ?? this.query,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
      showInsights: showInsights ?? this.showInsights,
      isSearchOpen: isSearchOpen ?? this.isSearchOpen,
    );
  }
}

class LedgerUiNotifier extends StateNotifier<LedgerUiState> {
  LedgerUiNotifier() : super(const LedgerUiState());

  void _setQuery(LedgerQuery q) => state = state.copyWith(query: q);

  void setText(String text) => _setQuery(state.query.copyWith(text: text));
  void setType(LedgerTypeFilter t) => _setQuery(state.query.copyWith(type: t));
  void setSort(LedgerSort s) => _setQuery(state.query.copyWith(sort: s));

  void setPeriod(LedgerPeriod p, {DateTimeRange? range}) {
    _setQuery(
      LedgerQuery(
        text: state.query.text,
        type: state.query.type,
        period: p,
        customRange: p == LedgerPeriod.custom ? range : null,
        categories: state.query.categories,
        paymentMethods: state.query.paymentMethods,
        minAmount: state.query.minAmount,
        maxAmount: state.query.maxAmount,
        sort: state.query.sort,
      ),
    );
  }

  /// Shows a single calendar month (used when tapping a chart bar).
  void showMonth(DateTime month) {
    setPeriod(
      LedgerPeriod.custom,
      range: DateTimeRange(
        start: DateTime(month.year, month.month),
        end: DateTime(month.year, month.month + 1, 0),
      ),
    );
  }

  void toggleCategory(String c) {
    final next = {...state.query.categories};
    next.contains(c) ? next.remove(c) : next.add(c);
    _setQuery(state.query.copyWith(categories: next));
  }

  /// Filters to exactly one category (used when tapping an insight row).
  void onlyCategory(String c) =>
      _setQuery(state.query.copyWith(categories: {c}));

  void togglePaymentMethod(String m) {
    final next = {...state.query.paymentMethods};
    next.contains(m) ? next.remove(m) : next.add(m);
    _setQuery(state.query.copyWith(paymentMethods: next));
  }

  void setAmountRange(double? min, double? max) {
    _setQuery(
      state.query.copyWith(
        minAmount: min,
        maxAmount: max,
        clearMinAmount: min == null,
        clearMaxAmount: max == null,
      ),
    );
  }

  /// Clears every filter but keeps the search text and sort.
  void clearFilters() =>
      _setQuery(LedgerQuery(text: state.query.text, sort: state.query.sort));

  void clearAll() => _setQuery(const LedgerQuery());

  void openSearch() => state = state.copyWith(isSearchOpen: true);

  /// Hides the search panel and clears text + filters (keeps the sort), so
  /// no hidden filter is left affecting the list.
  void closeSearch() => state = state.copyWith(
    isSearchOpen: false,
    query: LedgerQuery(sort: state.query.sort),
  );

  void toggleInsights() =>
      state = state.copyWith(showInsights: !state.showInsights);

  void toggleSelectionMode() {
    state = state.copyWith(
      isSelectionMode: !state.isSelectionMode,
      selectedIds: {},
    );
  }

  /// Long-press: enter selection mode with this item selected.
  void startSelection(String id) {
    state = state.copyWith(isSelectionMode: true, selectedIds: {id});
  }

  void toggleId(String id) {
    final next = {...state.selectedIds};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(selectedIds: next, isSelectionMode: next.isNotEmpty);
  }

  void selectAll(Iterable<String> ids) {
    state = state.copyWith(isSelectionMode: true, selectedIds: ids.toSet());
  }
}

final ledgerUiProvider = StateNotifierProvider<LedgerUiNotifier, LedgerUiState>(
  (ref) => LedgerUiNotifier(),
);

/// Filtered + sorted ledger list, recomputed only when data or query change.
final filteredLedgersProvider = Provider<List<LedgerModel>>((ref) {
  final all = ref.watch(ledgerProvider).value ?? const <LedgerModel>[];
  final query = ref.watch(ledgerUiProvider.select((s) => s.query));
  return applyLedgerQuery(all, query);
});
