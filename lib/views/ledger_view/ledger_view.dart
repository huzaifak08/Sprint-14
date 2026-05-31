import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sprint_14/models/ledger_model.dart';
import 'package:sprint_14/providers/ledger_provider/ledger_provider.dart';
import 'package:sprint_14/views/add_or_update_ledger_view.dart';

import 'ledger_view_model.dart';

class LedgerView extends ConsumerWidget {
  const LedgerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1️⃣ Watch the updated async ledger provider state wrapper
    final ledgersAsync = ref.watch(ledgerProvider);

    // 2️⃣ Watch your localized filter parameters
    final activeFilter = ref.watch(
      ledgerUiProvider.select((s) => s.activeFilter),
    );
    final selectedDate = ref.watch(
      ledgerUiProvider.select((s) => s.selectedDate),
    );

    // 3️⃣ Unpack the AsyncValue cleanly matching structural layouts
    return ledgersAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
        body: Center(child: Text("Error loading transactions: $err")),
      ),
      data: (allTransactions) {
        // Handle global empty state first when no data exists in SQLite or cloud
        if (allTransactions.isEmpty) {
          return const _EmptyLedgerState();
        }

        // Apply time filter parameters safely over the raw unpacked Iterable items list
        final timeFiltered = allTransactions.where((ledger) {
          if (activeFilter == LedgerFilterType.monthly) {
            return ledger.dateTime.month == selectedDate.month &&
                ledger.dateTime.year == selectedDate.year;
          } else if (activeFilter == LedgerFilterType.yearly) {
            return ledger.dateTime.year == selectedDate.year;
          }
          return true;
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCard(transactions: timeFiltered),
            const SizedBox(height: 20),
            _ChartSection(transactions: timeFiltered),
            const SizedBox(height: 16),
            const _FilterToggleSection(),
            const SizedBox(height: 16),
            const _HeaderSection(),
            const SizedBox(height: 12),
            _TransactionDataTable(timeFiltered: timeFiltered),
          ],
        );
      },
    );
  }
}

// --- ATOMIC SUB-WIDGETS ---

class _SummaryCard extends ConsumerWidget {
  final List<LedgerModel> transactions;
  const _SummaryCard({required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSelMode = ref.watch(
      ledgerUiProvider.select((s) => s.isSelectionMode),
    );
    final selIds = ref.watch(ledgerUiProvider.select((s) => s.selectedIds));

    double inc = 0, exp = 0, sel = 0;
    for (var t in transactions) {
      if (t.isIncome) {
        inc += t.amount;
      } else {
        exp += t.amount;
      }
    }

    if (isSelMode) {
      for (var id in selIds) {
        // Prevent crashes if transactions filter bounds changes out from under active checkbox lists
        final t = transactions.cast<LedgerModel?>().firstWhere(
          (e) => e?.id == id,
          orElse: () => null,
        );
        if (t != null) {
          sel += t.isIncome ? t.amount : -t.amount;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _item("Income", inc, Colors.green),
          _vDiv(theme),
          _item("Expense", exp, Colors.redAccent),
          _vDiv(theme),
          isSelMode
              ? _item("Selected", sel, theme.colorScheme.tertiary)
              : _item("Net", inc - exp, theme.colorScheme.primary),
        ],
      ),
    );
  }

  Widget _item(String l, double v, Color c) => Column(
    children: [
      Text(l, style: const TextStyle(fontSize: 12)),
      Text(
        v.toStringAsFixed(0),
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c),
      ),
    ],
  );

  Widget _vDiv(ThemeData t) => Container(
    width: 1,
    height: 30,
    color: t.dividerColor.withValues(alpha: 0.2),
  );
}

class _ChartSection extends StatelessWidget {
  final List<LedgerModel> transactions;
  const _ChartSection({required this.transactions});

