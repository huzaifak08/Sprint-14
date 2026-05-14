import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sprint_14/models/expense_model.dart';
import 'package:sprint_14/providers/expense_provider/expense_provider.dart';
import 'package:sprint_14/views/business_views/expense_view/components/add_expense_sheet.dart';
import 'package:sprint_14/views/business_views/expense_view/components/expense_tile.dart';

class ExpenseView extends ConsumerStatefulWidget {
  final String businessId;
  const ExpenseView({super.key, required this.businessId});

  @override
  ConsumerState<ExpenseView> createState() => _ExpenseViewState();
}

class _ExpenseViewState extends ConsumerState<ExpenseView> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseState = ref.watch(expenseProvider(widget.businessId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "EXPENSE LOG",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              // 🔥 FIX: Ensure the widget is still attached to the tree
              if (picked != null && mounted) {
                setState(() => selectedDate = picked);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: expenseState.when(
        data: (expenses) {
          final dailyExpenses = expenses
              .where(
                (e) =>
                    e.dateTime.year == selectedDate.year &&
                    e.dateTime.month == selectedDate.month &&
                    e.dateTime.day == selectedDate.day,
              )
              .toList();

          return Column(
            children: [
              _buildSummaryHeader(theme, dailyExpenses),
              Expanded(
                child: dailyExpenses.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: dailyExpenses.length,
                        itemBuilder: (context, index) =>
                            ExpenseTile(expense: dailyExpenses[index]),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
      // 🔥 FIX: Replaced .large with standard FAB size
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseSheet(context, ref),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildSummaryHeader(
    ThemeData theme,
    List<ExpenseModel> dailyExpenses,
  ) {
    final total = dailyExpenses.fold(0.0, (sum, item) => sum + item.amount);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, d MMMM').format(selectedDate).toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "PKR ${total.toStringAsFixed(0)}",
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 50,
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          const Text(
            "No expenses for this day",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExpenseSheet(
        businessId: widget.businessId,
        initialDate: selectedDate,
      ),
    );
  }
}
