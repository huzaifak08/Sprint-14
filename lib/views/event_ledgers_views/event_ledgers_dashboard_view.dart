import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/providers/event_ledger_provider/event_ledger_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:sprint_14/models/event_participant_model.dart';
import 'package:sprint_14/models/event_transaction_model.dart';

class EventLedgersDashboardView extends ConsumerStatefulWidget {
  final String eventId;

  const EventLedgersDashboardView({super.key, required this.eventId});

  @override
  ConsumerState<EventLedgersDashboardView> createState() =>
      _EventLedgersDashboardViewState();
}

class _EventLedgersDashboardViewState
    extends ConsumerState<EventLedgersDashboardView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledgerAsync = ref.watch(singleEventLedgerProvider(widget.eventId));
    final summaryAsync = ref.watch(
      eventFinancialSummaryProvider(widget.eventId),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ledgerAsync.when(
          data: (ledger) => Text(
            ledger.title.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: theme.colorScheme.onSecondary,
            ),
          ),
          loading: () => const Text("Loading..."),
          error: (_, __) => const Text("Workspace Error"),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sync_rounded, color: theme.colorScheme.primary),
            onPressed: () => ref
                .read(eventLedgerProvider.notifier)
                .syncPendingRecordsToCloud(),
          ),
          IconButton(
            icon: Icon(
              Icons.person_add_alt_1_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: () => _showAddParticipantBottomSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(eventLedgerProvider.notifier).syncPendingRecordsToCloud(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 8),
            // 1. Tactile 3-Number Master Matrix Card
            summaryAsync.when(
              data: (summary) => _buildMetricsCard(theme, summary),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(child: Text("Metrics Error: $err")),
            ),
            const SizedBox(height: 24),
            // 2. Transaction Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ACTIVE TRANSACTIONS",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSecondary.withValues(alpha: 0.6),
                  ),
                ),
                _buildSyncPendingBadge(context),
              ],
            ),
            const SizedBox(height: 12),
            // 3. Isolated High-Performance Transaction List
            _TransactionsSubList(eventId: widget.eventId),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_card_rounded),
        label: const Text(
          "Log Split",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showLogSplitBottomSheet(context),
      ),
    );
  }

  // =========================================================================
  // Master Matrix Widget Components
  // =========================================================================
  Widget _buildMetricsCard(ThemeData theme, EventFinancialSummary summary) {
    final bool isOwed = summary.yourNetBalance >= 0;
    final Color balanceColor = isOwed
        ? (theme.brightness == Brightness.light
              ? const Color(0xFF00C853)
              : const Color(0xFF00E676))
        : theme.colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem(
                "Group Total Spent",
                summary.totalGroupSpent.toStringAsFixed(0),
                theme.colorScheme.onSecondary,
              ),
              _buildMetricItem(
                "Your Contributions",
                summary.yourTotalPaid.toStringAsFixed(0),
                theme.colorScheme.primary,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "YOUR NET STANDING",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: theme.colorScheme.onSecondary.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOwed ? "You are owed money" : "You owe money",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: balanceColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              Text(
                "${isOwed ? '+' : ''}${summary.yourNetBalance.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: balanceColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String title, String rawNumber, Color numColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: numColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          rawNumber,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: numColor,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSyncPendingBadge(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final list =
            ref.watch(activeEventTransactionsProvider(widget.eventId)).value ??
            [];
        if (list.any((tx) => !tx.isSynced)) {
          final theme = Theme.of(context);
          return Card(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            elevation: 0,
            shape: const StadiumBorder(),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                "UNSYNCED CHANGES",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // =========================================================================
  // Modals sheets initialization pipelines
  // =========================================================================
  void _showAddParticipantBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddParticipantSheet(eventId: widget.eventId),
    );
  }

  void _showLogSplitBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LogSplitSheet(eventId: widget.eventId),
    );
  }
}

