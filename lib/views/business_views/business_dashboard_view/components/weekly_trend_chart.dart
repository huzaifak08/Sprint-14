import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sprint_14/models/sale_model.dart';

class WeeklyTrendChart extends StatelessWidget {
  final List<SaleModel> sales;
  const WeeklyTrendChart({super.key, required this.sales});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Map<int, double> weeklyData = {};
    for (int i = 0; i < 7; i++) {
      weeklyData[DateTime.now().subtract(Duration(days: i)).weekday] = 0;
    }
    for (var s in sales) {
      if (weeklyData.containsKey(s.dateTime.weekday)) {
        weeklyData[s.dateTime.weekday] =
            weeklyData[s.dateTime.weekday]! + s.soldAtPrice;
      }
    }

    final spots = weeklyData.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    spots.sort((a, b) => a.x.compareTo(b.x));

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
            "REVENUE TREND",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