  @override
  Widget build(BuildContext context) {
    double totalExp = 0;
    Map<String, double> catMap = {};
    for (var t in transactions.where((e) => !e.isIncome)) {
      totalExp += t.amount;
      catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
    }

    if (totalExp == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Expense Breakdown",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildPie(catMap, totalExp, Theme.of(context)),
      ],
    );
  }

  Widget _buildPie(Map<String, double> data, double total, ThemeData theme) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.teal,
      Colors.purple,
      Colors.pink,
      Colors.green,
      Colors.red,
    ];
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: data.entries.indexed
                    .map(
                      (e) => PieChartSectionData(
                        color: colors[e.$1 % colors.length],
                        value: e.$2.value,
                        title: '',
                        radius: 15,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: data.entries.indexed
                  .map(
                    (e) => Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors[e.$1 % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "${e.$2.key} (${(e.$2.value / total * 100).toStringAsFixed(0)}%)",
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterToggleSection extends ConsumerWidget {
  const _FilterToggleSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(ledgerUiProvider.select((s) => s.showFilters));
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "History Range",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () =>
                  ref.read(ledgerUiProvider.notifier).toggleFilters(),
              icon: Icon(show ? Icons.expand_less : Icons.tune),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: show ? const _FilterContent() : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _FilterContent extends ConsumerWidget {
  const _FilterContent();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(ledgerUiProvider.select((s) => s.activeFilter));
    final date = ref.watch(ledgerUiProvider.select((s) => s.selectedDate));
    final notifier = ref.read(ledgerUiProvider.notifier);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: LedgerFilterType.values
              .map(
                (t) => ChoiceChip(
                  label: Text(t.name.toUpperCase()),
                  selected: active == t,
                  onSelected: (_) => notifier.setFilter(t),
                ),
              )
              .toList(),
        ),
        if (active != LedgerFilterType.all)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => notifier.adjustDate(-1),
              ),
              Text(
                active == LedgerFilterType.monthly
                    ? DateFormat('MMM yyyy').format(date)
                    : date.year.toString(),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => notifier.adjustDate(1),
              ),
            ],
          ),
      ],
    );
  }
}

class _HeaderSection extends ConsumerWidget {
  const _HeaderSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearching = ref.watch(
      ledgerUiProvider.select((s) => s.isSearching),
    );
    final isSel = ref.watch(ledgerUiProvider.select((s) => s.isSelectionMode));
    final count = ref.watch(
      ledgerUiProvider.select((s) => s.selectedIds.length),
    );

    if (isSearching) {
      return TextField(
        onChanged: (v) => ref.read(ledgerUiProvider.notifier).updateSearch(v),
        autofocus: true,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: "Search transactions...",
          hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.7)),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => ref.read(ledgerUiProvider.notifier).toggleSearch(),
          ),
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Text(
          isSel ? "$count Selected" : "Transactions",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(isSel ? Icons.calculate : Icons.calculate_outlined),
          onPressed: () =>
              ref.read(ledgerUiProvider.notifier).toggleSelectionMode(),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => ref.read(ledgerUiProvider.notifier).toggleSearch(),
        ),
      ],
    );
  }
}

class _TransactionDataTable extends ConsumerWidget {
  final List<LedgerModel> timeFiltered;
  const _TransactionDataTable({required this.timeFiltered});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final query = ref
        .watch(ledgerUiProvider.select((s) => s.searchQuery))
        .toLowerCase();
    final isSelMode = ref.watch(
      ledgerUiProvider.select((s) => s.isSelectionMode),
    );
    final selIds = ref.watch(ledgerUiProvider.select((s) => s.selectedIds));

    final displayList = timeFiltered.where((t) {
      return t.title.toLowerCase().contains(query) ||
          t.category.toLowerCase().contains(query);
    }).toList();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: DataTable(
        showCheckboxColumn: isSelMode,
        horizontalMargin: 12,
        columnSpacing: 10,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.tertiary,
        ),
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Title')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Category')),
        ],
        rows: displayList.map((ledger) {
          final isSelected = selIds.contains(ledger.id);

          return DataRow(
            selected: isSelected,
            onSelectChanged: (selected) {
              if (isSelMode) {
                ref.read(ledgerUiProvider.notifier).toggleId(ledger.id!);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddOrUpdateLedgerView(ledger: ledger),
                  ),
                );
              }
            },
            cells: [
              DataCell(
                Text(
                  DateFormat('dd MMM').format(ledger.dateTime),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 80,
                  child: Text(ledger.title, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(
                Text(
                  ledger.amount.toStringAsFixed(0),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ledger.isIncome ? Colors.green : Colors.redAccent,
                  ),
                ),
              ),
              DataCell(
                Text(
                  ledger.category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

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
