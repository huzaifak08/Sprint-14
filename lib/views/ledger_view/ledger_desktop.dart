import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sprint_14/models/ledger_model.dart';
import 'package:sprint_14/views/ledger_view/components/filter_panel.dart';
import 'ledger_logic_mixin.dart';
import 'ledger_view_model.dart';
import '../add_or_update_ledger_view.dart';

class LedgerDesktop extends ConsumerWidget with LedgerLogic {
  const LedgerDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filtered = getFilteredTransactions(ref);
    final summary = getSummary(filtered);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            _buildHeader(context, ref, filtered.length),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Table
                  Expanded(
                    flex: 3,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.dividerColor.withOpacity(0.1),
                        ),
                      ),
                      child: _TransactionTable(transactions: filtered),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right Column: Stats & Filters
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildStatCard(
                          theme,
                          "Net Balance",
                          summary['net']!,
                          theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        _buildMiniSummary(summary),
                        const SizedBox(height: 24),
                        const FilterPanel(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddOrUpdateLedgerView()),
        ),
        label: const Text("New Transaction"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, int count) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Financial Ledger",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            Text(
              "Total $count transactions found",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        // Search bar integrated into header for Desktop
        SizedBox(
          width: 300,
          child: TextField(
            onChanged: (v) =>
                ref.read(ledgerUiProvider.notifier).updateSearch(v),
            decoration: InputDecoration(
              hintText: "Search...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String title,
    double val,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Rs. ${val.toStringAsFixed(0)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSummary(Map<String, double> summary) {
    return Row(
      children: [
        _miniItem("Income", summary['income']!, Colors.green),
        const SizedBox(width: 12),
        _miniItem("Expenses", summary['expense']!, Colors.redAccent),
      ],
    );
  }

  Widget _miniItem(String label, double val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              val.toStringAsFixed(0),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTable extends StatelessWidget {
  final List<LedgerModel> transactions;
  const _TransactionTable({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Date")),
          DataColumn(label: Text("Title")),
          DataColumn(label: Text("Category")),
          DataColumn(label: Text("Amount")),
        ],
        rows: transactions
            .map(
              (t) => DataRow(
                cells: [
                  DataCell(Text(DateFormat('dd MMM, yyyy').format(t.dateTime))),
                  DataCell(
                    Text(
                      t.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Chip(
                      label: Text(
                        t.category,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      t.amount.toStringAsFixed(0),
                      style: TextStyle(
                        color: t.isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                onSelectChanged: (_) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddOrUpdateLedgerView(ledger: t),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
