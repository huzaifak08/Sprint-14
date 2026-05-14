import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sprint_14/helpers/app_data.dart';
import 'package:sprint_14/models/expense_model.dart';
import 'package:sprint_14/providers/expense_provider/expense_provider.dart';
import 'package:sprint_14/providers/user_provider/user_provider.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  final String businessId;
  final DateTime
  initialDate; // 🔥 Required to pin expense to the selected calendar day

  const AddExpenseSheet({
    super.key,
    required this.businessId,
    required this.initialDate,
  });

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  String selectedCategory = "Tea";

  final List<Map<String, dynamic>> categories = [
    {"name": "Tea", "icon": Icons.coffee_rounded},
    {"name": "Guests", "icon": Icons.emoji_food_beverage_rounded},
    {"name": "Govt Fee", "icon": Icons.gavel_rounded},
    {"name": "Fine", "icon": Icons.report_problem_rounded},
    {"name": "Medical", "icon": Icons.medical_services_rounded},
    {"name": "Tips", "icon": Icons.volunteer_activism_rounded},
    {"name": "Other", "icon": Icons.more_horiz_rounded},
  ];

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
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
            "RECORD OUTFLOW",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMM dd, yyyy').format(widget.initialDate),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Category Grid
          SizedBox(
            height: 180,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
                  onTap: () {
                    setState(() => selectedCategory = cat['name']);
                    Feedback.forTap(context);
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withOpacity(0.1),
                        ),
                        child: Icon(
                          cat['icon'],
                          size: 20,
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
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Note Field (Visible only if 'Other' is selected)
          if (selectedCategory == "Other") ...[
            TextField(
              controller: noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Description",
                hintText: "e.g., Shop repairs, cleaning...",
                prefixIcon: const Icon(Icons.edit_note_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
                fillColor: theme.colorScheme.primary.withOpacity(0.05),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Amount Field
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: "Amount (PKR)",
              prefixIcon: const Icon(Icons.payments_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              filled: true,
              fillColor: theme.colorScheme.primary.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {
                if (amountController.text.isEmpty || user == null) return;

                // 🔥 COMBINE PICKED DATE WITH CURRENT TIME
                final now = DateTime.now();
                final finalDateTime = DateTime(
                  widget.initialDate.year,
                  widget.initialDate.month,
                  widget.initialDate.day,
                  now.hour,
                  now.minute,
                  now.second,
                );

                final expense = ExpenseModel(
                  id: AppData.shared.uuid.v4(),
                  businessId: widget.businessId,
                  category: selectedCategory,
                  note: selectedCategory == "Other"
                      ? noteController.text.trim()
                      : null,
                  amount: double.parse(amountController.text),
                  dateTime: finalDateTime, // 🔥 Fixed: uses selected day
                  recordedById: user.uid,
                  isSynced: false,
                  isDeleted: false,
                );

                ref
                    .read(expenseProvider(widget.businessId).notifier)
                    .addExpense(expense);

                Navigator.pop(context);
              },
              child: const Text(
                "FINALIZE ENTRY",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
