import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/providers/event_ledger_provider/event_ledger_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:sprint_14/models/event_ledger_model.dart';
import 'package:sprint_14/models/event_participant_model.dart';
import 'event_ledgers_dashboard_view.dart'; // Import your inner dashboard

class EventLedgersView extends ConsumerStatefulWidget {
  const EventLedgersView({super.key});

  @override
  ConsumerState<EventLedgersView> createState() => _EventLedgersViewState();
}

class _EventLedgersViewState extends ConsumerState<EventLedgersView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledgersAsync = ref.watch(eventLedgerProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "EVENT LEDGERS",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: theme.colorScheme.onSecondary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sync_rounded, color: theme.colorScheme.primary),
            onPressed: () => ref
                .read(eventLedgerProvider.notifier)
                .syncPendingRecordsToCloud(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ledgersAsync.when(
        data: (ledgersList) {
          if (ledgersList.isEmpty) {
            return _buildEmptyHubState(theme);
          }

          return RefreshIndicator(
            onRefresh: () async => ref
                .read(eventLedgerProvider.notifier)
                .syncPendingRecordsToCloud(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ledgersList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ledger = ledgersList[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to individual dashboard space safely passing the loaded ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EventLedgersDashboardView(eventId: ledger.id),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Icon(
                            _getLedgerTypeIcon(ledger.type),
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ledger.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ledger.type.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: theme.colorScheme.onSecondary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text("Error fetching ledger spaces: $err")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.create_new_folder_rounded),
        label: const Text(
          "New Ledger",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showCreateLedgerBottomSheet(context),
      ),
    );
  }

  Widget _buildEmptyHubState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: theme.colorScheme.onSecondary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              "No Event Ledgers Yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              "Create a ledger to split hostel bills, track road trips, or manage functions with friends.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSecondary.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getLedgerTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hostel':
        return Icons.hotel_rounded;
      case 'trip':
        return Icons.terrain_rounded;
      case 'function':
        return Icons.celebration_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  void _showCreateLedgerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CreateEventLedgerSheet(),
    );
  }
}

// =========================================================================
// BOTTOM SHEET: CREATION MODAL WITH USER-ORIENTED EXPANSION ENGINE
// =========================================================================
class _CreateEventLedgerSheet extends ConsumerStatefulWidget {
  const _CreateEventLedgerSheet();

  @override
  ConsumerState<_CreateEventLedgerSheet> createState() =>
      _CreateEventLedgerSheetState();
}

class _CreateEventLedgerSheetState
    extends ConsumerState<_CreateEventLedgerSheet> {
  final _titleController = TextEditingController();
  final _customTypeController = TextEditingController();

  String _selectedType = "Hostel";
  bool _isCustomTypeActive = false;

  final List<String> _baseTypes = ["Hostel", "Trip", "Function"];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authUser = ref.watch(authControllerProvider).value;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Create Project Ledger",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: "Ledger Title",
              hintText: "e.g., Room 302 Roomies, Swat Trip 2026...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _isCustomTypeActive
              ? TextField(
                  controller: _customTypeController,
                  decoration: InputDecoration(
                    labelText: "Custom Ledger Type",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: () =>
                          setState(() => _isCustomTypeActive = false),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              : DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  hint: Text("Ledger Classification Type"),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    ..._baseTypes.map(
                      (t) => DropdownMenuItem(value: t, child: Text(t)),
                    ),
                    const DropdownMenuItem(
                      value: "ADD_CUSTOM_TYPE",
                      child: Text(
                        "+ Add Custom Type",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val == "ADD_CUSTOM_TYPE") {
                      setState(() => _isCustomTypeActive = true);
                    } else if (val != null) {
                      setState(() => _selectedType = val);
                    }
                  },
                ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (_titleController.text.trim().isEmpty || authUser == null)
                  return;

                final String finalType = _isCustomTypeActive
                    ? _customTypeController.text.trim()
                    : _selectedType;
                if (finalType.isEmpty) return;

                final String newLedgerId = const Uuid().v4();

                final newLedger = EventLedgerModel(
                  id: newLedgerId,
                  title: _titleController.text.trim(),
                  creatorId: authUser.uid,
                  type: finalType.toLowerCase(),
                  createdAt: DateTime.now(),
                  isSynced: false,
                );

                // 🔥 CRITICAL: Automatically add the creator as Participant #1 in this new ledger workspace
                final autoParticipant = EventParticipantModel(
                  id: const Uuid().v4(),
                  eventId: newLedgerId,
                  userId: authUser.uid,
                  displayName: "You",
                  joinedAt: DateTime.now(),
                  isSynced: false,
                );

                // Save both to local db and fire cloud synchronization chain
                await ref
                    .read(eventLedgerProvider.notifier)
                    .addLedger(newLedger);
                await ref
                    .read(eventParticipantsRosterProvider(newLedgerId).notifier)
                    .addParticipant(autoParticipant);

                Navigator.pop(context);

                // Immediately open the newly generated empty workspace view safely
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EventLedgersDashboardView(eventId: newLedgerId),
                  ),
                );
              },
              child: Text(
                "Launch Workspace",
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
