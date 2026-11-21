import 'package:sprint_14/models/event_participant_model.dart';
import 'package:sprint_14/models/event_transaction_model.dart';

/// Payer id used for expenses paid from the common pool.
const String commonPoolId = 'COMMON_POOL';

/// What one member put in vs. what they consumed.
class MemberBalance {
  final EventParticipantModel participant;

  /// Pool deposits + expenses they paid out of their own pocket.
  final double paid;

  /// Their share of all expenses.
  final double share;

  /// Number of transactions that involve this member.
  final int involvedCount;

  const MemberBalance({
    required this.participant,
    required this.paid,
    required this.share,
    required this.involvedCount,
  });

  /// Positive: the group owes them. Negative: they owe the group.
  double get net => paid - share;
}

/// One suggested payment to settle up.
class SettlementTransfer {
  final String fromName;
  final String toName;
  final double amount;
  const SettlementTransfer(this.fromName, this.toName, this.amount);
}

double _round2(double v) => (v * 100).roundToDouble() / 100;

/// Per-member balances, same rules as the dashboard's financial summary:
/// net = deposits + out-of-pocket payments - share of expenses.
List<MemberBalance> computeMemberBalances({
  required List<EventTransactionModel> transactions,
  required List<EventParticipantModel> participants,
}) {
  final paid = <String, double>{};
  final share = <String, double>{};
  final involved = <String, int>{};

  for (final tx in transactions) {
    if (tx.isDeleted) continue;
    final touched = <String>{};

    if (tx.isFundDeposit || !tx.paidFromPool) {
      paid[tx.paidById] = (paid[tx.paidById] ?? 0) + tx.totalAmount;
      touched.add(tx.paidById);
    }
    if (!tx.isFundDeposit) {
      tx.splitDetails.forEach((id, amount) {
        share[id] = (share[id] ?? 0) + amount;
        touched.add(id);
      });
    }
    for (final id in touched) {
      involved[id] = (involved[id] ?? 0) + 1;
    }
  }

  return [
    for (final p in participants)
      MemberBalance(
        participant: p,
        paid: _round2(paid[p.id] ?? 0),
        share: _round2(share[p.id] ?? 0),
        involvedCount: involved[p.id] ?? 0,
      ),
  ];
}

/// Fewest payments that bring everyone to zero (greedy: biggest debtor pays
/// biggest creditor). Money still sitting in the common pool
/// ([poolRemaining] > 0) is treated as owed back by "Pool" (whoever holds
/// it); a negative pool means the pool was overspent and members cover it.
List<SettlementTransfer> suggestSettlements(
  List<MemberBalance> balances, {
  double poolRemaining = 0,
  String poolName = 'Pool',
}) {
  final debtors = <MapEntry<String, double>>[];
  final creditors = <MapEntry<String, double>>[];

  for (final b in balances) {
    final net = _round2(b.net);
    if (net < -0.009) debtors.add(MapEntry(b.participant.displayName, -net));
    if (net > 0.009) creditors.add(MapEntry(b.participant.displayName, net));
  }
  final pool = _round2(poolRemaining);
  if (pool > 0.009) debtors.add(MapEntry(poolName, pool));
  if (pool < -0.009) creditors.add(MapEntry(poolName, -pool));

  debtors.sort((a, b) => b.value.compareTo(a.value));
  creditors.sort((a, b) => b.value.compareTo(a.value));

  final transfers = <SettlementTransfer>[];
  var i = 0, j = 0;
  final owe = [for (final d in debtors) d.value];
  final get = [for (final c in creditors) c.value];

  while (i < debtors.length && j < creditors.length) {
    final amount = owe[i] < get[j] ? owe[i] : get[j];
    if (amount > 0.009) {
      transfers.add(
        SettlementTransfer(debtors[i].key, creditors[j].key, _round2(amount)),
      );
    }
    owe[i] -= amount;
    get[j] -= amount;
    if (owe[i] <= 0.009) i++;
    if (get[j] <= 0.009) j++;
  }
  return transfers;
}

/// Splits [amount] equally between [memberIds]; the last member absorbs the
/// rounding remainder so the shares always add up exactly to the total.
Map<String, double> equalSplit(double amount, List<String> memberIds) {
  if (memberIds.isEmpty) return {};
  final each = (amount / memberIds.length * 100).floorToDouble() / 100;
  final result = {for (final id in memberIds) id: each};
  final remainder = _round2(amount - each * memberIds.length);
  result[memberIds.last] = _round2(each + remainder);
  return result;
}
