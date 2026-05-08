import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/models/sale_model.dart';
import 'package:sprint_14/views/business_views/business_dashboard_view/business_dashboard_view_model.dart';

class SummaryCard extends ConsumerWidget {
  final List<SaleModel> sales;
  const SummaryCard({super.key, required this.sales});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ui = ref.watch(dashboardUiProvider);

    double revenue = 0, profit = 0;
    final targetList = (ui.isSelectionMode && ui.selectedIds.isNotEmpty)
        ? sales.where((s) => ui.selectedIds.contains(s.id)).toList()
        : sales;

    for (var s in targetList) {
      revenue += s.soldAtPrice;
      profit += s.profit;
    }

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
          Text(
            ui.selectedIds.isNotEmpty ? "SELECTED PROFIT" : "TOTAL NET PROFIT",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Rs. ${profit.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color:
                  theme.colorScheme.primary, // Using Golden/Blue based on theme
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _statItem(theme, "REVENUE", revenue),
              const Spacer(),
              _statItem(
                theme,
                "COUNT",
                targetList.length.toDouble(),
                isCurrency: false,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
