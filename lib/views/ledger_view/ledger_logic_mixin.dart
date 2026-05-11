import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ledger_model.dart';
import '../../providers/ledger_provider/ledger_provider.dart';
import 'ledger_view_model.dart';

mixin LedgerLogic {
  List<LedgerModel> getFilteredTransactions(WidgetRef ref) {
    final allTransactions = ref.watch(ledgerProvider);
    final uiState = ref.watch(ledgerUiProvider);

    return allTransactions.where((ledger) {
      // 1. Time Filtering
      bool matchesTime = true;
      if (uiState.activeFilter == LedgerFilterType.monthly) {
        matchesTime =
            ledger.dateTime.month == uiState.selectedDate.month &&
            ledger.dateTime.year == uiState.selectedDate.year;
      } else if (uiState.activeFilter == LedgerFilterType.yearly) {
        matchesTime = ledger.dateTime.year == uiState.selectedDate.year;
      }

      if (!matchesTime) return false;

      // 2. Search Filtering
      if (uiState.isSearching && uiState.searchQuery.isNotEmpty) {
        final q = uiState.searchQuery.toLowerCase();
        return ledger.title.toLowerCase().contains(q) ||
            ledger.category.toLowerCase().contains(q);
      }

      return true;
    }).toList();
  }

  Map<String, double> getSummary(List<LedgerModel> transactions) {
    double income = 0;
    double expense = 0;
    for (var t in transactions) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    return {'income': income, 'expense': expense, 'net': income - expense};
  }
}
