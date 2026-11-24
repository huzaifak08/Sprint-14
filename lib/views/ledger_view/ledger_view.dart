import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:digital_munshi/helpers/constants.dart';
import 'package:digital_munshi/helpers/theme_widgets.dart';
import 'package:digital_munshi/models/ledger_model.dart';
import 'package:digital_munshi/providers/ledger_provider/ledger_provider.dart';
import 'package:digital_munshi/views/add_or_update_ledger_view.dart';

import 'ledger_view_model.dart';

final _money = NumberFormat('#,##0.##');
String _fmt(double v) => _money.format(v);

const _incomeColor = Color(0xFF2E9E5B);
const _expenseColor = Color(0xFFE5484D);

Color _categoryColor(String category) {
  final known = categoryColors[category];
  if (known != null) return known;
  final palette = Colors.primaries;
  return palette[category.hashCode.abs() % palette.length];
}

class LedgerView extends ConsumerWidget {
  const LedgerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgersAsync = ref.watch(ledgerProvider);

    return ledgersAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
        body: Center(child: Text("Error loading transactions: $err")),
      ),
      data: (all) {
        if (all.isEmpty) return const _EmptyLedgerState();
        return const _LedgerBody();
      },
    );
  }
}

// =========================================================================
// BODY
// =========================================================================

class _LedgerBody extends ConsumerStatefulWidget {
  const _LedgerBody();

  @override
  ConsumerState<_LedgerBody> createState() => _LedgerBodyState();
}

class _LedgerBodyState extends ConsumerState<_LedgerBody> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(ledgerUiProvider).query.text;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      ref.read(ledgerUiProvider.notifier).setText(value);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    ref.read(ledgerUiProvider.notifier).setText('');
  }

  void _openSearch() {
    ref.read(ledgerUiProvider.notifier).openSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _debounce?.cancel();
    _searchController.clear();
    _searchFocus.unfocus();
    ref.read(ledgerUiProvider.notifier).closeSearch();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredLedgersProvider);
    final query = ref.watch(ledgerUiProvider.select((s) => s.query));
    final showInsights = ref.watch(
      ledgerUiProvider.select((s) => s.showInsights),
    );
    final isSelectionMode = ref.watch(
      ledgerUiProvider.select((s) => s.isSelectionMode),
    );
    final isSearchOpen = ref.watch(
      ledgerUiProvider.select((s) => s.isSearchOpen),
    );
    // Also show the panel when a filter is active (e.g. set by tapping a
    // chart bar), so no filter is ever applied without being visible.
    final searchVisible = isSearchOpen || !query.isEmpty;

    // Day headers only make sense when sorted by date.
    final groupByDay =
        query.sort == LedgerSort.newest || query.sort == LedgerSort.oldest;
    final rows = _buildRows(filtered, groupByDay);

    return Scaffold(
      body: GestureDetector(
        onTap: () => _searchFocus.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: RefreshIndicator(
          onRefresh: () => ref.read(ledgerProvider.notifier).forceRefresh(),
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHeaderDelegate(
                  height: searchVisible ? 116 : 52,
                  child: searchVisible
                      ? _SearchAndChips(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: _onSearchChanged,
                          onClear: _clearSearch,
                          onClose: _closeSearch,
                        )
                      : _CollapsedHeader(onSearch: _openSearch),
                ),
              ),
              // In select mode the totals bar sticks under the header, so the
              // selected total stays visible while scrolling and selecting.
              if (isSelectionMode)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedHeaderDelegate(
                    height: 72,
                    child: const _ResultsBar(),
                  ),
                )
              else
                const SliverToBoxAdapter(child: _ResultsBar()),
              if (showInsights && query.text.trim().isEmpty)
                const SliverToBoxAdapter(child: _InsightsCard()),
              if (!showInsights && query.text.trim().isEmpty)
                const SliverToBoxAdapter(child: _InsightsCollapsed()),
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NoResults(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                  sliver: SliverList.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      if (row is _DayHeaderRow) {
                        return _DayHeader(row: row);
                      }
                      return _LedgerTile(
                        ledger: (row as _ItemRow).ledger,
                        searchText: query.text,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Object> _buildRows(List<LedgerModel> items, bool groupByDay) {
    if (!groupByDay) return [for (final l in items) _ItemRow(l)];

    final rows = <Object>[];
    DateTime? currentDay;
    _DayHeaderRow? header;
    for (final l in items) {
      final day = DateTime(l.dateTime.year, l.dateTime.month, l.dateTime.day);
      if (day != currentDay) {
        currentDay = day;
        header = _DayHeaderRow(day);
        rows.add(header);
      }
      header!.add(l);
      rows.add(_ItemRow(l));
    }
    return rows;
  }
}

class _ItemRow {
  final LedgerModel ledger;
  const _ItemRow(this.ledger);
}

class _DayHeaderRow {
  final DateTime day;
  double income = 0;
  double expense = 0;
  _DayHeaderRow(this.day);

  void add(LedgerModel l) {
    if (l.isIncome) {
      income += l.amount;
    } else {
      expense += l.amount;
    }
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _PinnedHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent || shrinkOffset > 0 ? 1 : 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_PinnedHeaderDelegate old) =>
      old.child != child || old.height != height;
}

// =========================================================================
// SEARCH + QUICK FILTER CHIPS
// =========================================================================

class _SearchAndChips extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onClose;

  const _SearchAndChips({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filterCount = ref.watch(
      ledgerUiProvider.select((s) => s.query.activeFilterCount),
    );
    final sort = ref.watch(ledgerUiProvider.select((s) => s.query.sort));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) => TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search title, note, category, 500, >1000…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: value.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: onClear,
                            ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<LedgerSort>(
                tooltip: 'Sort',
                initialValue: sort,
                icon: const Icon(Icons.swap_vert_rounded),
                onSelected: (s) =>
                    ref.read(ledgerUiProvider.notifier).setSort(s),
                itemBuilder: (_) => [
                  for (final s in LedgerSort.values)
                    CheckedPopupMenuItem(
                      value: s,
                      checked: s == sort,
                      child: Text(s.label),
                    ),
                ],
              ),
              Badge(
                isLabelVisible: filterCount > 0,
                label: Text('$filterCount'),
                backgroundColor: theme.colorScheme.primary,
                textColor: theme.colorScheme.onPrimary,
                child: IconButton(
                  tooltip: 'Filters',
                  icon: const Icon(Icons.tune_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  onPressed: () => _showFilterSheet(context),
                ),
              ),
              IconButton(
                tooltip: 'Hide search',
                icon: const Icon(Icons.expand_less_rounded),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 40, child: _QuickChips()),
        ],
      ),
    );
  }
}

