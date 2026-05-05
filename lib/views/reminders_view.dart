import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/providers/reminders_provider/reminders_provider.dart';
import 'package:sprint_14/providers/theme_provider/theme_provider.dart';
import 'package:sprint_14/views/add_reminder_view.dart';

class RemindersView extends ConsumerWidget {
  const RemindersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Active Reminders",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddReminderView()),
            ),
            icon: const Icon(Icons.add_circle_outline, size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: reminders.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reminders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                return _buildReminderCard(context, ref, reminder);
              },
            ),
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    WidgetRef ref,
    PendingNotificationRequest reminder,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: ref.watch(themeNotifier).themeMode == ThemeMode.light
            ? Colors.white
            : Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Color Accent Bar
              Container(
                width: 6,
                color: const Color(0xFFFF9800), // Action Orange
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              reminder.title ?? "No Title",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // ID Badge
                          Text(
                            "ID: ${reminder.id}",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reminder.body ?? "No Description",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // SCHEDULED DATE & TIME SECTION
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_filled,
                              size: 14,
                              color: Color(0xFF4285F4),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              // Displaying the payload which contains our DateTime string
                              reminder.payload ?? "No time set",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Delete Action
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => ref
                      .read(remindersProvider.notifier)
                      .cancelReminder(reminderId: reminder.id),
                  child: Container(
                    width: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No pending reminders",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your 14-day schedule is clear!",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
