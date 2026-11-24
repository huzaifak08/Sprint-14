import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:digital_munshi/views/business_views/business_dashboard_view/business_dashboard_view_model.dart';

class DateFilterControls extends ConsumerWidget {
  /// Days (date only) with at least one sale; the daily arrows skip the rest.
  final Set<DateTime> saleDays;
  const DateFilterControls({super.key, this.saleDays = const {}});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ui = ref.watch(dashboardUiProvider);
    final notifier = ref.read(dashboardUiProvider.notifier);
    final canGoBack =
        steppedDate(ui.activeFilter, ui.selectedDate, -1, saleDays) != null;
    final canGoForward =
        steppedDate(ui.activeFilter, ui.selectedDate, 1, saleDays) != null;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: DashboardFilterType.values
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.name.toUpperCase()),
                      labelStyle: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: ui.activeFilter == f
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                      ),
                      selected: ui.activeFilter == f,
                      selectedColor: theme.colorScheme.primary,
                      onSelected: (_) => notifier.setFilter(f),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        if (ui.activeFilter != DashboardFilterType.all)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: canGoBack
                      ? () => notifier.adjustDate(-1, saleDays: saleDays)
                      : null,
                ),
                const SizedBox(width: 16),
                Text(
                  ui.activeFilter == DashboardFilterType.daily
                      ? DateFormat('dd MMM yyyy').format(ui.selectedDate)
                      : ui.activeFilter == DashboardFilterType.monthly
                      ? DateFormat('MMM yyyy').format(ui.selectedDate)
                      : ui.selectedDate.year.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: canGoForward
                      ? () => notifier.adjustDate(1, saleDays: saleDays)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
