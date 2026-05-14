import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/models/sale_model.dart';
import 'package:sprint_14/providers/expense_provider/expense_provider.dart'; // 🔥 Import this
import 'package:sprint_14/views/business_views/business_dashboard_view/business_dashboard_view_model.dart';

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

    // 🔥 Calculate total expenses for the visible sales day
    // (Assuming the dashboard is currently showing a specific date)
    double totalExpenses = 0;
    expenseState.whenData((expenses) {
      if (targetList.isNotEmpty) {
        final currentDate = targetList.first.dateTime;
        totalExpenses = expenses
            .where(
              (e) =>
                  e.dateTime.year == currentDate.year &&
                  e.dateTime.month == currentDate.month &&
                  e.dateTime.day == currentDate.day,
            )
            .fold(0, (sum, e) => sum + e.amount);
      }
    });

    // 🔥 Actual Net Profit calculation
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
                    ui.selectedIds.isNotEmpty
                        ? "SELECTED PROFIT"
                        : "DAILY NET PROFIT",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Rs. ${netProfit.toStringAsFixed(0)}",
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
                color: Colors.redAccent,
                crossAxisAlignment: CrossAxisAlignment.end,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem(theme, "REVENUE", revenue),
              _statItem(theme, "GROSS", grossProfit, color: Colors.green),
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
          "${isCurrency ? 'Rs ' : ''}${val.toStringAsFixed(0)}",
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
