import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sprint_14/models/expense_model.dart';
import 'package:sprint_14/providers/expense_provider/expense_provider.dart';
import 'package:sprint_14/views/business_views/expense_view/components/expense_form_sheet.dart';

class ExpenseTile extends ConsumerWidget {
  final ExpenseModel expense;
  const ExpenseTile({super.key, required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          // 🔥 SINGLE TAP: EDIT
          onTap: () => _showEditSheet(context),
          // 🔥 LONG PRESS: DELETE
          onLongPress: () => _showDeleteConfirmation(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                  child: Icon(
                    _getIcon(expense.category),
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.category == "Other" && expense.note != null
                            ? expense.note!.toUpperCase()
                            : expense.category.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            DateFormat('hh:mm a').format(expense.dateTime),
                            style: TextStyle(
                              color: theme.colorScheme.outline,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // 🔥 SYNC INDICATOR
                          Icon(
                            expense.isSynced
                                ? Icons.cloud_done_rounded
                                : Icons.sync_rounded,
                            size: 12,
                            color: expense.isSynced
                                ? Colors.green.withOpacity(0.7)
                                : theme
                                      .colorScheme
                                      .tertiary, // Orange from your theme
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  "-${expense.amount.toInt()}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpenseFormSheet(
        businessId: expense.businessId,
        existingExpense: expense,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Expense?"),
        content: const Text(
          "This action will remove the record from your ledger.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(expenseProvider(expense.businessId).notifier)
                  .deleteExpense(expense.id, expense.businessId);
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String category) {
    switch (category) {
      case 'Tea':
        return Icons.coffee_rounded;
      case 'Guests':
        return Icons.group_rounded;
      case 'Govt Fee':
        return Icons.gavel_rounded;
      case 'Fine':
        return Icons.report_problem_rounded;
      case 'Medical':
        return Icons.medical_services_rounded;
      case 'Tips':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
