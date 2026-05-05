import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sprint_14/helpers/constants.dart';
import 'package:sprint_14/models/ledger_model.dart';
import 'package:sprint_14/providers/ledger_provider/ledger_provider.dart';

import 'package:uuid/uuid.dart';

class AddOrUpdateLedgerView extends ConsumerStatefulWidget {
  final LedgerModel? ledger;
  const AddOrUpdateLedgerView({super.key, this.ledger});

  @override
  ConsumerState<AddOrUpdateLedgerView> createState() =>
      _AddOrUpdateLedgerViewState();
}

class _AddOrUpdateLedgerViewState extends ConsumerState<AddOrUpdateLedgerView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  // Focus Nodes for smooth navigation
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _noteFocus = FocusNode();

  // State Variables
  late bool _isIncome;
  late String _selectedCategory;
  late DateTime _selectedDate;
  String _selectedPaymentMethod = "Cash";

  @override
  void initState() {
    super.initState();
    _isIncome = widget.ledger?.isIncome ?? false;
    _titleController = TextEditingController(text: widget.ledger?.title);
    _amountController = TextEditingController(
      text: widget.ledger?.amount.toString() == "0.0"
          ? ""
          : widget.ledger?.amount.toString(),
    );
    _noteController = TextEditingController(text: widget.ledger?.note);
    _selectedCategory = widget.ledger?.category ?? "Food";
    _selectedDate = widget.ledger?.dateTime ?? DateTime.now();
    _selectedPaymentMethod = widget.ledger?.paymentMethod ?? "Cash";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final newLedger = LedgerModel(
        id: widget.ledger?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        isIncome: _isIncome,
        note: _noteController.text.trim(),
        paymentMethod: _selectedPaymentMethod,
        isSynced: false,
        isDeleted: false,
        dateTime: _selectedDate,
      );

      if (widget.ledger == null) {
        await ref.read(ledgerProvider.notifier).addLedger(newLedger);
      } else {
        await ref.read(ledgerProvider.notifier).updateLedger(newLedger);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.ledger == null ? "New Transaction" : "Edit Transaction",
        ),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check_rounded)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Transaction Type Selector
            Center(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text("Expense"),
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text("Income"),
                    icon: Icon(Icons.add_circle_outline),
                  ),
                ],
                selected: {_isIncome},
                onSelectionChanged: (val) =>
                    setState(() => _isIncome = val.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: _isIncome
                      ? Colors.green
                      : Colors.redAccent,
                  selectedForegroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title Input
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration("Title", Icons.title),
              textInputAction: TextInputAction.next,
              validator: (v) => v!.isEmpty ? "Enter a title" : null,
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_amountFocus),
            ),
            const SizedBox(height: 16),

            // Amount Input
            TextFormField(
              controller: _amountController,
              focusNode: _amountFocus,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("Amount", Icons.money),
              style: TextStyle(
                color: _isIncome ? Colors.green : Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
              validator: (v) => double.tryParse(v ?? "") == null
                  ? "Enter valid amount"
                  : null,
            ),
            const SizedBox(height: 16),

            // Category & Date Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: _inputDecoration("Category", Icons.category),
                    items: transactionCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final DateTime now = DateTime.now();
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: now,
                      );

                      if (pickedDate != null) {
                        setState(() {
                          // 🔥 Combine picked Date with CURRENT Time
                          _selectedDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            now.hour,
                            now.minute,
                            now.second,
                          );
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: _inputDecoration(
                        "Date",
                        Icons.calendar_today,
                      ),
                      child: Text(DateFormat('dd MMM').format(_selectedDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Note Input
            TextFormField(
              controller: _noteController,
              focusNode: _noteFocus,
              maxLines: 3,
              decoration: _inputDecoration("Notes (Optional)", Icons.notes),
            ),

            const SizedBox(height: 32),
            if (widget.ledger != null)
              Row(
                children: [
                  Expanded(
                    // flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: _showDeleteDialog,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        "DELETE",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 54),
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSaveButton(theme)),
                ],
              )
            else
              _buildSaveButton(theme),
          ],
        ),
      ),
    );
  }

  // Helper for the Save Button to avoid code duplication
  Widget _buildSaveButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        "SAVE TRANSACTION",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  // The Delete Confirmation Dialog
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Transaction?"),
        content: const Text(
          "This will permanently remove this record from your ledger.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCEL",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);
              await ref
                  .read(ledgerProvider.notifier)
                  .deleteLedger(widget.ledger?.id ?? "Ledger ID");

              // ! Remove if not implemented
              // if (mounted) {
              //   Navigator.pop(
              //     AppData.shared.navigatorKey.currentContext ?? context,
              //   );
              // }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
  }
}
