import 'package:flutter/material.dart';
import 'package:sprint_14/components/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sprint_14/helpers/theme_widgets.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/providers/event_ledger_provider/event_ledger_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:sprint_14/models/event_participant_model.dart';
import 'package:sprint_14/models/event_transaction_model.dart';

import 'event_balances.dart';
import 'event_ledgers_view.dart' show eventTypeIcon;

final _money = NumberFormat('#,##0.##');
String _fmt(double v) => _money.format(v);

/// The current user's participant record in this event (if any).
EventParticipantModel? _me(List<EventParticipantModel> people, String? uid) {
  if (uid == null) return null;
  for (final p in people) {
    if (p.userId == uid) return p;
  }
  return null;
}

String _payerName(
  EventTransactionModel tx,
  List<EventParticipantModel> people,
) {
  if (tx.paidFromPool && !tx.isFundDeposit) return 'Common pool';
  for (final p in people) {
    if (p.id == tx.paidById) return p.displayName;
  }
  return 'Removed member';
}

Future<bool> _confirmDelete(BuildContext context, String what) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete $what?'),
      content: const Text("This can't be undone."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}

class EventLedgersDashboardView extends ConsumerStatefulWidget {
  final String eventId;

  const EventLedgersDashboardView({super.key, required this.eventId});

  @override
  ConsumerState<EventLedgersDashboardView> createState() =>
      _EventLedgersDashboardViewState();
}

enum _TxFilter { all, deposits, pool, pocket }

extension on _TxFilter {
  String get label => switch (this) {
    _TxFilter.all => 'All',
    _TxFilter.deposits => 'Deposits',
    _TxFilter.pool => 'From pool',
    _TxFilter.pocket => 'Out of pocket',
  };

  bool matches(EventTransactionModel t) => switch (this) {
    _TxFilter.all => true,
    _TxFilter.deposits => t.isFundDeposit,
    _TxFilter.pool => !t.isFundDeposit && t.paidFromPool,
    _TxFilter.pocket => !t.isFundDeposit && !t.paidFromPool,
  };
}

