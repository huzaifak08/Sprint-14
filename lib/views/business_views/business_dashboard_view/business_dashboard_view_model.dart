import 'package:flutter_riverpod/legacy.dart';

enum DashboardFilterType { all, daily, monthly, yearly }

class DashboardUiState {
  final bool isSearching;
  final bool isSelectionMode;
  final String searchQuery;
  final DashboardFilterType activeFilter;
  final DateTime selectedDate;
  final Set<String> selectedIds;

  DashboardUiState({
    this.isSearching = false,
    this.isSelectionMode = false,
    this.searchQuery = "",
    this.activeFilter = DashboardFilterType.all,
    DateTime? selectedDate,
    this.selectedIds = const {},
  }) : selectedDate = selectedDate ?? DateTime.now();

  DashboardUiState copyWith({
    bool? isSearching,
    bool? isSelectionMode,
    String? searchQuery,
    DashboardFilterType? activeFilter,
    DateTime? selectedDate,
    Set<String>? selectedIds,
  }) {
    return DashboardUiState(
      isSearching: isSearching ?? this.isSearching,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class DashboardUiNotifier extends StateNotifier<DashboardUiState> {
  DashboardUiNotifier() : super(DashboardUiState());

  void toggleSearch() =>
      state = state.copyWith(isSearching: !state.isSearching, searchQuery: "");
  void updateSearch(String q) => state = state.copyWith(searchQuery: q);
  void setFilter(DashboardFilterType t) =>
      state = state.copyWith(activeFilter: t);

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
    if (state.activeFilter == DashboardFilterType.daily) {
      state = state.copyWith(selectedDate: current.add(Duration(days: offset)));
    } else if (state.activeFilter == DashboardFilterType.monthly) {
      state = state.copyWith(
        selectedDate: DateTime(current.year, current.month + offset),
      );
    } else {
      state = state.copyWith(selectedDate: DateTime(current.year + offset));
    }
  }
}

final dashboardUiProvider =
    StateNotifierProvider<DashboardUiNotifier, DashboardUiState>(
      (ref) => DashboardUiNotifier(),
    );
