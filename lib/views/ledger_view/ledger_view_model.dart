import 'package:flutter_riverpod/legacy.dart';

enum LedgerFilterType { all, monthly, yearly }

class LedgerUiState {
  final bool isSearching;
  final bool isSelectionMode;
  final bool showFilters;
  final String searchQuery;
  final LedgerFilterType activeFilter;
  final DateTime selectedDate;
  final Set<String> selectedIds;

  LedgerUiState({
    this.isSearching = false,
    this.isSelectionMode = false,
    this.showFilters = false,
    this.searchQuery = "",
    this.activeFilter = LedgerFilterType.all,
    DateTime? selectedDate,
    this.selectedIds = const {},
  }) : selectedDate = selectedDate ?? DateTime.now();

  LedgerUiState copyWith({
    bool? isSearching,
    bool? isSelectionMode,
    bool? showFilters,
    String? searchQuery,
    LedgerFilterType? activeFilter,
    DateTime? selectedDate,
    Set<String>? selectedIds,
  }) {
    return LedgerUiState(
      isSearching: isSearching ?? this.isSearching,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      showFilters: showFilters ?? this.showFilters,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class LedgerUiNotifier extends StateNotifier<LedgerUiState> {
  LedgerUiNotifier() : super(LedgerUiState());

  void toggleSearch() =>
      state = state.copyWith(isSearching: !state.isSearching, searchQuery: "");
  void updateSearch(String q) => state = state.copyWith(searchQuery: q);
  void toggleFilters() =>
      state = state.copyWith(showFilters: !state.showFilters);
  void setFilter(LedgerFilterType t) => state = state.copyWith(activeFilter: t);

  void toggleSelectionMode() {
    state = state.copyWith(
      isSelectionMode: !state.isSelectionMode,
      selectedIds: {},
    );
  }

  void toggleId(String id) {
    final newIds = Set<String>.from(state.selectedIds);
    if (newIds.contains(id)) {
      newIds.remove(id);
    } else {
      newIds.add(id);
    }
    state = state.copyWith(selectedIds: newIds);
  }

  void adjustDate(int offset) {
    final current = state.selectedDate;
    if (state.activeFilter == LedgerFilterType.monthly) {
      state = state.copyWith(
        selectedDate: DateTime(current.year, current.month + offset),
      );
    } else {
      state = state.copyWith(selectedDate: DateTime(current.year + offset));
    }
  }
}

final ledgerUiProvider = StateNotifierProvider<LedgerUiNotifier, LedgerUiState>(
  (ref) {
    return LedgerUiNotifier();
  },
);
