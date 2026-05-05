import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sprint_14/helpers/app_data.dart';
import 'package:sprint_14/providers/reminders_provider/reminders_provider.dart';

class AddReminderView extends ConsumerStatefulWidget {
  const AddReminderView({super.key});

  @override
  ConsumerState<AddReminderView> createState() => _AddReminderViewState();
}

class _AddReminderViewState extends ConsumerState<AddReminderView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final FocusNode _bodyFocusNode;

  DateTime _selectedDate = DateTime.now().add(const Duration(minutes: 5));
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    _bodyFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: AppData.shared.navigatorKey.currentContext ?? context,
        initialTime: _selectedTime,
        initialEntryMode: TimePickerEntryMode.input,
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Custom Reminder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('What should we remind you?'),
              const SizedBox(height: 15),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Title', Icons.title),
                validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
                onFieldSubmitted: (value) {
                  FocusScope.of(context).requestFocus(_bodyFocusNode);
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _bodyController,
                focusNode: _bodyFocusNode,
                maxLines: 3,
                decoration: _inputDecoration('Description', Icons.description),
                validator: (v) =>
                    v!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('When?'),
              const SizedBox(height: 15),
              InkWell(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: Color(0xFF4285F4),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        DateFormat(
                          'MMM dd, yyyy - hh:mm a',
                        ).format(scheduledDateTime),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Generating a 32-bit ID as we discussed

                      ref
                          .read(remindersProvider.notifier)
                          .setReminder(
                            id: AppData.shared.uuid.v4().hashCode & 0x7FFFFFFF,
                            title: _titleController.text,
                            body: _bodyController.text,
                            dateTime: scheduledDateTime,
                            payload: scheduledDateTime.toString(),
                          );

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reminder Scheduled!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800), // Action Orange
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Schedule Reminder',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
      prefixIcon: Icon(icon, color: const Color(0xFF4285F4)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4285F4), width: 2),
      ),
    );
  }
}