/// Compact header shown while search is hidden: just a search icon.
class _CollapsedHeader extends StatelessWidget {
  final VoidCallback onSearch;
  const _CollapsedHeader({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          const Text(
            'Transactions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Search & filter',
            icon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
            onPressed: onSearch,
          ),
        ],
      ),
    );
  }
}

class _QuickChips extends ConsumerWidget {
  const _QuickChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(ledgerUiProvider.select((s) => s.query));
    final notifier = ref.read(ledgerUiProvider.notifier);
    final all = ref.watch(ledgerProvider).value ?? const <LedgerModel>[];
    final topCategories = byFrequency(all.map((l) => l.category)).take(8);

    Widget chip(String label, bool selected, VoidCallback onTap, {Color? dot}) {
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          avatar: dot == null
              ? null
              : CircleAvatar(backgroundColor: dot, radius: 5),
          visualDensity: VisualDensity.compact,
          onSelected: (_) => onTap(),
        ),
      );
    }

    final customLabel =
        query.period == LedgerPeriod.custom && query.customRange != null
        ? _rangeLabel(query.customRange!)
        : 'Pick dates';

    return ChipTheme(
      data: themedChips(Theme.of(context)),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (query.activeFilterCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                avatar: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('Clear'),
                visualDensity: VisualDensity.compact,
                onPressed: notifier.clearFilters,
              ),
            ),
          chip(
            'Income',
            query.type == LedgerTypeFilter.income,
            () => notifier.setType(
              query.type == LedgerTypeFilter.income
                  ? LedgerTypeFilter.all
                  : LedgerTypeFilter.income,
            ),
            dot: _incomeColor,
          ),
          chip(
            'Expense',
            query.type == LedgerTypeFilter.expense,
            () => notifier.setType(
              query.type == LedgerTypeFilter.expense
                  ? LedgerTypeFilter.all
                  : LedgerTypeFilter.expense,
            ),
            dot: _expenseColor,
          ),
          for (final p in [
            LedgerPeriod.thisMonth,
            LedgerPeriod.lastMonth,
            LedgerPeriod.thisYear,
          ])
            chip(
              p.label,
              query.period == p,
              () => notifier.setPeriod(
                query.period == p ? LedgerPeriod.allTime : p,
              ),
            ),
          chip(customLabel, query.period == LedgerPeriod.custom, () async {
            if (query.period == LedgerPeriod.custom) {
              notifier.setPeriod(LedgerPeriod.allTime);
              return;
            }
            final range = await _pickRange(context, query.customRange);
            if (range != null) {
              notifier.setPeriod(LedgerPeriod.custom, range: range);
            }
          }),
          for (final c in topCategories)
            chip(
              c,
              query.categories.contains(c),
              () => notifier.toggleCategory(c),
              dot: _categoryColor(c),
            ),
        ],
      ),
    );
  }
}

