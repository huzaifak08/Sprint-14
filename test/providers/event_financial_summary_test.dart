import 'package:flutter_test/flutter_test.dart';
import 'package:digital_munshi/models/event_transaction_model.dart';
import 'package:digital_munshi/providers/event_ledger_provider/event_ledger_provider.dart';

EventTransactionModel tx({
  required String paidBy,
  required double amount,
  bool deposit = false,
  bool fromPool = false,
  Map<String, double> split = const {},
}) {
  return EventTransactionModel(
    id: '$paidBy-$amount-$deposit-$fromPool',
    eventId: 'e1',
    paidById: paidBy,
    totalAmount: amount,
    description: '',
    category: 'Food',
    transactionDate: DateTime(2026),
    splitDetails: split,
    isFundDeposit: deposit,
    paidFromPool: fromPool,
    isSynced: true,
  );
}

void main() {
  test('pool deposits, pool spends and personal spends', () {
    final s = computeEventFinancialSummary(
      myParticipantId: 'me',
      transactions: [
        tx(paidBy: 'me', amount: 100, deposit: true),
        tx(paidBy: 'other', amount: 100, deposit: true),
        tx(paidBy: 'me', amount: 60, fromPool: true, split: {'me': 30, 'other': 30}),
        tx(paidBy: 'me', amount: 40, split: {'me': 20, 'other': 20}),
      ],
    );

    expect(s.totalCollected, 200);
    expect(s.totalPoolSpent, 60);
    expect(s.totalOutPocketSpent, 40);
    expect(s.totalGroupSpent, 100);
    expect(s.remainingPoolCash, 140);
    expect(s.yourTotalContributed, 140); // 100 deposit + 40 out of pocket
    expect(s.yourNetBalance, 90); // 140 - (30 + 20)
  });

  test('results are rounded to cents', () {
    final s = computeEventFinancialSummary(
      myParticipantId: 'me',
      transactions: [
        tx(paidBy: 'me', amount: 0.1, deposit: true),
        tx(paidBy: 'me', amount: 0.2, deposit: true),
      ],
    );
    expect(s.totalCollected, 0.3);
  });
}
