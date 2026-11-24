import 'package:flutter_test/flutter_test.dart';
import 'package:digital_munshi/models/event_participant_model.dart';
import 'package:digital_munshi/models/event_transaction_model.dart';
import 'package:digital_munshi/providers/event_ledger_provider/event_ledger_provider.dart';
import 'package:digital_munshi/views/event_ledgers_views/event_balances.dart';

EventParticipantModel p(String id) => EventParticipantModel(
  id: id,
  eventId: 'e',
  displayName: id,
  joinedAt: DateTime(2026),
  isSynced: true,
);

int _n = 0;
EventTransactionModel tx({
  required String paidBy,
  required double amount,
  bool deposit = false,
  bool pool = false,
  List<String> split = const [],
}) => EventTransactionModel(
  id: 't${_n++}',
  eventId: 'e',
  paidById: pool ? commonPoolId : paidBy,
  totalAmount: amount,
  description: '',
  category: 'Food',
  transactionDate: DateTime(2026),
  splitDetails: deposit ? const {} : equalSplit(amount, split),
  isFundDeposit: deposit,
  paidFromPool: pool,
  isSynced: true,
);

void main() {
  final a = p('A'), b = p('B'), c = p('C');

  test('equalSplit always sums to the total', () {
    final s = equalSplit(100, ['A', 'B', 'C']);
    expect(s.values.reduce((x, y) => x + y), closeTo(100, 1e-9));
    expect(s['A'], 33.33);
    expect(s['C'], 33.34);
    expect(equalSplit(50, []), isEmpty);
  });

  test('out-of-pocket expense: payer is owed by the others', () {
    final txs = [
      tx(paidBy: 'A', amount: 300, split: ['A', 'B', 'C']),
    ];
    final bal = computeMemberBalances(
      transactions: txs,
      participants: [a, b, c],
    );
    expect(bal.map((x) => x.net).toList(), [200, -100, -100]);

    final transfers = suggestSettlements(bal);
    expect(transfers.length, 2);
    expect(transfers.every((t) => t.toName == 'A' && t.amount == 100), isTrue);
  });

  test('split only between chosen members', () {
    final txs = [
      tx(paidBy: 'A', amount: 100, split: ['A', 'B']),
    ];
    final bal = computeMemberBalances(
      transactions: txs,
      participants: [a, b, c],
    );
    expect(bal.firstWhere((x) => x.participant.id == 'C').net, 0);
    expect(bal.firstWhere((x) => x.participant.id == 'B').net, -50);
  });

  test('pool: unspent cash is refunded by the pool', () {
    final txs = [
      tx(paidBy: 'A', amount: 300, deposit: true),
      tx(paidBy: 'B', amount: 300, deposit: true),
      tx(paidBy: '', amount: 400, pool: true, split: ['A', 'B']),
    ];
    final bal = computeMemberBalances(transactions: txs, participants: [a, b]);
    // Each put in 300, each consumed 200 -> each gets 100 back from the pool.
    expect(bal.map((x) => x.net).toList(), [100, 100]);
    final transfers = suggestSettlements(bal, poolRemaining: 200);
    expect(transfers.length, 2);
    expect(
      transfers.every((t) => t.fromName == 'Pool' && t.amount == 100),
      isTrue,
    );
  });

  test('member balance matches the dashboard summary for "you"', () {
    final txs = [
      tx(paidBy: 'A', amount: 100, deposit: true),
      tx(paidBy: 'B', amount: 90, split: ['A', 'B', 'C']),
      tx(paidBy: '', amount: 60, pool: true, split: ['A', 'B']),
    ];
    final bal = computeMemberBalances(
      transactions: txs,
      participants: [a, b, c],
    );
    final summary = computeEventFinancialSummary(
      transactions: txs,
      myParticipantId: 'A',
    );
    expect(bal.first.net, closeTo(summary.yourNetBalance, 0.01));
  });

  test('involvedCount blocks removing members with entries', () {
    final txs = [
      tx(paidBy: 'A', amount: 10, split: ['A']),
    ];
    final bal = computeMemberBalances(transactions: txs, participants: [a, b]);
    expect(bal[0].involvedCount, 1);
    expect(bal[1].involvedCount, 0);
  });
}