String _rangeLabel(DateTimeRange r) {
  final sameYear = r.start.year == r.end.year;
  final f = DateFormat(sameYear ? 'd MMM' : 'd MMM yy');
  if (r.start.year == r.end.year &&
      r.start.month == r.end.month &&
      r.start.day == 1 &&
      DateTime(r.end.year, r.end.month + 1, 0).day == r.end.day) {
    return DateFormat('MMMM yyyy').format(r.start);
  }
  return '${f.format(r.start)} – ${f.format(r.end)}';
}

Future<DateTimeRange?> _pickRange(
  BuildContext context,
  DateTimeRange? initial,
) {
  final now = DateTime.now();
  return showDateRangePicker(
    context: context,
    firstDate: DateTime(2000),
    lastDate: DateTime(now.year + 5),
    initialDateRange: initial,
    helpText: 'Show transactions between',
  );
}

// =========================================================================
// RESULTS BAR (live totals / selection calculator)
// =========================================================================

class _ResultsBar extends ConsumerWidget {
  const _ResultsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filtered = ref.watch(filteredLedgersProvider);
    final isSel = ref.watch(ledgerUiProvider.select((s) => s.isSelectionMode));
    final selIds = ref.watch(ledgerUiProvider.select((s) => s.selectedIds));
    final notifier = ref.read(ledgerUiProvider.notifier);

    if (isSel) {
      final selected = filtered.where((l) => selIds.contains(l.id));
      final t = totalsOf(selected);
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selIds.length} selected',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'In ${_fmt(t.income)} · Out ${_fmt(t.expense)} · Net ${_fmt(t.net)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => notifier.selectAll(
                filtered.map((l) => l.id).whereType<String>(),
              ),
              child: const Text('All'),
            ),
            IconButton(
              tooltip: 'Done',
              icon: const Icon(Icons.close_rounded),
              onPressed: notifier.toggleSelectionMode,
            ),
          ],
        ),
      );
    }

    final t = totalsOf(filtered);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _stat('Income', t.income, _incomeColor),
          _stat('Expense', t.expense, _expenseColor),
          _stat(
            'Net',
            t.net,
            t.net >= 0 ? theme.colorScheme.primary : _expenseColor,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${filtered.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                filtered.length == 1 ? 'result' : 'results',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Select to add up',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.calculate_outlined),
            onPressed: notifier.toggleSelectionMode,
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, double value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _fmt(value),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// INSIGHTS (replaces the pie chart)
// =========================================================================

class _InsightsCollapsed extends ConsumerWidget {
  const _InsightsCollapsed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton.icon(
        onPressed: ref.read(ledgerUiProvider.notifier).toggleInsights,
        icon: const Icon(Icons.insights_rounded, size: 18),
        label: const Text('Show insights'),
      ),
    );
  }
}

class _InsightsCard extends ConsumerWidget {
  const _InsightsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final all = ref.watch(ledgerProvider).value ?? const <LedgerModel>[];
    final filtered = ref.watch(filteredLedgersProvider);
    final query = ref.watch(ledgerUiProvider.select((s) => s.query));
    final notifier = ref.read(ledgerUiProvider.notifier);

    final flow = monthlyFlow(all);
    final thisMonth = flow.last;
    final lastMonth = flow[flow.length - 2];
    final top = topExpenseCategories(filtered);
    final topTotal = top.fold<double>(0, (s, e) => s + e.value);

