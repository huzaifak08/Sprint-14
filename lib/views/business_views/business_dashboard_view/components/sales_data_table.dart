import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sprint_14/components/sync_status_badge.dart';
import 'package:sprint_14/models/sale_model.dart';
import 'package:sprint_14/views/business_views/add_update_sale_view.dart';
import 'package:sprint_14/views/business_views/business_dashboard_view/business_dashboard_view_model.dart';

class SalesDataTable extends ConsumerWidget {
  final List<SaleModel> sales;
  final String businessId;

  const SalesDataTable({
    super.key,
    required this.sales,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ui = ref.watch(dashboardUiProvider);
    final notifier = ref.read(dashboardUiProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.05),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: DataTable(
            showCheckboxColumn: ui.isSelectionMode,
            headingRowHeight: 52,
            dataRowMaxHeight: 70, // Increased for multi-line titles
            columnSpacing: 32,
            horizontalMargin: 20,
            headingTextStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
              letterSpacing: 1.5,
            ),
            rows: sales.map((sale) {
              final isSelected = ui.selectedIds.contains(sale.id);
              final bool isProfitable = sale.profit > 0;

              // 🔥 Handle Multi-Product Display Logic
              final String displayTitle = sale.productTitles.isNotEmpty
                  ? sale.productTitles.first.toUpperCase()
                  : "NO TITLE";
              final int extraCount = sale.productTitles.length - 1;

              return DataRow(
                selected: isSelected,
                onSelectChanged: (selected) {
                  if (ui.isSelectionMode) {
                    notifier.toggleId(sale.id);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddUpdateSaleView(
                          businessId: businessId,
                          sale: sale,
                        ),
                      ),
                    );
                  }
                },
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SyncStatusBadge(isSynced: sale.isSynced),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  displayTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (extraCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "+$extraCount",
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              DateFormat(
                                'hh:mm a • dd MMM',
                              ).format(sale.dateTime),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      sale.soldAtPrice.toStringAsFixed(0),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isProfitable
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${isProfitable ? '+' : ''}${sale.profit.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: isProfitable
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      sale.quantity.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
            columns: const [
              DataColumn(label: Text('PRODUCT')),
              DataColumn(label: Text('BILL'), numeric: true),
              DataColumn(label: Text('PROFIT'), numeric: true),
              DataColumn(label: Text('QTY'), numeric: true),
            ],
          ),
        ),
      ),
    );
  }
}
