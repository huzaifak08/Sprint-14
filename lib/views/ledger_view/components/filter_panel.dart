import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sprint_14/views/ledger_view/ledger_view_model.dart';

class FilterPanel extends ConsumerWidget {
  const FilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uiState = ref.watch(ledgerUiProvider);
    final notifier = ref.read(ledgerUiProvider.notifier);

    return Container(
      // Use width: double.infinity to fill the Expanded sidebar
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Constrain height to content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "FILTERS",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),

          // 1. FILTER CHIPS: Using a Wrap with better spacing
          Wrap(
            spacing: 8,
            runSpacing: 8, // Handles wrapping if the sidebar is too narrow
            children: LedgerFilterType.values.map((type) {
              final isSelected = uiState.activeFilter == type;
              return ChoiceChip(
                label: Text(
                  type.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => notifier.setFilter(type),
              );
            }).toList(),
          ),

          if (uiState.activeFilter != LedgerFilterType.all) ...[
            const SizedBox(height: 24),
            const Text(
              "TIMEFRAME",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),

            // 2. DATE NAVIGATION: Fixed with Flexible text to prevent overflow
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    onPressed: () => notifier.adjustDate(-1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                  // Flexible prevents the date string (e.g. "September 2026") from breaking
                  Flexible(
                    child: Text(
                      uiState.activeFilter == LedgerFilterType.monthly
                          ? DateFormat('MMM yyyy').format(uiState.selectedDate)
                          : uiState.selectedDate.year.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    onPressed: () => notifier.adjustDate(1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
