import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_munshi/models/sale_model.dart';
import 'package:digital_munshi/providers/business_provider/business_provider.dart';
import 'package:digital_munshi/providers/expense_provider/expense_provider.dart'; // 🔥 Import this
import 'package:digital_munshi/views/business_views/business_dashboard_view/business_dashboard_view_model.dart';

class SummaryCard extends ConsumerWidget {
  final List<SaleModel> sales;
  final String businessId; // 🔥 Pass this to fetch expenses

  const SummaryCard({super.key, required this.sales, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ui = ref.watch(dashboardUiProvider);

    // 🔥 Watch expenses for this business
    final expenseState = ref.watch(expenseProvider(businessId));

    double revenue = 0, grossProfit = 0;
    final targetList = (ui.isSelectionMode && ui.selectedIds.isNotEmpty)
        ? sales.where((s) => ui.selectedIds.contains(s.id)).toList()
        : sales;

    for (var s in targetList) {
      revenue += s.soldAtPrice;
      grossProfit += s.profit;
    }

    final currency =
        ref.watch(singleBusinessProvider(businessId)).value?.currency ?? 'PKR';
    final hasSelection = ui.isSelectionMode && ui.selectedIds.isNotEmpty;

    // Expenses for the whole period on screen (even on days with no sales).
    // A hand-picked selection of sales has no matching expenses, so it shows
    // gross profit only.
    double totalExpenses = 0;
    if (!hasSelection) {
      totalExpenses = (expenseState.value ?? [])
          .where(
            (e) => matchesPeriod(e.dateTime, ui.activeFilter, ui.selectedDate),
          )
          .fold(0.0, (sum, e) => sum + e.amount);
    }

    final netProfit = grossProfit - totalExpenses;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasSelection
                        ? "SELECTED GROSS PROFIT"
                        : periodProfitLabel(ui.activeFilter),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$currency ${netProfit.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              // 🔥 Top Right: Daily Expense Outflow
              _statItem(
                theme,
                "EXPENSES",
                totalExpenses,
                currency: currency,
                color: Colors.redAccent,
                crossAxisAlignment: CrossAxisAlignment.end,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem(theme, "REVENUE", revenue, currency: currency),
              _statItem(
                theme,
                "GROSS",
                grossProfit,
                currency: currency,
                color: Colors.green,
              ),
              _statItem(
                theme,
                "COUNT",
                targetList.length.toDouble(),
                isCurrency: false,
                crossAxisAlignment: CrossAxisAlignment.end,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    ThemeData theme,
    String label,
    double val, {
    bool isCurrency = true,
    String currency = 'PKR',
    Color? color,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: Colors.grey,
          ),
        ),
        Text(
          "${isCurrency ? '$currency ' : ''}${val.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