class _EventLedgersDashboardViewState
    extends ConsumerState<EventLedgersDashboardView> {
  bool _syncing = false;
  _TxFilter _filter = _TxFilter.all;
  String? _categoryFilter;

  Future<void> _sync({bool showResult = true}) async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await ref.read(eventLedgerProvider.notifier).forceRefresh();
      if (showResult) AppToast.success('Synced');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledgerAsync = ref.watch(singleEventLedgerProvider(widget.eventId));
    final summaryAsync = ref.watch(
      eventFinancialSummaryProvider(widget.eventId),
    );
    final txAsync = ref.watch(activeEventTransactionsProvider(widget.eventId));
    final people =
        ref.watch(eventParticipantsRosterProvider(widget.eventId)).value ??
        const <EventParticipantModel>[];
    final myUid = ref.watch(authControllerProvider).value?.uid;

    final all = [...(txAsync.value ?? <EventTransactionModel>[])]
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    final hasUnsynced = all.any((t) => !t.isSynced);

    final visible = all
        .where(_filter.matches)
        .where(
          (t) =>
              _categoryFilter == null ||
              (!t.isFundDeposit && t.category == _categoryFilter),
        )
        .toList();
    final rows = _groupByDay(visible);

    // Expense totals per category (for the category strip).
    final byCategory = <String, double>{};
    for (final t in all) {
      if (t.isFundDeposit) continue;
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.totalAmount;
    }
    final categories = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: ledgerAsync.when(
          data: (ledger) => Row(
            children: [
              Icon(
                eventTypeIcon(ledger.type),
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ledger.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      ledger.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Text("Loading..."),
          error: (_, _) => const Text("Ledger not found"),
        ),
        actions: [
          IconButton(
            tooltip: hasUnsynced ? 'Sync (changes pending)' : 'Sync',
            onPressed: _syncing ? null : _sync,
            icon: _syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Badge(
                    isLabelVisible: hasUnsynced,
                    smallSize: 8,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(
                      Icons.sync_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
          ),
          IconButton(
            tooltip: 'Members & balances',
            icon: Icon(Icons.groups_rounded, color: theme.colorScheme.primary),
            onPressed: () => _showMembersSheet(context, widget.eventId),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _sync(showResult: false),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              sliver: SliverToBoxAdapter(
                child: summaryAsync.when(
                  data: (summary) => _HeroHeader(
                    summary: summary,
                    people: people,
                    myUid: myUid,
                    onMembers: () => _showMembersSheet(context, widget.eventId),
                  ),
                  loading: () => const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Text("Couldn't calculate totals: $err"),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _SettleUpCard(
                  eventId: widget.eventId,
                  transactions: all,
                  people: people,
                ),
              ),
            ),
            if (categories.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _CategoryStrip(
                    categories: categories,
                    selected: _categoryFilter,
                    onTap: (c) => setState(
                      () => _categoryFilter = _categoryFilter == c ? null : c,
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      'Transactions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: ShapeDecoration(
                        shape: const StadiumBorder(),
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                      ),
                      child: Text(
                        '${visible.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (all.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ChipTheme(
                    data: themedChips(theme),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final f in _TxFilter.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                '${f.label} · ${all.where(f.matches).length}',
                              ),
                              selected: _filter == f,
                              showCheckmark: false,
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) => setState(() => _filter = f),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            if (txAsync.isLoading && all.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (all.isEmpty)
              SliverToBoxAdapter(child: _EmptyTransactions())
            else if (visible.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        'Nothing matches this filter.',
                        style: TextStyle(color: theme.hintColor),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _filter = _TxFilter.all;
                          _categoryFilter = null;
                        }),
                        child: const Text('Show everything'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    if (row is _DayGroup) return _DayHeader(group: row);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TransactionTile(
                        eventId: widget.eventId,
                        tx: row as EventTransactionModel,
                        people: people,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'log_event_entry',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_card_rounded),
        label: const Text(
          "Log entry",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showLogSheet(context, widget.eventId),
      ),
    );
  }

  List<Object> _groupByDay(List<EventTransactionModel> items) {
    final rows = <Object>[];
    _DayGroup? group;
    for (final t in items) {
      final day = DateTime(
        t.transactionDate.year,
        t.transactionDate.month,
        t.transactionDate.day,
      );
      if (group == null || group.day != day) {
        group = _DayGroup(day);
        rows.add(group);
      }
      if (t.isFundDeposit) {
        group.inflow += t.totalAmount;
      } else {
        group.outflow += t.totalAmount;
      }
      rows.add(t);
    }
    return rows;
  }
}

class _DayGroup {
  final DateTime day;
  double inflow = 0;
  double outflow = 0;
  _DayGroup(this.day);
}

class _DayHeader extends StatelessWidget {
  final _DayGroup group;
  const _DayHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final String label;
    if (group.day == today) {
      label = 'Today';
    } else if (group.day == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else {
      label = DateFormat(
        group.day.year == now.year ? 'EEE, d MMM' : 'EEE, d MMM yyyy',
      ).format(group.day);
    }
    final parts = [
      if (group.inflow > 0) '+${_fmt(group.inflow)} in',
      if (group.outflow > 0) '${_fmt(group.outflow)} spent',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(color: theme.dividerColor.withValues(alpha: 0.3)),
          ),
          const SizedBox(width: 8),
          Text(
            parts.join(' · '),
            style: TextStyle(fontSize: 11, color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 100),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No entries yet',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Start by adding money to the pool, or log an expense someone paid.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final List<MapEntry<String, double>> categories;
  final String? selected;
  final ValueChanged<String> onTap;

  const _CategoryStrip({
    required this.categories,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = categories.fold<double>(0, (s, e) => s + e.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Spending by category',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final e = categories[i];
              final isSel = selected == e.key;
              final share = total == 0 ? 0.0 : e.value / total;
              return Material(
                color: isSel
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onTap(e.key),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: isSel ? 0 : 0.12,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSel
                                ? theme.colorScheme.onPrimary
                                : theme.hintColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _fmt(e.value),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isSel
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: share,
                            minHeight: 4,
                            color: isSel
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                            backgroundColor:
                                (isSel
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.primary)
                                    .withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

void _showLogSheet(
  BuildContext context,
  String eventId, {
  EventTransactionModel? existing,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        _LogSplitSheet(eventId: eventId, existingTransaction: existing),
  );
}

void _showMembersSheet(BuildContext context, String eventId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => _MembersSheet(eventId: eventId),
  );
}

// =========================================================================
// HERO HEADER
// =========================================================================
class _HeroHeader extends StatelessWidget {
  final EventFinancialSummary summary;
  final List<EventParticipantModel> people;
  final String? myUid;
  final VoidCallback onMembers;

  const _HeroHeader({
    required this.summary,
    required this.people,
    required this.myUid,
    required this.onMembers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final on = cs.onPrimary;
    final net = summary.yourNetBalance;
    final isSquare = net.abs() < 0.01;
    final isOwed = net > 0;

    final status = isSquare
        ? "You're all square"
        : (isOwed ? 'You get back' : 'You owe the group');
    final statusIcon = isSquare
        ? Icons.check_circle_rounded
        : (isOwed ? Icons.south_west_rounded : Icons.north_east_rounded);

    final collected = summary.totalCollected;
    final poolSpent = summary.totalPoolSpent;
    final poolUse = collected <= 0
        ? 0.0
        : (poolSpent / collected).clamp(0.0, 1.0);
    final overspent = summary.remainingPoolCash < 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, Color.lerp(cs.primary, Colors.black, 0.28)!],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: on.withValues(alpha: 0.15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: on),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        color: on,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _AvatarStack(people: people, myUid: myUid, onTap: onMembers),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'YOUR STANDING',
            style: TextStyle(
              color: on.withValues(alpha: 0.7),
              fontSize: 10,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              isSquare ? '0' : '${isOwed ? '+' : '−'}${_fmt(net.abs())}',
              style: TextStyle(
                color: on,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ),
          Text(
            'You put in ${_fmt(summary.yourTotalContributed)}',
            style: TextStyle(color: on.withValues(alpha: 0.75), fontSize: 12),
          ),
          if (collected > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Pool used',
                  style: TextStyle(
                    color: on.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  overspent
                      ? 'Overspent by ${_fmt(-summary.remainingPoolCash)}'
                      : '${(poolUse * 100).toStringAsFixed(0)}% · ${_fmt(summary.remainingPoolCash)} left',
                  style: TextStyle(
                    color: on,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: overspent ? 1 : poolUse,
                minHeight: 8,
                color: overspent ? cs.error : on,
                backgroundColor: on.withValues(alpha: 0.18),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _glassStat(on, Icons.savings_rounded, 'Collected', collected),
              const SizedBox(width: 8),
              _glassStat(
                on,
                Icons.account_balance_wallet_rounded,
                'Pool left',
                summary.remainingPoolCash,
              ),
              const SizedBox(width: 8),
              _glassStat(
                on,
                Icons.shopping_bag_rounded,
                'Group spent',
                summary.totalGroupSpent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassStat(Color on, IconData icon, String label, double value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: on.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: on.withValues(alpha: 0.85)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _fmt(value),
                style: TextStyle(
                  color: on,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: on.withValues(alpha: 0.7), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlapping member avatars; tap to manage members.
class _AvatarStack extends StatelessWidget {
  final List<EventParticipantModel> people;
  final String? myUid;
  final VoidCallback onTap;

  const _AvatarStack({
    required this.people,
    required this.myUid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final on = cs.onPrimary;
    const size = 28.0;
    const overlap = 18.0;
    final shown = people.take(4).toList();
    final extra = people.length - shown.length;
    final count = shown.length + (extra > 0 ? 1 : 0) + 1; // +1 add button

    Widget bubble(Widget child, {Color? bg}) => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg ?? on,
        border: Border.all(color: cs.primary, width: 2),
      ),
      child: child,
    );

    final children = <Widget>[
      for (final p in shown)
        bubble(
          Text(
            p.displayName.isEmpty
                ? '?'
                : p.displayName.characters.first.toUpperCase(),
            style: TextStyle(
              color: cs.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      if (extra > 0)
        bubble(
          Text(
            '+$extra',
            style: TextStyle(
              color: cs.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      bubble(
        Icon(Icons.person_add_alt_1_rounded, size: 14, color: on),
        bg: on.withValues(alpha: 0.25),
      ),
    ];

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + (count - 1) * overlap,
        height: size,
        child: Stack(
          children: [
            for (var i = 0; i < children.length; i++)
              Positioned(left: i * overlap, child: children[i]),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// SETTLE-UP PREVIEW
// =========================================================================
class _SettleUpCard extends StatelessWidget {
  final String eventId;
  final List<EventTransactionModel> transactions;
  final List<EventParticipantModel> people;

  const _SettleUpCard({
    required this.eventId,
    required this.transactions,
    required this.people,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (transactions.isEmpty || people.isEmpty) return const SizedBox.shrink();

    final balances = computeMemberBalances(
      transactions: transactions,
      participants: people,
    );
    final pool = _poolRemaining(transactions);
    final transfers = suggestSettlements(balances, poolRemaining: pool);

    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showMembersSheet(context, eventId),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Icon(Icons.handshake_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settle up',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    if (transfers.isEmpty)
                      Text(
                        'Everyone is square',
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      )
                    else
                      for (final t in transfers.take(2))
                        Text(
                          '${t.fromName} → ${t.toName}: ${_fmt(t.amount)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.hintColor,
                          ),
                        ),
                    if (transfers.length > 2)
                      Text(
                        '+${transfers.length - 2} more',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.hintColor),
            ],
          ),
        ),
      ),
    );
  }
}

double _poolRemaining(List<EventTransactionModel> transactions) {
  double collected = 0, spent = 0;
  for (final tx in transactions) {
    if (tx.isFundDeposit) {
      collected += tx.totalAmount;
    } else if (tx.paidFromPool) {
      spent += tx.totalAmount;
    }
  }
  return collected - spent;
}

// =========================================================================
// TRANSACTION TILE
// =========================================================================
class _TransactionTile extends ConsumerWidget {
  final String eventId;
  final EventTransactionModel tx;
  final List<EventParticipantModel> people;

  const _TransactionTile({
    required this.eventId,
    required this.tx,
    required this.people,
  });

  void _delete(WidgetRef ref) {
    ref
        .read(activeEventTransactionsProvider(eventId).notifier)
        .deleteTransaction(tx.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final positive = positiveMoneyColor(theme);
    final isDeposit = tx.isFundDeposit;

    final Color accent = isDeposit
        ? positive
        : (tx.paidFromPool
              ? theme.colorScheme.primary
              : theme.colorScheme.tertiary);
    final IconData icon = isDeposit
        ? Icons.savings_outlined
        : (tx.paidFromPool
              ? Icons.account_balance_wallet_outlined
              : Icons.person_outline_rounded);
    final String kind = isDeposit
        ? "DEPOSIT"
        : (tx.paidFromPool ? "FROM POOL" : "OUT OF POCKET");
    final payer = _payerName(tx, people);
    final splitCount = tx.splitDetails.length;

    final details = [
      isDeposit ? 'by $payer' : payer,
      if (!isDeposit && splitCount > 0)
        splitCount == people.length && people.isNotEmpty
            ? 'split by all'
            : 'split by $splitCount',
      DateFormat('d MMM').format(tx.transactionDate),
    ].join(' · ');

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, 'this entry'),
      onDismissed: (_) => _delete(ref),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_sweep_rounded,
          color: theme.colorScheme.onError,
        ),
      ),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showOptions(context, ref),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: accent.withValues(alpha: 0.12),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              kind,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: accent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              details,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${isDeposit ? '+' : ''}${_fmt(tx.totalAmount)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isDeposit
                            ? positive
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (!tx.isSynced)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(
                          Icons.cloud_off_rounded,
                          size: 13,
                          color: theme.hintColor,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
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
              tx.description,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text("Edit entry"),
              onTap: () {
                Navigator.pop(sheetContext);
                _showLogSheet(context, eventId, existing: tx);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error,
              ),
              title: Text(
                "Delete entry",
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                if (await _confirmDelete(context, 'this entry')) _delete(ref);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// MEMBERS & BALANCES SHEET
// =========================================================================
class _MembersSheet extends ConsumerStatefulWidget {
  final String eventId;
  const _MembersSheet({required this.eventId});

  @override
  ConsumerState<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends ConsumerState<_MembersSheet> {
  final _nameController = TextEditingController();
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addMember(List<EventParticipantModel> people) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Enter a name');
      return;
    }
    if (people.any((p) => p.displayName.toLowerCase() == name.toLowerCase())) {
      setState(() => _nameError = '$name is already in this ledger');
      return;
    }
    ref
        .read(eventParticipantsRosterProvider(widget.eventId).notifier)
        .addParticipant(
          EventParticipantModel(
            id: const Uuid().v4(),
            eventId: widget.eventId,
            displayName: name,
            joinedAt: DateTime.now(),
            isSynced: false,
          ),
        );
    _nameController.clear();
    setState(() => _nameError = null);
  }

  Future<void> _rename(EventParticipantModel p) async {
    final controller = TextEditingController(text: p.displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename member'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.pop(dialogContext, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || newName == p.displayName) return;
    ref
        .read(eventParticipantsRosterProvider(widget.eventId).notifier)
        .renameParticipant(p.id, newName);
  }

  Future<void> _remove(EventParticipantModel p) async {
    if (!await _confirmDelete(context, p.displayName)) return;
    ref
        .read(eventParticipantsRosterProvider(widget.eventId).notifier)
        .removeParticipant(p.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final people =
        ref.watch(eventParticipantsRosterProvider(widget.eventId)).value ??
        const <EventParticipantModel>[];
    final transactions =
        ref.watch(activeEventTransactionsProvider(widget.eventId)).value ??
        const <EventTransactionModel>[];
    final myUid = ref.watch(authControllerProvider).value?.uid;
    final me = _me(people, myUid);

    final balances = computeMemberBalances(
      transactions: transactions,
      participants: people,
    )..sort((a, b) => b.net.compareTo(a.net));
    final pool = _poolRemaining(transactions);
    final transfers = suggestSettlements(balances, poolRemaining: pool);
    final positive = positiveMoneyColor(theme);
    final negative = negativeMoneyColor(theme);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              'Members & balances',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addMember(people),
                    onChanged: (_) {
                      if (_nameError != null) {
                        setState(() => _nameError = null);
                      }
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Add a member',
                      hintText: 'Name',
                      errorText: _nameError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Add',
                  onPressed: () => _addMember(people),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            for (final b in balances)
              _memberRow(
                theme,
                b,
                isMe: b.participant.id == me?.id,
                positive: positive,
                negative: negative,
              ),
            if (pool.abs() >= 0.01) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pool > 0
                          ? 'Unspent cash in the common pool'
                          : 'Pool overspent (members must cover it)',
                    ),
                  ),
                  Text(
                    _fmt(pool),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: pool > 0 ? positive : negative,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Suggested payments to settle up',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (transfers.isEmpty)
              Text(
                transactions.isEmpty
                    ? 'Add some entries first.'
                    : 'Everyone is square. Nothing to pay.',
                style: TextStyle(color: theme.hintColor),
              )
            else
              for (final t in transfers)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: t.fromName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(text: '  pays  '),
                              TextSpan(
                                text: t.toName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        _fmt(t.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            if (transfers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '"Pool" means whoever is holding the common pool cash.',
                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _memberRow(
    ThemeData theme,
    MemberBalance b, {
    required bool isMe,
    required Color positive,
    required Color negative,
  }) {
    final net = b.net;
    final square = net.abs() < 0.01;
    final color = square ? theme.hintColor : (net > 0 ? positive : negative);
    final canRemove = !isMe && b.involvedCount == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              b.participant.displayName.isEmpty
                  ? '?'
                  : b.participant.displayName.characters.first.toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe
                      ? '${b.participant.displayName} (you)'
                      : b.participant.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Paid ${_fmt(b.paid)} · Share ${_fmt(b.share)}',
                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                square ? '0' : '${net > 0 ? '+' : ''}${_fmt(net)}',
                style: TextStyle(fontWeight: FontWeight.w900, color: color),
              ),
              Text(
                square ? 'square' : (net > 0 ? 'gets back' : 'owes'),
                style: TextStyle(fontSize: 10, color: color),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: theme.hintColor),
            onSelected: (a) {
              if (a == 'rename') _rename(b.participant);
              if (a == 'remove') _remove(b.participant);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(
                value: 'remove',
                enabled: canRemove,
                child: Text(
                  canRemove
                      ? 'Remove'
                      : (isMe
                            ? "Can't remove yourself"
                            : 'Has entries, can’t remove'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// LOG ENTRY SHEET: DEPOSIT / EXPENSE
// =========================================================================
/// How a pool deposit is shared between members.
enum _DepositSplit { single, equal, custom }

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

  bool _isDepositMode = false;
  bool _isPaidFromPool = true;
  bool _isCustomCategoryActive = false;

  String _selectedCategory = "Food";
  String? _selectedPayerId;

  /// Members sharing this expense; null = not chosen yet (defaults to all).
  Set<String>? _splitWith;

  // Pool deposit contributors (new deposits only; editing changes the one
  // contribution that was tapped).
  _DepositSplit _depositSplit = _DepositSplit.single;
  Set<String>? _depositWith; // equal mode, null = everyone
  final Map<String, TextEditingController> _customAmounts = {};

  String? _amountError;
  String? _descError;
  String? _splitError;
  String? _depositError;

  TextEditingController _customCtrl(String id) =>
      _customAmounts.putIfAbsent(id, TextEditingController.new);

  double? _parse(String text) =>
      double.tryParse(text.replaceAll(',', '').trim());

  /// Custom-mode amounts per member (only those > 0).
  Map<String, double> _customContributions(List<EventParticipantModel> people) {
    final result = <String, double>{};
    for (final p in people) {
      final value = _parse(_customAmounts[p.id]?.text ?? '') ?? 0;
      if (value > 0) result[p.id] = value;
    }
    return result;
  }

  bool get _isMultiDeposit =>
      _isDepositMode && !_isEditMode && _depositSplit != _DepositSplit.single;

  final List<String> _basePresets = ["Food", "Transport", "Rent", "Utilities"];

  bool get _isEditMode => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.existingTransaction;
    if (tx != null) {
      _amountController.text = _money
          .format(tx.totalAmount)
          .replaceAll(',', '');
      _descController.text = tx.description;
      _isDepositMode = tx.isFundDeposit;
      _isPaidFromPool = tx.paidFromPool;
      if (!tx.paidFromPool || tx.isFundDeposit) _selectedPayerId = tx.paidById;
      if (!tx.isFundDeposit && tx.splitDetails.isNotEmpty) {
        _splitWith = tx.splitDetails.keys.toSet();
      }
      // Custom categories are added to the dropdown list in build().
      if (!tx.isFundDeposit && tx.category.isNotEmpty) {
        _selectedCategory = tx.category;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _customCategoryController.dispose();
    for (final c in _customAmounts.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Saves a deposit made by several members as one entry per member, so
  /// totals, balances and sync work exactly like single deposits.
  void _saveMultiDeposit(List<EventParticipantModel> people) {
    final Map<String, double> contributions;
    if (_depositSplit == _DepositSplit.equal) {
      final amount = _parseAmount();
      final ids = (_depositWith ?? people.map((p) => p.id).toSet())
          .where((id) => people.any((p) => p.id == id))
          .toList();
      setState(() {
        _amountError = amount == null || amount <= 0
            ? 'Enter the total amount'
            : null;
        _depositError = ids.isEmpty ? 'Pick at least one person' : null;
      });
      if (_amountError != null || _depositError != null) return;
      contributions = equalSplit(amount!, ids);
    } else {
      contributions = _customContributions(people);
      setState(() {
        _depositError = contributions.isEmpty
            ? 'Enter an amount for at least one person'
            : null;
      });
      if (_depositError != null) return;
    }

    final note = _descController.text.trim();
    final now = DateTime.now();
    final entries = [
      for (final e in contributions.entries)
        EventTransactionModel(
          id: const Uuid().v4(),
          eventId: widget.eventId,
          paidById: e.key,
          totalAmount: e.value,
          description: note.isEmpty ? 'Pool deposit' : note,
          category: 'Deposit',
          transactionDate: now,
          splitDetails: const {},
          isFundDeposit: true,
          paidFromPool: false,
          isSynced: false,
        ),
    ];

    ref
        .read(activeEventTransactionsProvider(widget.eventId).notifier)
        .addTransactions(entries);
    Navigator.pop(context);
  }

  double? _parseAmount() {
    final raw = _amountController.text.replaceAll(',', '').trim();
    return double.tryParse(raw);
  }

  void _save(List<EventParticipantModel> people) {
    if (_isMultiDeposit) {
      _saveMultiDeposit(people);
      return;
    }
    final amount = _parseAmount();
    final description = _descController.text.trim();
    final splitIds = (_splitWith ?? people.map((p) => p.id).toSet())
        .where((id) => people.any((p) => p.id == id))
        .toList();

    setState(() {
      _amountError = amount == null || amount <= 0
          ? 'Enter an amount greater than 0'
          : null;
      _descError = !_isDepositMode && description.isEmpty
          ? 'What was this for?'
          : null;
      _splitError = !_isDepositMode && splitIds.isEmpty
          ? 'Pick at least one person'
          : null;
    });
    if (_amountError != null || _descError != null || _splitError != null) {
      return;
    }
    if (people.isEmpty) return;

    final category = _isDepositMode
        ? "Deposit"
        : (_isCustomCategoryActive
              ? _customCategoryController.text.trim()
              : _selectedCategory);
    if (category.isEmpty) return;

    final payerId = (!_isDepositMode && _isPaidFromPool)
        ? commonPoolId
        : (_selectedPayerId ?? people.first.id);

    final existing = widget.existingTransaction;
    final model = EventTransactionModel(
      id: existing?.id ?? const Uuid().v4(),
      eventId: widget.eventId,
      paidById: payerId,
      totalAmount: amount!,
      description: description.isEmpty ? 'Pool deposit' : description,
      category: category,
      transactionDate: existing?.transactionDate ?? DateTime.now(),
      milestoneId: existing?.milestoneId,
      splitDetails: _isDepositMode ? const {} : equalSplit(amount, splitIds),
      isFundDeposit: _isDepositMode,
      paidFromPool: !_isDepositMode && _isPaidFromPool,
      isSynced: false,
    );

    final notifier = ref.read(
      activeEventTransactionsProvider(widget.eventId).notifier,
    );
    if (_isEditMode) {
      notifier.updateTransaction(model);
    } else {
      notifier.addTransaction(model);
    }
    Navigator.pop(context);
  }

  /// Equal mode: choose members, see each person's part.
  Widget _equalDepositPicker(
    ThemeData theme,
    List<EventParticipantModel> people,
  ) {
    final ids = _depositWith ?? people.map((p) => p.id).toSet();
    final total = _parseAmount();
    final each = total != null && total > 0 && ids.isNotEmpty
        ? equalSplit(total, ids.toList()).values.first
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                each == null
                    ? '${ids.length} of ${people.length} members'
                    : '${_fmt(each)} each from ${ids.length} '
                          '${ids.length == 1 ? 'person' : 'people'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  _depositWith = ids.length == people.length
                      ? <String>{}
                      : people.map((p) => p.id).toSet();
                  _depositError = null;
                }),
                child: Text(ids.length == people.length ? 'None' : 'All'),
              ),
            ],
          ),
          ChipTheme(
            data: themedChips(theme),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in people)
                  FilterChip(
                    label: Text(p.displayName),
                    selected: ids.contains(p.id),
                    onSelected: (_) => setState(() {
                      final next = {...ids};
                      next.contains(p.id) ? next.remove(p.id) : next.add(p.id);
                      _depositWith = next;
                      _depositError = null;
                    }),
                  ),
              ],
            ),
          ),
          if (_depositError != null) _errorLine(theme, _depositError!),
        ],
      ),
    );
  }

  /// Custom mode: an amount field per member, total added up live.
  Widget _customDepositEditor(
    ThemeData theme,
    List<EventParticipantModel> people,
    String? myUid,
  ) {
    final contributions = _customContributions(people);
    final total = contributions.values.fold<double>(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in people)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    p.userId != null && p.userId == myUid
                        ? '${p.displayName} (you)'
                        : p.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: TextField(
                    controller: _customCtrl(p.id),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.right,
                    onChanged: (_) => setState(() => _depositError = null),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                'Total from ${contributions.length} '
                '${contributions.length == 1 ? 'person' : 'people'}',
              ),
              const Spacer(),
              Text(
                _fmt(total),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        if (_depositError != null) _errorLine(theme, _depositError!),
      ],
    );
  }

  Widget _errorLine(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final people =
        ref.watch(eventParticipantsRosterProvider(widget.eventId)).value ??
        const <EventParticipantModel>[];
    final customCategories =
        ref.watch(dynamicEventCategoriesProvider(widget.eventId)).value ??
        const <String>[];
    final myUid = ref.watch(authControllerProvider).value?.uid;

    final allCategories = {
      ..._basePresets,
      ...customCategories.where((c) => c != 'Deposit'),
      if (!_basePresets.contains(_selectedCategory)) _selectedCategory,
    }.toList();

    // Default payer: you (falls back to the first member).
    _selectedPayerId ??=
        _me(people, myUid)?.id ?? (people.isNotEmpty ? people.first.id : null);
    if (_selectedPayerId != null &&
        !people.any((p) => p.id == _selectedPayerId)) {
      _selectedPayerId = people.isNotEmpty ? people.first.id : null;
    }

    final splitIds = _splitWith ?? people.map((p) => p.id).toSet();
    final amount = _parseAmount();
    final perHead = amount != null && amount > 0 && splitIds.isNotEmpty
        ? amount / splitIds.length
        : null;

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
              _isEditMode
                  ? "Edit entry"
                  : (_isDepositMode ? "Add to pool" : "Log expense"),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                style: themedSegments(theme),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text("Expense"),
                    icon: Icon(Icons.outbox_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text("Pool deposit"),
                    icon: Icon(Icons.savings_rounded, size: 16),
                  ),
                ],
                selected: {_isDepositMode},
                onSelectionChanged: (val) => setState(() {
                  _isDepositMode = val.first;
                  _descError = null;
                  _splitError = null;
                  _depositError = null;
                }),
              ),
            ),
            if (_isDepositMode && !_isEditMode && people.length > 1) ...[
              const SizedBox(height: 16),
              const Text(
                'Who put money in?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<_DepositSplit>(
                  style: themedSegments(theme),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: _DepositSplit.single,
                      label: Text('One person'),
                    ),
                    ButtonSegment(
                      value: _DepositSplit.equal,
                      label: Text('Equally'),
                    ),
                    ButtonSegment(
                      value: _DepositSplit.custom,
                      label: Text('Custom'),
                    ),
                  ],
                  selected: {_depositSplit},
                  onSelectionChanged: (v) => setState(() {
                    _depositSplit = v.first;
                    _depositError = null;
                    _amountError = null;
                  }),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_isMultiDeposit && _depositSplit == _DepositSplit.custom)
              _customDepositEditor(theme, people, myUid)
            else
              TextField(
                controller: _amountController,
                autofocus: !_isEditMode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() => _amountError = null),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: _isMultiDeposit ? "Total amount" : "Amount",
                  errorText: _amountError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_descError != null) setState(() => _descError = null);
              },
              decoration: InputDecoration(
                labelText: _isDepositMode
                    ? "Note (optional, e.g. Round 1)"
                    : "What was this for?",
                errorText: _descError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!_isDepositMode) ...[
              _isCustomCategoryActive
                  ? TextField(
                      controller: _customCategoryController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Custom category",
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
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
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
                            "+ Add custom",
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.06),
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
                            ? "Paid from the common pool"
                            : "Paid by a member (own pocket)",
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
            if (_isMultiDeposit && _depositSplit == _DepositSplit.equal)
              _equalDepositPicker(theme, people),
            if (people.isNotEmpty &&
                ((_isDepositMode && !_isMultiDeposit) ||
                    (!_isDepositMode && !_isPaidFromPool))) ...[
              DropdownButtonFormField<String>(
                // Keyed so it shows the default payer once members load.
                key: ValueKey('payer_$_selectedPayerId'),
                initialValue: _selectedPayerId,
                decoration: InputDecoration(
                  labelText: _isDepositMode ? "Who put money in?" : "Who paid?",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  for (final p in people)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        p.userId != null && p.userId == myUid
                            ? '${p.displayName} (you)'
                            : p.displayName,
                      ),
                    ),
                ],
                onChanged: (val) => setState(() => _selectedPayerId = val),
              ),
              const SizedBox(height: 12),
            ],
            if (!_isDepositMode && people.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'Split between',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (perHead != null)
                    Text(
                      '${_fmt(perHead)} each',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  TextButton(
                    onPressed: () => setState(() {
                      _splitWith = splitIds.length == people.length
                          ? <String>{}
                          : people.map((p) => p.id).toSet();
                      _splitError = null;
                    }),
                    child: Text(
                      splitIds.length == people.length ? 'None' : 'All',
                    ),
                  ),
                ],
              ),
              ChipTheme(
                data: themedChips(theme),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in people)
                      FilterChip(
                        label: Text(p.displayName),
                        selected: splitIds.contains(p.id),
                        onSelected: (_) => setState(() {
                          final next = {...splitIds};
                          next.contains(p.id)
                              ? next.remove(p.id)
                              : next.add(p.id);
                          _splitWith = next;
                          _splitError = null;
                        }),
                      ),
                  ],
                ),
              ),
              if (_splitError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _splitError!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
            if (people.isEmpty)
              Text(
                'Add a member first (Members & balances).',
                style: TextStyle(color: theme.colorScheme.error),
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
                onPressed: people.isEmpty ? null : () => _save(people),
                child: Text(
                  _isEditMode
                      ? "Save changes"
                      : (_isDepositMode ? "Add to pool" : "Save & split"),
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
