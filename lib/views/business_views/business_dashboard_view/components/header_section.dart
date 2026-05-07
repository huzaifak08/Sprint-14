import 'package:flutter/material.dart';
import 'package:sprint_14/views/business_views/business_dashboard_view/business_dashboard_view_model.dart';

class HeaderSection extends StatelessWidget {
  final DashboardUiState uiState;
  final int count;
  const HeaderSection({super.key, required this.uiState, required this.count});

  @override
  Widget build(BuildContext context) {
    return Text(
      uiState.isSelectionMode ? "$count SELECTED" : "ALL TRANSACTIONS",
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Colors.grey,
      ),
    );
  }
}
