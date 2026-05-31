import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/helpers/app_data.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/providers/event_ledger_provider/event_ledger_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:sprint_14/models/event_ledger_model.dart';
import 'package:sprint_14/models/event_participant_model.dart';
import 'event_ledgers_dashboard_view.dart';

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
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ledger = ledgersList[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EventLedgersDashboardView(eventId: ledger.id),
                      ),
                    );
                  },
                  onLongPress: () => _showEditDeleteMenu(
                    context,
                    ledger,
                  ), // 🔥 Option 1: Long Press Access
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                        // 🔥 Option 2: Clean Trailing Menu Options Button
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: theme.colorScheme.onSecondary.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          onSelected: (action) {
                            if (action == 'edit') {
                              _showCreateLedgerBottomSheet(
                                context,
                                existingLedger: ledger,
                              );
                            } else if (action == 'delete') {
                              _confirmDeleteDialog(context, ledger);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text("Edit Title"),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Delete",
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  void _showEditDeleteMenu(BuildContext context, EventLedgerModel ledger) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                ledger.title.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text("Edit Ledger Details"),
              onTap: () {
                Navigator.pop(context);
                _showCreateLedgerBottomSheet(context, existingLedger: ledger);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_sweep_rounded,
                color: theme.colorScheme.error,
              ),
              title: Text(
                "Delete Workspace",
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteDialog(context, ledger);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDialog(BuildContext context, EventLedgerModel ledger) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Ledger?"),
        content: Text(
          "Are you completely sure you want to remove '${ledger.title}'? This action can sync changes away across all shared members.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(eventLedgerProvider.notifier).deleteLedger(ledger.id);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showCreateLedgerBottomSheet(
    BuildContext context, {
    EventLedgerModel? existingLedger,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateEventLedgerSheet(existingLedger: existingLedger),
    );
  }
}

// =========================================================================
// BOTTOM SHEET: CREATION & EDIT MODAL PAYLOAD ENGINE
// =========================================================================
class _CreateEventLedgerSheet extends ConsumerStatefulWidget {
  final EventLedgerModel? existingLedger;
  const _CreateEventLedgerSheet({this.existingLedger});

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
  bool _isEditMode = false;

  final List<String> _baseTypes = ["Hostel", "Trip", "Function"];

  @override
  void initState() {
    super.initState();
    if (widget.existingLedger != null) {
      _isEditMode = true;
      _titleController.text = widget.existingLedger!.title;

      // Match incoming type configuration values cleanly
      final String formattedType = widget.existingLedger!.type.trim();
      final bool matchesPreset = _baseTypes.any(
        (t) => t.toLowerCase() == formattedType.toLowerCase(),
      );

      if (matchesPreset) {
        _selectedType = _baseTypes.firstWhere(
          (t) => t.toLowerCase() == formattedType.toLowerCase(),
        );
        _isCustomTypeActive = false;
      } else {
        _isCustomTypeActive = true;
        _customTypeController.text = widget.existingLedger!.type;
      }
    }
  }

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
          Text(
            _isEditMode ? "Modify Ledger Settings" : "Create Project Ledger",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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
          // 🔥 Only allow editing classification type if creating new workspace to prevent transaction schema crashes
          if (!_isEditMode)
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
                    initialValue:
                        _selectedType, // Fixed initialValue crash bug pass rule here
                    decoration: InputDecoration(
                      labelText: "Ledger Classification Type",
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
                if (_titleController.text.trim().isEmpty || authUser == null) {
                  return;
                }

                if (_isEditMode) {
                  // 🔥 EXECUTE UPDATE TASK
                  final updatedLedger = widget.existingLedger!.copyWith(
                    title: _titleController.text.trim(),
                  );
                  await ref
                      .read(eventLedgerProvider.notifier)
                      .updateLedger(updatedLedger);
                  Navigator.pop(
                    AppData.shared.navigatorKey.currentContext ?? context,
                  );
                } else {
                  // 🔥 EXECUTE NEW TARGET ENTRY GENERATION
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

                  final autoParticipant = EventParticipantModel(
                    id: const Uuid().v4(),
                    eventId: newLedgerId,
                    userId: authUser.uid,
                    displayName: "You",
                    joinedAt: DateTime.now(),
                    isSynced: false,
                  );

                  await ref
                      .read(eventLedgerProvider.notifier)
                      .addLedger(newLedger);
                  await ref
                      .read(
                        eventParticipantsRosterProvider(newLedgerId).notifier,
                      )
                      .addParticipant(autoParticipant);

                  Navigator.pop(
                    AppData.shared.navigatorKey.currentContext ?? context,
                  );

                  Navigator.push(
                    AppData.shared.navigatorKey.currentContext ?? context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EventLedgersDashboardView(eventId: newLedgerId),
                    ),
                  );
                }
              },
              child: Text(
                _isEditMode ? "Save Workspace Details" : "Launch Workspace",
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
