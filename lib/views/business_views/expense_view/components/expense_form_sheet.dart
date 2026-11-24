import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:digital_munshi/components/app_toast.dart';
import 'package:digital_munshi/helpers/app_data.dart';
import 'package:digital_munshi/helpers/number_input.dart';
import 'package:digital_munshi/providers/business_provider/business_provider.dart';
import 'package:digital_munshi/models/expense_model.dart';
import 'package:digital_munshi/providers/expense_provider/expense_provider.dart';
import 'package:digital_munshi/providers/current_user_provider/current_user_provider.dart';

class ExpenseFormSheet extends ConsumerStatefulWidget {
  final String businessId;
  final ExpenseModel? existingExpense;

  /// Day a new expense is recorded on (defaults to today).
  final DateTime? initialDate;

  const ExpenseFormSheet({
    super.key,
    required this.businessId,
    this.existingExpense,
    this.initialDate,
  });

  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  late TextEditingController amountController;
  late TextEditingController noteController;
  late String selectedCategory;
  late DateTime selectedDate;

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
    final amount = widget.existingExpense?.amount;
    amountController = TextEditingController(
      text: amount == null
          ? ""
          : (amount % 1 == 0
                ? amount.toStringAsFixed(0)
                : amount.toStringAsFixed(2)),
    );
    selectedDate =
        widget.existingExpense?.dateTime ??
        widget.initialDate ??
        DateTime.now();
    noteController = TextEditingController(
      text: widget.existingExpense?.note ?? "",
    );
    selectedCategory = widget.existingExpense?.category ?? "Tea";
  }

  String get _currency =>
      ref.watch(singleBusinessProvider(widget.businessId)).value?.currency ??
      'PKR';

  /// Changes the day, keeping the original time of day.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        selectedDate.hour,
        selectedDate.minute,
        selectedDate.second,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.read(currentUserProvider).value;

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
                            : theme.colorScheme.primary.withValues(alpha: 0.1),
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
                fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_rounded),
            title: Text(
              DateFormat('EEEE, d MMM yyyy').format(selectedDate),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.edit_calendar_rounded),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: "Amount ($_currency)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              filled: true,
              fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                if (user == null) return;
                final amount = parseAmount(amountController.text);
                if (amount == null || amount <= 0) {
                  AppToast.error("Enter an amount above 0.");
                  return;
                }
                final note = noteController.text.trim();
                final keepNote = selectedCategory == "Other" && note.isNotEmpty;

                final expense =
                    widget.existingExpense?.copyWith(
                      category: selectedCategory,
                      note: keepNote ? note : null,
                      clearNote: !keepNote,
                      amount: amount,
                      dateTime: selectedDate,
                    ) ??
                    ExpenseModel(
                      id: AppData.shared.uuid.v4(),
                      businessId: widget.businessId,
                      category: selectedCategory,
                      note: keepNote ? note : null,
                      amount: amount,
                      dateTime: selectedDate,
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
