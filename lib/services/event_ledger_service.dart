import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sprint_14/helpers/constants.dart';
import 'package:sprint_14/models/event_ledger_model.dart';
import 'package:sprint_14/models/event_participant_model.dart';
import 'package:sprint_14/models/event_transaction_model.dart';
import 'package:sprint_14/models/settlement_milestone_model.dart';

class EventLedgerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Root Database Reference Hooks
  CollectionReference<Map<String, dynamic>> get _ledgerRef =>
      _firestore.collection(eventLedgersCollection);

  CollectionReference<Map<String, dynamic>> get _participantRef =>
      _firestore.collection(eventParticipantsCollection);

  CollectionReference<Map<String, dynamic>> get _transactionRef =>
      _firestore.collection(transactionsCollection);

  CollectionReference<Map<String, dynamic>> get _milestoneRef =>
      _firestore.collection(milestonesCollection);

  // =========================================================================
  // 1. EVENT LEDGER ENVELOPE OPERATIONS
  // =========================================================================

  Future<bool> saveLedger({required EventLedgerModel ledger}) async {
    try {
      dev.log(
        "Syncing Event Ledger Envelope: ${ledger.title}",
        name: "EventLedgerService",
      );
      await _ledgerRef
          .doc(ledger.id)
          .set(ledger.toMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      dev.log(
        "Firestore Event Ledger Sync Error: $e",
        name: "EventLedgerService",
      );
      return false;
    }
  }

  Future<List<EventLedgerModel>> getLedgersForUser(String userId) async {
    try {
      dev.log(
        "Resolving ledger workspace registrations for user UID: $userId",
        name: "EventLedgerService",
      );

      final membershipSnapshot = await _participantRef
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      if (membershipSnapshot.docs.isEmpty) return [];

      final List<String> targetEventIds = membershipSnapshot.docs
          .map((doc) => doc.data()['eventId'] as String)
          .toList();

      final List<EventLedgerModel> ledgers = [];

      for (var i = 0; i < targetEventIds.length; i += 30) {
        final chunk = targetEventIds.sublist(
          i,
          i + 30 > targetEventIds.length ? targetEventIds.length : i + 30,
        );

        final ledgerSnapshot = await _ledgerRef
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var doc in ledgerSnapshot.docs) {
          ledgers.add(EventLedgerModel.fromMap(doc.data()));
        }
      }

      return ledgers;
    } catch (e) {
      dev.log(
        "Failed fetching user linked workspaces: $e",
        name: "EventLedgerService",
      );
      throw Exception(e.toString());
    }
  }

  Future<bool> deleteLedgerData({required String ledgerId}) async {
    try {
      dev.log(
        "Hard purging Ledger Envelope shell from Cloud: $ledgerId",
        name: "EventLedgerService",
      );
      await _ledgerRef.doc(ledgerId).delete();
      return true;
    } catch (e) {
      dev.log("Cloud Ledger Deletion Failure: $e", name: "EventLedgerService");
      return false;
    }
  }

  // =========================================================================
  // 2. ROSTER PARTICIPANTS PIPELINES
  // =========================================================================

  Future<bool> saveParticipant({
    required EventParticipantModel participant,
  }) async {
    try {
      await _participantRef
          .doc(participant.id)
          .set(participant.toMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      dev.log("Participant Cloud Sink Error: $e", name: "EventLedgerService");
      return false;
    }
  }

  Stream<List<EventParticipantModel>> streamParticipants(String eventId) {
    return _participantRef.where('eventId', isEqualTo: eventId).snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map((doc) => EventParticipantModel.fromMap(doc.data()))
            .toList();
      },
    );
  }

  Future<bool> removeParticipant({required String participantId}) async {
    try {
      await _participantRef.doc(participantId).delete();
      return true;
    } catch (e) {
      dev.log(
        "Failed offboarding cloud participant record: $e",
        name: "EventLedgerService",
      );
      return false;
    }
  }

  // =========================================================================
  // 3. EVENT TRANSACTIONS LEDGERS (SPLIT MATRIX ENGINE)
  // =========================================================================

  Future<bool> saveTransaction({
    required EventTransactionModel transaction,
  }) async {
    try {
      await _transactionRef
          .doc(transaction.id)
          .set(transaction.toMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      dev.log("Transaction Cloud Sink Error: $e", name: "EventLedgerService");
      return false;
    }
  }

  Stream<List<EventTransactionModel>> streamActiveTransactions(String eventId) {
    return _transactionRef
        .where('eventId', isEqualTo: eventId)
        .where('milestoneId', isNull: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => EventTransactionModel.fromMap(doc.data()))
              .toList();
        });
  }

  Future<bool> deleteTransactionData({required String transactionId}) async {
    try {
      await _transactionRef.doc(transactionId).delete();
      return true;
    } catch (e) {
      dev.log(
        "Failed removing split transaction from cloud: $e",
        name: "EventLedgerService",
      );
      return false;
    }
  }

  // =========================================================================
  // 4. MILESTONE SETTLEMENT ARCHIVE CONTROL
  // =========================================================================

  Future<bool> executeMilestoneSettlement({
    required SettlementMilestoneModel milestone,
    required List<String> activeTransactionIdsToFreeze,
  }) async {
    try {
      dev.log(
        "Commencing Atomic Milestone Settlement for Event Ledger ID: ${milestone.eventId}",
        name: "EventLedgerService",
      );

      final WriteBatch batch = _firestore.batch();

      batch.set(_milestoneRef.doc(milestone.id), milestone.toMap());

      for (String txId in activeTransactionIdsToFreeze) {
        batch.update(_transactionRef.doc(txId), {'milestoneId': milestone.id});
      }

      await batch.commit();
      dev.log(
        "Atomic Milestone Settlement written successfully.",
        name: "EventLedgerService",
      );
      return true;
    } catch (e) {
      dev.log(
        "Atomic Milestone Settlement Operation Failed: $e",
        name: "EventLedgerService",
      );
      return false;
    }
  }

  Future<List<SettlementMilestoneModel>> getHistoricalMilestones(
    String eventId,
  ) async {
    try {
      final snapshot = await _milestoneRef
          .where('eventId', isEqualTo: eventId)
          .orderBy('settledAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SettlementMilestoneModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      dev.log(
        "Failed downloading historical milestones maps: $e",
        name: "EventLedgerService",
      );
      throw Exception(e.toString());
    }
  }
}
