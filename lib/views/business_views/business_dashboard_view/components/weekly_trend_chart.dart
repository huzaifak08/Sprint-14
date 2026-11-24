import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_munshi/models/sale_model.dart';
import 'package:digital_munshi/views/business_views/business_dashboard_view/business_dashboard_view_model.dart';

/// Revenue over the period chosen on the dashboard (see [revenueTrend]).
class WeeklyTrendChart extends ConsumerWidget {
  /// Search-filtered sales from every date; the chart picks its own range.
  final List<SaleModel> sales;
  const WeeklyTrendChart({super.key, required this.sales});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ui = ref.watch(dashboardUiProvider);
    final points = revenueTrend(sales, ui.activeFilter, ui.selectedDate);

    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].revenue),
    ];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trendTitle(ui.activeFilter),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: spots.length < 2
                ? const Center(
                    child: Text(
                      "Not enough data yet",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: theme.colorScheme.primary,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
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