    // Month comparison sentence.
    String compare;
    Color compareColor;
    IconData compareIcon;
    if (lastMonth.expense == 0) {
      compare = 'No spending last month to compare';
      compareColor = theme.hintColor;
      compareIcon = Icons.remove_rounded;
    } else {
      final change =
          (thisMonth.expense - lastMonth.expense) / lastMonth.expense * 100;
      final up = change >= 0;
      compare =
          '${change.abs().toStringAsFixed(0)}% ${up ? 'more' : 'less'} than last month so far';
      compareColor = up ? _expenseColor : _incomeColor;
      compareIcon = up
          ? Icons.trending_up_rounded
          : Icons.trending_down_rounded;
    }

    // Highlight the bar of the month currently filtered (if any).
    int? selectedBar;
    final range = query.customRange;
    if (query.period == LedgerPeriod.custom && range != null) {
      selectedBar = flow.indexWhere(
        (m) =>
            m.month.year == range.start.year &&
            m.month.month == range.start.month,
      );
    } else if (query.period == LedgerPeriod.thisMonth) {
      selectedBar = flow.length - 1;
    } else if (query.period == LedgerPeriod.lastMonth) {
      selectedBar = flow.length - 2;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Insights',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Hide insights',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.expand_less_rounded),
                onPressed: notifier.toggleInsights,
              ),
            ],
          ),
          Text(
            'Spent ${_fmt(thisMonth.expense)} this month',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(compareIcon, size: 16, color: compareColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  compare,
                  style: TextStyle(fontSize: 12, color: compareColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _legendDot(_incomeColor, 'Income'),
              const SizedBox(width: 12),
              _legendDot(_expenseColor, 'Expense'),
              const Spacer(),
              Text(
                'Tap a month to filter',
                style: TextStyle(fontSize: 11, color: theme.hintColor),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 120,
            child: _CashFlowChart(
              flow: flow,
              selectedIndex: selectedBar,
              onMonthTap: (m) {
                final isSame = selectedBar != null && flow[selectedBar] == m;
                if (isSame) {
                  notifier.setPeriod(LedgerPeriod.allTime);
                } else {
                  notifier.showMonth(m.month);
                }
              },
            ),
          ),
          if (top.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? 'Top spending categories'
                  : 'Top spending in these results',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            for (final e in top)
              _CategoryBar(
                category: e.key,
                amount: e.value,
                share: topTotal == 0 ? 0 : e.value / topTotal,
                selected: query.categories.contains(e.key),
                onTap: () =>
                    query.categories.length == 1 &&
                        query.categories.contains(e.key)
                    ? notifier.toggleCategory(e.key)
                    : notifier.onlyCategory(e.key),
              ),
          ],
        ],
      ),
    );
  }

  Widget _legendDot(Color c, String label) => Row(
    children: [
      CircleAvatar(radius: 4, backgroundColor: c),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}

class _CashFlowChart extends StatelessWidget {
  final List<MonthFlow> flow;
  final int? selectedIndex;
  final ValueChanged<MonthFlow> onMonthTap;

  const _CashFlowChart({
    required this.flow,
    required this.selectedIndex,
    required this.onMonthTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = flow.fold<double>(
      0,
      (m, f) => [m, f.income, f.expense].reduce((a, b) => a > b ? a : b),
    );

    final chartMax = maxY == 0 ? 1.0 : maxY;
    // Small but non-zero amounts get a minimum height so they stay visible
    // next to a much bigger month (e.g. salary).
    double visible(double v) =>
        v <= 0 ? 0 : (v < chartMax * 0.03 ? chartMax * 0.03 : v);
    final track = BackgroundBarChartRodData(
      show: true,
      toY: chartMax,
      color: theme.colorScheme.primary.withValues(alpha: 0.06),
    );

    return BarChart(
      BarChartData(
        // No extra headroom: the tallest bar reaches the top of the chart.
        maxY: chartMax,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= flow.length) return const SizedBox.shrink();
                final selected = i == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('MMM').format(flow[i].month),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: selected ? theme.colorScheme.primary : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final f = flow[groupIndex];
              return BarTooltipItem(
                '${DateFormat('MMM yyyy').format(f.month)}\n'
                'In ${_fmt(f.income)}\nOut ${_fmt(f.expense)}',
                TextStyle(
                  color: theme.colorScheme.onInverseSurface,
                  fontSize: 11,
                ),
              );
            },
          ),
          touchCallback: (event, response) {
            if (event is! FlTapUpEvent) return;
            final index = response?.spot?.touchedBarGroupIndex;
            if (index != null && index >= 0 && index < flow.length) {
              onMonthTap(flow[index]);
            }
          },
        ),
        barGroups: [
          for (var i = 0; i < flow.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                BarChartRodData(
                  toY: visible(flow[i].income),
                  width: 9,
                  backDrawRodData: track,
                  color: _incomeColor.withValues(
                    alpha: selectedIndex == null || selectedIndex == i
                        ? 1
                        : 0.35,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: visible(flow[i].expense),
                  width: 9,
                  backDrawRodData: track,
                  color: _expenseColor.withValues(
                    alpha: selectedIndex == null || selectedIndex == i
                        ? 1
                        : 0.35,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String category;
  final double amount;
  final double share;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryBar({
    required this.category,
    required this.amount,
    required this.share,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _categoryColor(category);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 84,
              child: Text(
                category,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: share,
                  minHeight: 8,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: Text(
                _fmt(amount),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '${(share * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11, color: theme.hintColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// LIST
// =========================================================================

class _DayHeader extends StatelessWidget {
  final _DayHeaderRow row;
  const _DayHeader({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final String label;
    if (row.day == today) {
      label = 'Today';
    } else if (row.day == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else if (row.day.year == now.year) {
      label = DateFormat('EEE, d MMM').format(row.day);
    } else {
      label = DateFormat('EEE, d MMM yyyy').format(row.day);
    }
    final net = row.income - row.expense;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const Spacer(),
          Text(
            '${net >= 0 ? '+' : '−'}${_fmt(net.abs())}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerTile extends ConsumerWidget {
  final LedgerModel ledger;
  final String searchText;

  const _LedgerTile({required this.ledger, required this.searchText});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final id = ledger.id;
    final isSel = ref.watch(ledgerUiProvider.select((s) => s.isSelectionMode));
    final selected = ref.watch(
      ledgerUiProvider.select((s) => s.selectedIds.contains(id)),
    );
    final notifier = ref.read(ledgerUiProvider.notifier);
    final color = _categoryColor(ledger.category);
    final words = ParsedSearch.parse(searchText).words;

    final subtitleParts = [
      ledger.category,
      ledger.paymentMethod,
      DateFormat('d MMM, h:mm a').format(ledger.dateTime),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (id == null) return;
          if (isSel) {
            notifier.toggleId(id);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddOrUpdateLedgerView(ledger: ledger),
              ),
            );
          }
        },
        onLongPress: id == null ? null : () => notifier.startSelection(id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (isSel)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.hintColor,
                  ),
                ),
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(
                  ledger.category.isEmpty
                      ? '?'
                      : ledger.category.characters.first.toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightText(
                      text: ledger.title,
                      words: words,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                    if ((ledger.note ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      _HighlightText(
                        text: ledger.note!.trim(),
                        words: words,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${ledger.isIncome ? '+' : '−'}${_fmt(ledger.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: ledger.isIncome ? _incomeColor : _expenseColor,
                    ),
                  ),
                  if (!ledger.isSynced)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.cloud_off_rounded,
                        size: 14,
                        color: theme.hintColor,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single-line text with every occurrence of the search words highlighted.
class _HighlightText extends StatelessWidget {
  final String text;
  final List<String> words;
  final TextStyle style;

  const _HighlightText({
    required this.text,
    required this.words,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final terms = words.where((w) => double.tryParse(w) == null).toList();
    if (terms.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lower = text.toLowerCase();
    final marks = List<bool>.filled(text.length, false);
    for (final t in terms) {
      var start = lower.indexOf(t);
      while (start != -1) {
        for (var i = start; i < start + t.length && i < text.length; i++) {
          marks[i] = true;
        }
        start = lower.indexOf(t, start + t.length);
      }
    }

    final highlight = style.copyWith(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.2),
      fontWeight: FontWeight.bold,
    );
    final spans = <TextSpan>[];
    var i = 0;
    while (i < text.length) {
      final mark = marks[i];
      var j = i;
      while (j < text.length && marks[j] == mark) {
        j++;
      }
      spans.add(
        TextSpan(text: text.substring(i, j), style: mark ? highlight : style),
      );
      i = j;
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _NoResults extends ConsumerWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: theme.hintColor),
          const SizedBox(height: 12),
          const Text(
            'No matching transactions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Try fewer words or clear some filters.',
            style: TextStyle(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: ref.read(ledgerUiProvider.notifier).clearFilters,
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// FULL FILTER SHEET
// =========================================================================

void _showFilterSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late final TextEditingController _min;
  late final TextEditingController _max;

  @override
  void initState() {
    super.initState();
    final q = ref.read(ledgerUiProvider).query;
    _min = TextEditingController(text: q.minAmount?.toStringAsFixed(0) ?? '');
    _max = TextEditingController(text: q.maxAmount?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _applyAmounts() {
    ref
        .read(ledgerUiProvider.notifier)
        .setAmountRange(double.tryParse(_min.text), double.tryParse(_max.text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = ref.watch(ledgerUiProvider.select((s) => s.query));
    final resultCount = ref.watch(filteredLedgersProvider).length;
    final notifier = ref.read(ledgerUiProvider.notifier);
    final all = ref.watch(ledgerProvider).value ?? const <LedgerModel>[];
    final categories = byFrequency(all.map((l) => l.category));
    final methods = byFrequency(all.map((l) => l.paymentMethod));

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          Expanded(
            child: ChipTheme(
              data: themedChips(theme),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  Text(
                    'Filters',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  section(
                    'Type',
                    SegmentedButton<LedgerTypeFilter>(
                      showSelectedIcon: false,
                      style: themedSegments(theme),
                      segments: const [
                        ButtonSegment(
                          value: LedgerTypeFilter.all,
                          label: Text('All'),
                        ),
                        ButtonSegment(
                          value: LedgerTypeFilter.income,
                          label: Text('Income'),
                        ),
                        ButtonSegment(
                          value: LedgerTypeFilter.expense,
                          label: Text('Expense'),
                        ),
                      ],
                      selected: {query.type},
                      onSelectionChanged: (v) => notifier.setType(v.first),
                    ),
                  ),
                  section(
                    'Date',
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in LedgerPeriod.values)
                          ChoiceChip(
                            label: Text(
                              p == LedgerPeriod.custom &&
                                      query.period == LedgerPeriod.custom &&
                                      query.customRange != null
                                  ? _rangeLabel(query.customRange!)
                                  : p == LedgerPeriod.custom
                                  ? 'Pick dates…'
                                  : p.label,
                            ),
                            selected: query.period == p,
                            onSelected: (_) async {
                              if (p != LedgerPeriod.custom) {
                                notifier.setPeriod(p);
                                return;
                              }
                              final range = await _pickRange(
                                context,
                                query.customRange,
                              );
                              if (range != null) {
                                notifier.setPeriod(
                                  LedgerPeriod.custom,
                                  range: range,
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  if (categories.isNotEmpty)
                    section(
                      'Categories',
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final c in categories)
                            FilterChip(
                              label: Text(c),
                              avatar: CircleAvatar(
                                radius: 5,
                                backgroundColor: _categoryColor(c),
                              ),
                              selected: query.categories.contains(c),
                              onSelected: (_) => notifier.toggleCategory(c),
                            ),
                        ],
                      ),
                    ),
                  if (methods.isNotEmpty)
                    section(
                      'Payment method',
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final m in methods)
                            FilterChip(
                              label: Text(m),
                              selected: query.paymentMethods.contains(m),
                              onSelected: (_) =>
                                  notifier.togglePaymentMethod(m),
                            ),
                        ],
                      ),
                    ),
                  section(
                    'Amount',
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _min,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Min',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _applyAmounts(),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('–'),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _max,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Max',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _applyAmounts(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  section(
                    'Sort by',
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final s in LedgerSort.values)
                          ChoiceChip(
                            label: Text(s.label),
                            selected: query.sort == s,
                            onSelected: (_) => notifier.setSort(s),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Search tips: type several words to narrow down '
                      '(e.g. "fuel cash"), a number to match amounts ("500"), '
                      'or ">1000" / "<200" for an amount range.',
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      _min.clear();
                      _max.clear();
                      notifier.clearFilters();
                    },
                    child: const Text('Clear filters'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Show $resultCount ${resultCount == 1 ? 'result' : 'results'}',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// EMPTY STATE (no transactions at all)
// =========================================================================

class _EmptyLedgerState extends StatelessWidget {
  const _EmptyLedgerState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Your Wallet is Quiet",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Track your incomes and expenses to see your financial health. Add your first transaction below!",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddOrUpdateLedgerView(),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text("Add Transaction"),
            ),
          ],
        ),
      ),
    );
  }
}
