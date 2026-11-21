import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/providers/event_ledger_provider/event_ledger_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:sprint_14/models/event_ledger_model.dart';
import 'package:sprint_14/models/event_participant_model.dart';
import 'event_ledgers_dashboard_view.dart';

IconData eventTypeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'hostel':
      return Icons.hotel_rounded;
    case 'trip':
      return Icons.terrain_rounded;
    case 'function':
      return Icons.celebration_rounded;
    default:
      return Icons.folder_special_rounded;
  }
}

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
    final myUid = ref.watch(authControllerProvider).value?.uid;

    return Scaffold(
      body: ledgersAsync.when(
        data: (ledgersList) {
          return RefreshIndicator(
            // Uploads pending changes AND fetches events shared by others.
            onRefresh: () =>
                ref.read(eventLedgerProvider.notifier).forceRefresh(),
            child: ledgersList.isEmpty
                ? ListView(
                    // Scrollable so pull-to-refresh also works when empty.
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: _buildEmptyHubState(theme),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: ledgersList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ledger = ledgersList[index];
                      return _EventLedgerCard(
                        ledger: ledger,
                        isOwner: ledger.creatorId == myUid,
                        onOpen: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EventLedgersDashboardView(eventId: ledger.id),
                          ),
                        ),
                        onEdit: () => _showCreateLedgerBottomSheet(
                          context,
                          existingLedger: ledger,
                        ),
                        onDelete: () => _confirmDeleteDialog(context, ledger),
                      );
                    },
                  ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text("Couldn't load event ledgers: $err")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new_event_ledger',
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
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
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
              style: TextStyle(color: theme.hintColor, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _showCreateLedgerBottomSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create your first ledger'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDialog(BuildContext context, EventLedgerModel ledger) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete ledger?"),
        content: Text(
          "'${ledger.title}' and all of its members and transactions will be "
          "deleted for everyone in it. This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () {
              ref.read(eventLedgerProvider.notifier).deleteLedger(ledger.id);
              Navigator.pop(dialogContext);
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
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateEventLedgerSheet(existingLedger: existingLedger),
    );
  }
}

// =========================================================================
// LEDGER CARD
// =========================================================================
class _EventLedgerCard extends StatelessWidget {
  final EventLedgerModel ledger;
  final bool isOwner;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventLedgerCard({
    required this.ledger,
    required this.isOwner,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        onLongPress: isOwner ? () => _showOwnerMenu(context) : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                child: Icon(
                  eventTypeIcon(ledger.type),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          ledger.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '  ·  ${DateFormat('d MMM yyyy').format(ledger.createdAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.hintColor,
                          ),
                        ),
                        if (!ledger.isSynced) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 13,
                            color: theme.hintColor,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: theme.hintColor),
                  onSelected: (action) {
                    if (action == 'edit') onEdit();
                    if (action == 'delete') onDelete();
                  },
                  itemBuilder: (context) => _menuItems(theme),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.hintColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _menuItems(ThemeData theme) => [
    const PopupMenuItem(
      value: 'edit',
      child: Row(
        children: [
          Icon(Icons.edit_outlined, size: 18),
          SizedBox(width: 8),
          Text("Edit title"),
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
          Text("Delete", style: TextStyle(color: theme.colorScheme.error)),
        ],
      ),
    ),
  ];

  void _showOwnerMenu(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ledger.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text("Edit title"),
              onTap: () {
                Navigator.pop(sheetContext);
                onEdit();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_sweep_rounded,
                color: theme.colorScheme.error,
              ),
              title: Text(
                "Delete ledger",
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// BOTTOM SHEET: CREATE / EDIT
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
  bool _isSaving = false;
  String? _titleError;
  String? _typeError;

  final List<String> _baseTypes = ["Hostel", "Trip", "Function"];

  bool get _isEditMode => widget.existingLedger != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingLedger;
    if (existing != null) {
      _titleController.text = existing.title;
      final match = _baseTypes.where(
        (t) => t.toLowerCase() == existing.type.trim().toLowerCase(),
      );
      if (match.isNotEmpty) {
        _selectedType = match.first;
      } else {
        _isCustomTypeActive = true;
        _customTypeController.text = existing.type;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final authUser = ref.read(authControllerProvider).value;
    final title = _titleController.text.trim();
    final type = _isCustomTypeActive
        ? _customTypeController.text.trim()
        : _selectedType;

    setState(() {
      _titleError = title.isEmpty ? 'Give the ledger a name' : null;
      _typeError = !_isEditMode && type.isEmpty ? 'Enter a type' : null;
    });
    if (_titleError != null || _typeError != null) return;
    if (authUser == null) return;

    // Capture the navigator before any await so we never use a stale context.
    final navigator = Navigator.of(context);
    setState(() => _isSaving = true);

    if (_isEditMode) {
      await ref
          .read(eventLedgerProvider.notifier)
          .updateLedger(widget.existingLedger!.copyWith(title: title));
      navigator.pop();
      return;
    }

    final newLedgerId = const Uuid().v4();
    final newLedger = EventLedgerModel(
      id: newLedgerId,
      title: title,
      creatorId: authUser.uid,
      type: type.toLowerCase(),
      createdAt: DateTime.now(),
      isSynced: false,
    );
    final me = EventParticipantModel(
      id: const Uuid().v4(),
      eventId: newLedgerId,
      userId: authUser.uid,
      displayName: "You",
      joinedAt: DateTime.now(),
      isSynced: false,
    );

    await ref.read(eventLedgerProvider.notifier).addLedger(newLedger);
    await ref
        .read(eventParticipantsRosterProvider(newLedgerId).notifier)
        .addParticipant(me);

    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => EventLedgersDashboardView(eventId: newLedgerId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditMode ? "Edit Ledger" : "Create Ledger",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: !_isEditMode,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
              decoration: InputDecoration(
                labelText: "Ledger title",
                hintText: "e.g., Room 302 Roomies, Swat Trip 2026...",
                errorText: _titleError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Type is fixed after creation.
            if (!_isEditMode)
              _isCustomTypeActive
                  ? TextField(
                      controller: _customTypeController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Custom ledger type",
                        errorText: _typeError,
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
                      decoration: InputDecoration(
                        labelText: "Ledger type",
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
                            "+ Add custom type",
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
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(
                        _isEditMode ? "Save" : "Create & open",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
