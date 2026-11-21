import 'dart:async';
import 'package:sprint_14/cache/init_cache.dart';
import 'package:sprint_14/cache/sync/sync_merge.dart';
import 'package:sprint_14/cache/sync/sync_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/models/event_ledger_model.dart';
import 'package:sprint_14/models/event_participant_model.dart';
import 'package:sprint_14/models/event_transaction_model.dart';
import 'package:sprint_14/cache/tables/event_ledger_table.dart';
import 'package:sprint_14/cache/tables/event_participant_table.dart';
import 'package:sprint_14/cache/tables/event_transaction_table.dart';
import 'package:sprint_14/cache/tables/settlement_milestone_table.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/providers/current_user_provider/current_user_provider.dart';
import 'package:sprint_14/services/event_ledger_service.dart';
import 'dart:developer' as dev;

part 'event_ledger_provider.g.dart';

// =========================================================================
// 1. GLOBAL EVENT LEDGERS LIST NOTIFIER
// =========================================================================
@Riverpod(keepAlive: true)
class EventLedgerNotifier extends _$EventLedgerNotifier {
  final EventLedgerService _service = EventLedgerService();

  @override
  Future<List<EventLedgerModel>> build() async {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return [];

    // 1. Load from SQLite local cache immediately
    final localCache = await EventLedgerTable.getActiveLedgers();

    // 2. Trigger asynchronous background alignment synchronization pass
    _syncLedgerEnvelopesFromCloud(user.uid);

    return localCache;
  }

