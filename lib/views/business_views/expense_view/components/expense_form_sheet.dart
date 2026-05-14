import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/helpers/app_data.dart';
import 'package:sprint_14/models/expense_model.dart';
import 'package:sprint_14/providers/expense_provider/expense_provider.dart';
import 'package:sprint_14/providers/user_provider/user_provider.dart';

class ExpenseFormSheet extends ConsumerStatefulWidget {
  final String businessId;
  final ExpenseModel? existingExpense;

  const ExpenseFormSheet({
    super.key,
    required this.businessId,
    this.existingExpense,
  });

  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  late TextEditingController amountController;
  late TextEditingController noteController;
  late String selectedCategory;

  final List<Map<String, dynamic>> categories = [
    {"name": "Tea", "icon": Icons.coffee_rounded},
    {"name": "Guests", "icon": Icons.emoji_food_beverage_rounded},
    {"name": "Electricity", "icon": Icons.bolt_rounded},
    {"name": "Govt Fee", "icon": Icons.gavel_rounded},
    {"name": "Rent", "icon": Icons.home_work_rounded},
    {"name": "Fine", "icon": Icons.report_problem_rounded},
    {"name": "Medical", "icon": Icons.medical_services_rounded},
    {"name": "Tips", "icon": Icons.volunteer_activism_rounded},
    {"name": "Other", "icon": Icons.more_horiz_rounded},
  ];

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(
      text: widget.existingExpense?.amount.toInt().toString() ?? "",
    );
    noteController = TextEditingController(
      text: widget.existingExpense?.note ?? "",
    );
    selectedCategory = widget.existingExpense?.category ?? "Tea";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.read(userProvider).value;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 24,
        right: 24,
        top: 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.existingExpense == null ? "RECORD OUTFLOW" : "EDIT EXPENSE",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                bool isSelected = selectedCategory == cat['name'];
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = cat['name']),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          cat['icon'],
                          size: 18,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cat['name'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          if (selectedCategory == "Other") ...[
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: "What is this for?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
                fillColor: theme.colorScheme.primary.withOpacity(0.05),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: "Amount (PKR)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              filled: true,
              fillColor: theme.colorScheme.primary.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                if (amountController.text.isEmpty || user == null) return;

                final expense =
                    widget.existingExpense?.copyWith(
                      category: selectedCategory,
                      note: selectedCategory == "Other"
                          ? noteController.text.trim()
                          : null,
                      amount: double.parse(amountController.text),
                    ) ??
                    ExpenseModel(
                      id: AppData.shared.uuid.v4(),
                      businessId: widget.businessId,
                      category: selectedCategory,
                      note: selectedCategory == "Other"
                          ? noteController.text.trim()
                          : null,
                      amount: double.parse(amountController.text),
                      dateTime: DateTime.now(),
                      recordedById: user.uid,
                      isSynced: false,
                      isDeleted: false,
                    );

                if (widget.existingExpense == null) {
                  ref
                      .read(expenseProvider(widget.businessId).notifier)
                      .addExpense(expense);
                } else {
                  ref
                      .read(expenseProvider(widget.businessId).notifier)
                      .updateExpense(expense);
                }
                Navigator.pop(context);
              },
              child: Text(
                widget.existingExpense == null
                    ? "FINALIZE ENTRY"
                    : "UPDATE ENTRY",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