// =========================================================================
// ISOLATED LIST CONSUMER (Ensures dashboard metric cards don't jitter)
// =========================================================================
class _TransactionsSubList extends ConsumerWidget {
  final String eventId;
  const _TransactionsSubList({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(activeEventTransactionsProvider(eventId));
    final theme = Theme.of(context);

    return txAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                "No transactions recorded yet.",
                style: TextStyle(
                  color: theme.colorScheme.onSecondary.withValues(alpha: 0.4),
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return Dismissible(
              key: Key(tx.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.white,
                ),
              ),
              onDismissed: (_) => ref
                  .read(activeEventTransactionsProvider(eventId).notifier)
                  .deleteTransaction(tx.id),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    tx.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    tx.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  trailing: Text(
                    tx.totalAmount.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSecondary,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text("Error: $err"),
    );
  }
}

// =========================================================================
// MULTI-USER / GUEST ROSTER ONBOARDING SHEET
// =========================================================================
class _AddParticipantSheet extends ConsumerStatefulWidget {
  final String eventId;
  const _AddParticipantSheet({required this.eventId});

  @override
  ConsumerState<_AddParticipantSheet> createState() =>
      _AddParticipantSheetState();
}

class _AddParticipantSheetState extends ConsumerState<_AddParticipantSheet> {
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            "Add Workspace Member",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Participant Name",
              hintText: "Enter manual name or linked handle...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
              onPressed: () {
                if (_nameController.text.trim().isEmpty) return;
                final newParticipant = EventParticipantModel(
                  id: const Uuid().v4(),
                  eventId: widget.eventId,
                  displayName: _nameController.text.trim(),
                  joinedAt: DateTime.now(),
                  isSynced: false,
                );
                ref
                    .read(
                      eventParticipantsRosterProvider(widget.eventId).notifier,
                    )
                    .addParticipant(newParticipant);
                Navigator.pop(context);
              },
              child: Text(
                "Add to Workspace",
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

// =========================================================================
// LOG SPLIT BOTTOM SHEET WITH CACHED CUSTOM CATEGORY INJECTION
// =========================================================================
class _LogSplitSheet extends ConsumerStatefulWidget {
  final String eventId;
  const _LogSplitSheet({required this.eventId});

  @override
  ConsumerState<_LogSplitSheet> createState() => _LogSplitSheetState();
}

class _LogSplitSheetState extends ConsumerState<_LogSplitSheet> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _customCategoryController = TextEditingController();

  String _selectedCategory = "Food";
  String? _selectedPayerId;
  bool _isCustomCategoryActive = false;

  final List<String> _basePresets = ["Food", "Transport", "Rent", "Utilities"];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final participants =
        ref.watch(eventParticipantsRosterProvider(widget.eventId)).value ?? [];
    final customCategoriesAsync = ref.watch(
      dynamicEventCategoriesProvider(widget.eventId),
    );

    // Consolidate default presets with dynamically loaded SQLite distinct category strings
    final List<String> allCategories = {
      ..._basePresets,
      ...(customCategoriesAsync.value ?? []),
    }.toList();

    if (_selectedPayerId == null && participants.isNotEmpty) {
      _selectedPayerId = participants.first.id;
    }

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
            "Log Split Transaction",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: "Number Value",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: _isCustomCategoryActive
                    ? TextField(
                        controller: _customCategoryController,
                        decoration: InputDecoration(
                          labelText: "Custom Label",
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: () =>
                                setState(() => _isCustomCategoryActive = false),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        value: allCategories.contains(_selectedCategory)
                            ? _selectedCategory
                            : allCategories.first,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          ...allCategories.map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          ),
                          const DropdownMenuItem(
                            value: "ADD_NEW_HOOK",
                            child: Text(
                              "+ Add Custom",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == "ADD_NEW_HOOK") {
                            setState(() => _isCustomCategoryActive = true);
                          } else if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: "What was this for?",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (participants.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _selectedPayerId,
              hint: Text("Who Paid Out-of-Pocket?"),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: participants
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedPayerId = val),
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
              onPressed: () {
                final double? parsedAmount = double.tryParse(
                  _amountController.text,
                );
                if (parsedAmount == null ||
                    _descController.text.isEmpty ||
                    _selectedPayerId == null)
                  return;

                final String finalCategoryValue = _isCustomCategoryActive
                    ? _customCategoryController.text.trim()
                    : _selectedCategory;
                if (finalCategoryValue.isEmpty) return;

                // EQUAL SPLIT MATRIX GENERATOR ENGINE
                final double sharedCostSlice =
                    parsedAmount / participants.length;
                final Map<String, double> equalSplitDetailsMatrix = {
                  for (final p in participants) p.id: sharedCostSlice,
                };

                final transactionModel = EventTransactionModel(
                  id: const Uuid().v4(),
                  eventId: widget.eventId,
                  paidById: _selectedPayerId!,
                  totalAmount: parsedAmount,
                  description: _descController.text.trim(),
                  category: finalCategoryValue,
                  transactionDate: DateTime.now(),
                  splitDetails: equalSplitDetailsMatrix,
                  isSynced: false,
                );

                ref
                    .read(
                      activeEventTransactionsProvider(widget.eventId).notifier,
                    )
                    .addTransaction(transactionModel);
                Navigator.pop(context);
              },
              child: Text(
                "Save & Distribute",
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