  Future<void> _syncLedgerEnvelopesFromCloud(String userId) async {
    try {
      // Offline, Firestore answers from its partial cache; skip so nothing
      // is mistaken for a remote deletion.
      if (!await isOnline()) return;

      // Push pending local changes first so the fetch reflects them.
      await syncPendingRecordsToCloud();

      final cloudProfiles = await _service.getLedgersForUser(userId);
      final localRows = await LocalCacheManager.queryAllRows(
        EventLedgerTable.tableName,
      );
      final local = localRows.map(EventLedgerModel.fromJsonDb).toList();

      final result = mergeCloudWithLocal<EventLedgerModel>(
        cloud: cloudProfiles,
        local: local,
        idOf: (l) => l.id,
        isSynced: (l) => l.isSynced,
        isDeleted: (l) => l.isDeleted,
        markSynced: (l) => l.copyWith(isSynced: true),
        sort: (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      await EventLedgerTable.saveAllLedgers(result.toSave);
      await LocalCacheManager.deleteByIds(
        EventLedgerTable.tableName,
        result.toRemove,
      );
      state = AsyncData(result.visible);
    } catch (e) {
      dev.log(
        "Cloud Ledgers Envelope Synchronization Sync Failure: $e",
        name: "EventLedgerProvider",
      );
    }
  }

  Future<void> addLedger(EventLedgerModel ledger) async {
    final localItem = ledger.copyWith(isSynced: false, isDeleted: false);
    final current = state.value ?? [];
    state = AsyncData([localItem, ...current]);

    await EventLedgerTable.saveSingleLedger(localItem);
    syncPendingRecordsToCloud();
  }

  Future<void> updateLedger(EventLedgerModel updatedLedger) async {
    final localItem = updatedLedger.copyWith(isSynced: false);
    state = AsyncData([
      for (final item in state.value ?? [])
        if (item.id == localItem.id) localItem else item,
    ]);

    await EventLedgerTable.saveSingleLedger(localItem);
    syncPendingRecordsToCloud();
  }

  Future<void> deleteLedger(String ledgerId) async {
    final current = state.value ?? [];
    final index = current.indexWhere((element) => element.id == ledgerId);
    if (index == -1) return;
    final match = current[index];
    final deletedMarker = match.copyWith(isDeleted: true, isSynced: false);

    state = AsyncData(
      current.where((element) => element.id != ledgerId).toList(),
    );
    await EventLedgerTable.saveSingleLedger(deletedMarker);
    syncPendingRecordsToCloud();
  }

  /// Serialised with [SyncLock]: the transaction and participant providers
  /// call this too, and parallel runs would upload the same rows twice.
  Future<void> syncPendingRecordsToCloud() {
    return SyncLock.run('event_ledgers', _syncPendingRecordsToCloud);
  }

  Future<void> _syncPendingRecordsToCloud() async {
    if (!await isOnline()) return;

    // A. Sync Ledger Envelopes
    final unsyncedLedgers = await EventLedgerTable.getUnsyncedLedgers();
    for (var ledger in unsyncedLedgers) {
      try {
        if (ledger.isDeleted) {
          final success = await _service.deleteLedgerData(ledgerId: ledger.id);
          if (success) await EventLedgerTable.hardDelete(ledger.id);
          continue;
        }

        final success = await _service.saveLedger(ledger: ledger);
        if (success) {
          await EventLedgerTable.saveSingleLedger(
            ledger.copyWith(isSynced: true, lastSyncAttempt: DateTime.now()),
          );
        }
      } catch (e) {
        dev.log(
          "Failed background sync for ledger structural node ${ledger.id}: $e",
          name: "EventLedgerProvider",
        );
      }
    }

    // B. Sync Participants
    final unsyncedParticipants =
        await EventParticipantTable.getUnsyncedParticipants();
    for (var p in unsyncedParticipants) {
      try {
        if (p.isDeleted) {
          final success = await _service.removeParticipant(participantId: p.id);
          if (success) await EventParticipantTable.hardDelete(p.id);
          continue;
        }
        final success = await _service.saveParticipant(participant: p);
        if (success) {
          await EventParticipantTable.saveParticipant(
            p.copyWith(isSynced: true, lastSyncAttempt: DateTime.now()),
          );
        }
      } catch (e) {
        dev.log(
          "Failed background participant sync: $e",
          name: "EventLedgerProvider",
        );
      }
    }

    // C. Sync Transactions
    final unsyncedTransactions =
        await EventTransactionTable.getUnsyncedTransactions();
    for (var tx in unsyncedTransactions) {
      try {
        if (tx.isDeleted) {
          final success = await _service.deleteTransactionData(
            transactionId: tx.id,
          );
          if (success) await EventTransactionTable.hardDelete(tx.id);
          continue;
        }
        final success = await _service.saveTransaction(transaction: tx);
        if (success) {
          await EventTransactionTable.saveSingleTransaction(
            tx.copyWith(isSynced: true, lastSyncAttempt: DateTime.now()),
          );
        }
      } catch (e) {
        dev.log(
          "Failed background transaction sync: $e",
          name: "EventLedgerProvider",
        );
      }
    }

    // D. Sync Settlement Milestones
    final unsyncedMilestones =
        await SettlementMilestoneTable.getUnsyncedMilestones();
    for (var ms in unsyncedMilestones) {
      try {
        if (ms.isDeleted) {
          final success = await _service.deleteMilestone(milestoneId: ms.id);
          if (success) await SettlementMilestoneTable.hardDelete(ms.id);
          continue;
        }
        final activeTxInMilestone =
            await EventTransactionTable.getTransactionsByMilestone(ms.id);
        final txIds = activeTxInMilestone.map((e) => e.id).toList();
        final successCall = await _service.executeMilestoneSettlement(
          milestone: ms,
          activeTransactionIdsToFreeze: txIds,
        );
        if (successCall) {
          await SettlementMilestoneTable.saveSingleMilestone(
            ms.copyWith(isSynced: true, lastSyncAttempt: DateTime.now()),
          );
        }
      } catch (e) {
        dev.log(
          "Failed milestone background synchronization: $e",
          name: "EventLedgerProvider",
        );
      }
    }
  }
}

// =========================================================================
// 2. SCOPED ACTIVE TRANSACTION FEED STREAM FAMILY PROVIDER
// =========================================================================
@Riverpod(keepAlive: true)
class ActiveEventTransactions extends _$ActiveEventTransactions {
  final EventLedgerService _service = EventLedgerService();
  StreamSubscription? _cloudSubscription;

  @override
  FutureOr<List<EventTransactionModel>> build(String eventId) async {
    ref.onDispose(() => _cloudSubscription?.cancel());

    final cachedActiveRows =
        await EventTransactionTable.getActiveEventTransactions(eventId);

    _listenToCloudTransactions(eventId);

    return cachedActiveRows;
  }

  void _listenToCloudTransactions(String eventId) {
    _cloudSubscription?.cancel();
    _cloudSubscription = _service.streamActiveTransactions(eventId).listen(
      (cloudList) async {
        final localRows = await LocalCacheManager.queryAllRows(
          EventTransactionTable.tableName,
          where: 'eventId = ? AND milestoneId IS NULL',
          whereArgs: [eventId],
        );
        final local = localRows.map(EventTransactionModel.fromJsonDb).toList();

        // The stream only covers active (unsettled) rows, so rows missing
        // from it aren't deleted: never prune here.
        final result = mergeCloudWithLocal<EventTransactionModel>(
          cloud: cloudList,
          local: local,
          idOf: (t) => t.id,
          isSynced: (t) => t.isSynced,
          isDeleted: (t) => t.isDeleted,
          markSynced: (t) => t.copyWith(isSynced: true),
          pruneMissing: false,
        );

        await EventTransactionTable.saveAllTransactions(result.toSave);
        state = AsyncData(result.visible);
      },
      onError: (err) => dev.log(
        "Live transaction stream broken: $err",
        name: "ActiveEventTransactions",
      ),
    );
  }

  Future<void> addTransaction(EventTransactionModel transaction) async {
    final localTx = transaction.copyWith(isSynced: false, isDeleted: false);
    final current = state.value ?? [];
    state = AsyncData([localTx, ...current]);

    await EventTransactionTable.saveSingleTransaction(localTx);
    ref.read(eventLedgerProvider.notifier).syncPendingRecordsToCloud();
  }

  Future<void> deleteTransaction(String transactionId) async {
    final current = state.value ?? [];
    final index = current.indexWhere((e) => e.id == transactionId);
    if (index == -1) return;
    final match = current[index];
    state = AsyncData(current.where((e) => e.id != transactionId).toList());

    await EventTransactionTable.saveSingleTransaction(
      match.copyWith(isDeleted: true, isSynced: false),
    );
    ref.read(eventLedgerProvider.notifier).syncPendingRecordsToCloud();
  }
}

// =========================================================================
// 3. EVENT PARTICIPANTS ROSTER ROOTS FAMILY PROVIDER
// =========================================================================
@Riverpod(keepAlive: true)
class EventParticipantsRoster extends _$EventParticipantsRoster {
  final EventLedgerService _service = EventLedgerService();
  StreamSubscription? _cloudSubscription;

  @override
  FutureOr<List<EventParticipantModel>> build(String eventId) async {
    ref.onDispose(() => _cloudSubscription?.cancel());

    final localCache = await EventParticipantTable.getParticipantsByEvent(
      eventId,
    );
    _listenToCloudParticipants(eventId);

    return localCache;
  }

  void _listenToCloudParticipants(String eventId) {
    _cloudSubscription?.cancel();
    _cloudSubscription = _service.streamParticipants(eventId).listen(
      (cloudParticipants) async {
        final localRows = await LocalCacheManager.queryAllRows(
          EventParticipantTable.tableName,
          where: 'eventId = ?',
          whereArgs: [eventId],
        );
        final local = localRows.map(EventParticipantModel.fromJsonDb).toList();

        // Keep participants added offline visible until they're uploaded.
        final result = mergeCloudWithLocal<EventParticipantModel>(
          cloud: cloudParticipants,
          local: local,
          idOf: (p) => p.id,
          isSynced: (p) => p.isSynced,
          isDeleted: (p) => p.isDeleted,
          markSynced: (p) => p.copyWith(isSynced: true),
          pruneMissing: false,
        );

        await EventParticipantTable.saveAllParticipants(result.toSave);
        state = AsyncData(result.visible);
      },
      onError: (err) => dev.log(
        "Live participant stream disrupted: $err",
        name: "EventParticipantsRoster",
      ),
    );
  }

  Future<void> addParticipant(EventParticipantModel participant) async {
    final local = participant.copyWith(isSynced: false, isDeleted: false);
    final current = state.value ?? [];
    state = AsyncData([...current, local]);

    await EventParticipantTable.saveParticipant(local);
    ref.read(eventLedgerProvider.notifier).syncPendingRecordsToCloud();
  }
}

// =========================================================================
// 4. FUNCTIONAL UTILITY LOOKUP PROVIDERS & MATRIX CALCULATOR ENGINES
// =========================================================================

@riverpod
Future<EventLedgerModel> singleEventLedger(Ref ref, String eventId) async {
  final ledgers = await ref.watch(eventLedgerProvider.future);
  return ledgers.firstWhere((element) => element.id == eventId);
}

@riverpod
Future<List<String>> dynamicEventCategories(Ref ref, String eventId) async {
  await ref.watch(activeEventTransactionsProvider(eventId).future);
  return await EventTransactionTable.getDistinctCategoriesInLedger(eventId);
}

class EventFinancialSummary {
  final double totalCollected; // Total Fund Influx / Deposited to Central Pool
  final double
  totalGroupSpent; // Total Group Spending (Pool Spends + Out-of-Pocket Spends)
  final double totalPoolSpent; // Total Spent directly from the Common Pool
  final double
  totalOutPocketSpent; // Total Spent directly from personal pockets
  final double
  remainingPoolCash; // Total Cash currently remaining in the leader's hands
  final double
  yourTotalContributed; // Total money you personally put in (Deposits + Personal Spends)
  final double
  yourNetBalance; // Net standing (Positive = You get money back, Negative = You owe)

  EventFinancialSummary({
    required this.totalCollected,
    required this.totalGroupSpent,
    required this.totalPoolSpent,
    required this.totalOutPocketSpent,
    required this.remainingPoolCash,
    required this.yourTotalContributed,
    required this.yourNetBalance,
  });
}

@riverpod
Future<EventFinancialSummary> eventFinancialSummary(
  Ref ref,
  String eventId,
) async {
  final authUser = ref.watch(authControllerProvider).value;
  if (authUser == null) {
    return EventFinancialSummary(
      totalCollected: 0.0,
      totalGroupSpent: 0.0,
      totalPoolSpent: 0.0,
      totalOutPocketSpent: 0.0,
      remainingPoolCash: 0.0,
      yourTotalContributed: 0.0,
      yourNetBalance: 0.0,
    );
  }

  final activeTransactions = await ref.watch(
    activeEventTransactionsProvider(eventId).future,
  );
  final participantRoster = await ref.watch(
    eventParticipantsRosterProvider(eventId).future,
  );

  final matchingMeProfile = participantRoster
      .cast<EventParticipantModel?>()
      .firstWhere((p) => p?.userId == authUser.uid, orElse: () => null);

  if (matchingMeProfile == null) {
    return EventFinancialSummary(
      totalCollected: 0.0,
      totalGroupSpent: 0.0,
      totalPoolSpent: 0.0,
      totalOutPocketSpent: 0.0,
      remainingPoolCash: 0.0,
      yourTotalContributed: 0.0,
      yourNetBalance: 0.0,
    );
  }

  return computeEventFinancialSummary(
    transactions: activeTransactions,
    myParticipantId: matchingMeProfile.id,
  );
}

/// Rounds to 2 decimals so float drift (0.1 + 0.2 = 0.30000000000000004)
/// never shows up in balances.
double roundMoney(double value) => (value * 100).roundToDouble() / 100;

/// Pure calculation behind [eventFinancialSummary], kept separate so it can
/// be unit tested.
EventFinancialSummary computeEventFinancialSummary({
  required List<EventTransactionModel> transactions,
  required String myParticipantId,
}) {
  double computedTotalCollected = 0.0;
  double computedPoolSpent = 0.0;
  double computedOutPocketSpent = 0.0;

  double computedMyTotalDeposits = 0.0;
  double computedMyOutPocketPaid = 0.0;
  double computedMyObligationDebtShare = 0.0;

  for (final tx in transactions) {
    if (tx.isFundDeposit) {
      // Flow A: Pool Deposit
      computedTotalCollected += tx.totalAmount;
      if (tx.paidById == myParticipantId) {
        computedMyTotalDeposits += tx.totalAmount;
      }
    } else {
      // Flow B: Expense
      if (tx.paidFromPool) {
        computedPoolSpent += tx.totalAmount;
      } else {
        computedOutPocketSpent += tx.totalAmount;
        if (tx.paidById == myParticipantId) {
          computedMyOutPocketPaid += tx.totalAmount;
        }
      }

      // Tally consumed split shares
      computedMyObligationDebtShare += tx.splitDetails[myParticipantId] ?? 0.0;
    }
  }

  final double totalGroupSpent = computedPoolSpent + computedOutPocketSpent;
  final double remainingPoolCash = computedTotalCollected - computedPoolSpent;
  final double yourTotalContributed =
      computedMyTotalDeposits + computedMyOutPocketPaid;
  final double yourNetBalance =
      yourTotalContributed - computedMyObligationDebtShare;

  return EventFinancialSummary(
    totalCollected: roundMoney(computedTotalCollected),
    totalGroupSpent: roundMoney(totalGroupSpent),
    totalPoolSpent: roundMoney(computedPoolSpent),
    totalOutPocketSpent: roundMoney(computedOutPocketSpent),
    remainingPoolCash: roundMoney(remainingPoolCash),
    yourTotalContributed: roundMoney(yourTotalContributed),
    yourNetBalance: roundMoney(yourNetBalance),
  );
}
