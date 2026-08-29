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
          error: (_, _) => const Text("Workspace Error"),
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
            // Master Financial Summary Card
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
          "Log Entry",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showLogSplitBottomSheet(context),
      ),
    );
  }

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
                "Total Collected",
                summary.totalCollected.toStringAsFixed(0),
                theme.colorScheme.primary,
              ),
              _buildMetricItem(
                "Pool Cash Left",
                summary.remainingPoolCash.toStringAsFixed(0),
                summary.remainingPoolCash >= 0
                    ? (theme.brightness == Brightness.light
                          ? const Color(0xFF00C853)
                          : const Color(0xFF00E676))
                    : theme.colorScheme.error,
              ),
              _buildMetricItem(
                "Group Spent",
                summary.totalGroupSpent.toStringAsFixed(0),
                theme.colorScheme.onSecondary,
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
                    isOwed ? "You are owed back" : "You owe the group",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: balanceColor.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Contributed: ${summary.yourTotalContributed.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSecondary.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                "${isOwed ? '+' : ''}${summary.yourNetBalance.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 26,
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
            letterSpacing: 0.6,
            color: numColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          rawNumber,
          style: TextStyle(
            fontSize: 18,
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
// ISOLATED TRANSACTION FEED SUB-LIST
// =========================================================================
class _TransactionsSubList extends ConsumerWidget {
  final String eventId;
  const _TransactionsSubList({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(activeEventTransactionsProvider(eventId));
    final participants =
        ref.watch(eventParticipantsRosterProvider(eventId)).value ?? [];
    final theme = Theme.of(context);

    return txAsync.when(
      data: (transactions) {
        final sortedTransactions = [...transactions]
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

        if (sortedTransactions.isEmpty) {
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
          itemCount: sortedTransactions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final tx = sortedTransactions[index];
            final payerName =
                participants
                    .cast<EventParticipantModel?>()
                    .firstWhere((p) => p?.id == tx.paidById, orElse: () => null)
                    ?.displayName ??
                "Unknown";

            final bool isDeposit = tx.isFundDeposit;
            final Color badgeBg = isDeposit
                ? (theme.brightness == Brightness.light
                      ? const Color(0xFF00C853).withValues(alpha: 0.12)
                      : const Color(0xFF00E676).withValues(alpha: 0.15))
                : (tx.paidFromPool
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.tertiary.withValues(alpha: 0.12));

            final Color badgeText = isDeposit
                ? (theme.brightness == Brightness.light
                      ? const Color(0xFF00C853)
                      : const Color(0xFF00E676))
                : (tx.paidFromPool
                      ? theme.colorScheme.primary
                      : theme.colorScheme.tertiary);

            final IconData leadingIcon = isDeposit
                ? Icons.savings_outlined
                : (tx.paidFromPool
                      ? Icons.account_balance_wallet_outlined
                      : Icons.person_outline_rounded);

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
              onDismissed: (_) {
                ref
                    .read(activeEventTransactionsProvider(eventId).notifier)
                    .deleteTransaction(tx.id);
              },
              child: Material(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  child: ListTile(
                    onTap: () =>
                        _showTransactionContextOptions(context, ref, tx),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: badgeBg,
                      child: Icon(leadingIcon, color: badgeText),
                    ),
                    title: Text(
                      tx.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isDeposit
                                ? "DEPOSIT"
                                : (tx.paidFromPool
                                      ? "FROM POOL"
                                      : "OUT-OF-POCKET"),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: badgeText,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isDeposit ? "by $payerName" : "• $payerName",
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${isDeposit ? '+' : ''}${tx.totalAmount.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: isDeposit
                                ? badgeText
                                : theme.colorScheme.onSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSecondary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ],
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

  void _showTransactionContextOptions(
    BuildContext context,
    WidgetRef ref,
    EventTransactionModel transaction,
  ) {
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
                transaction.description.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text("Edit Details"),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: theme.colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (_) => _LogSplitSheet(
                    eventId: eventId,
                    existingTransaction: transaction,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error,
              ),
              title: Text(
                "Remove Entry",
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(activeEventTransactionsProvider(eventId).notifier)
                    .deleteTransaction(transaction.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// ADD PARTICIPANT MODAL SHEET
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
              hintText: "Enter name...",
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
// LOG ENTRY SHEET: DUAL-FLOW (COLLECTION / SPENDING)
// =========================================================================
class _LogSplitSheet extends ConsumerStatefulWidget {
  final String eventId;
  final EventTransactionModel? existingTransaction;

  const _LogSplitSheet({required this.eventId, this.existingTransaction});

  @override
  ConsumerState<_LogSplitSheet> createState() => _LogSplitSheetState();
}

class _LogSplitSheetState extends ConsumerState<_LogSplitSheet> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _customCategoryController = TextEditingController();

  // Dual-Flow Toggles
  bool _isDepositMode = false; // true = Pool Influx / Contribution
  bool _isPaidFromPool = true; // true = Cash taken from Common Pool
  bool _isCustomCategoryActive = false;
  bool _isEditMode = false;

  String _selectedCategory = "Food";
  String? _selectedPayerId;

  final List<String> _basePresets = ["Food", "Transport", "Rent", "Utilities"];

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      _isEditMode = true;
      _amountController.text = tx.totalAmount.toStringAsFixed(0);
      _descController.text = tx.description;
      _selectedPayerId = tx.paidById;
      _isDepositMode = tx.isFundDeposit;
      _isPaidFromPool = tx.paidFromPool;

      if (_basePresets.contains(tx.category)) {
        _selectedCategory = tx.category;
        _isCustomCategoryActive = false;
      } else {
        _isCustomCategoryActive = true;
        _customCategoryController.text = tx.category;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final participants =
        ref.watch(eventParticipantsRosterProvider(widget.eventId)).value ?? [];
    final customCategoriesAsync = ref.watch(
      dynamicEventCategoriesProvider(widget.eventId),
    );

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEditMode
                    ? "Modify Entry"
                    : (_isDepositMode ? "Collect Pool Cash" : "Log Expense"),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              // Main Mode Segmented Switch
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text("Expense", style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.outbox_rounded, size: 14),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text("Collect", style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.savings_rounded, size: 14),
                  ),
                ],
                selected: {_isDepositMode},
                onSelectionChanged: (val) {
                  setState(() {
                    _isDepositMode = val.first;
                    if (_isDepositMode) {
                      _isPaidFromPool = false;
                    }
                  });
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
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
                    labelText: "Amount",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: _isDepositMode
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Text(
                          "POOL CONTRIBUTION",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    : (_isCustomCategoryActive
                          ? TextField(
                              controller: _customCategoryController,
                              decoration: InputDecoration(
                                labelText: "Custom Label",
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.cancel),
                                  onPressed: () => setState(
                                    () => _isCustomCategoryActive = false,
                                  ),
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
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                ),
                                const DropdownMenuItem(
                                  value: "ADD_NEW_HOOK",
                                  child: Text(
                                    "+ Add Custom",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val == "ADD_NEW_HOOK") {
                                  setState(
                                    () => _isCustomCategoryActive = true,
                                  );
                                } else if (val != null) {
                                  setState(() => _selectedCategory = val);
                                }
                              },
                            )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: _isDepositMode
                  ? "Deposit Note (e.g., Round 1 Contribution)"
                  : "What was this for?",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Expense Source Selection
          if (!_isDepositMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPaidFromPool
                        ? Icons.account_balance_wallet_rounded
                        : Icons.account_circle_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isPaidFromPool
                          ? "Paid from Common Pool (Fund)"
                          : "Paid by Individual (Out-of-Pocket)",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isPaidFromPool,
                    onChanged: (val) => setState(() => _isPaidFromPool = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Payer Dropdown
          if (participants.isNotEmpty && (!_isPaidFromPool || _isDepositMode))
            DropdownButtonFormField<String>(
              value: _selectedPayerId,
              decoration: InputDecoration(
                labelText: _isDepositMode
                    ? "Who Contributed?"
                    : "Who Paid from Pocket?",
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
                    _descController.text.trim().isEmpty ||
                    participants.isEmpty) {
                  return;
                }

                final effectivePayerId = _isPaidFromPool
                    ? "COMMON_POOL"
                    : (_selectedPayerId ?? participants.first.id);

                final String finalCategoryValue = _isDepositMode
                    ? "Deposit"
                    : (_isCustomCategoryActive
                          ? _customCategoryController.text.trim()
                          : _selectedCategory);

                if (finalCategoryValue.isEmpty) return;

                // Split Equal Matrix Computation
                final Map<String, double> splitMatrix = {};
                if (!_isDepositMode) {
                  final double sharedSlice = parsedAmount / participants.length;
                  for (final p in participants) {
                    splitMatrix[p.id] = sharedSlice;
                  }
                }

                final transactionModel = EventTransactionModel(
                  id: _isEditMode
                      ? widget.existingTransaction!.id
                      : const Uuid().v4(),
                  eventId: widget.eventId,
                  paidById: effectivePayerId,
                  totalAmount: parsedAmount,
                  description: _descController.text.trim(),
                  category: finalCategoryValue,
                  transactionDate: _isEditMode
                      ? widget.existingTransaction!.transactionDate
                      : DateTime.now(),
                  splitDetails: splitMatrix,
                  isFundDeposit: _isDepositMode,
                  paidFromPool: _isPaidFromPool,
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
                _isEditMode
                    ? "Save Changes"
                    : (_isDepositMode ? "Add to Pool" : "Save & Distribute"),
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
