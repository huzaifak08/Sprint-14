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

  /// Saves or Updates an Event Ledger envelope metadata record in Cloud Firestore
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

  /// Pulls down all active ledgers where the specific user is a registered member participant
  Future<List<EventLedgerModel>> getLedgersForUser(String userId) async {
    try {
      dev.log(
        "Resolving ledger workspace registrations for user UID: $userId",
        name: "EventLedgerService",
      );

      // Step A: Find all membership documents linked to this userId using corrected named parameters
      final membershipSnapshot = await _participantRef
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      if (membershipSnapshot.docs.isEmpty) return [];

      // Extract target Event IDs
      final List<String> targetEventIds = membershipSnapshot.docs
          .map((doc) => doc.data()['eventId'] as String)
          .toList();

      // Step B: Query actual ledger profiles in batches (Firestore allows max 30 items in an 'in' array operator match pass)
      final List<EventLedgerModel> ledgers = [];

      // Split into chunks of 30 if user is highly active across dozens of shared spaces
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

  /// Removes an Event Ledger meta envelope from the cloud data path
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

  /// Direct Upsert syncing for shared ecosystem member nodes
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

  /// Real-time live data stream connection tracking all workspace members
  Stream<List<EventParticipantModel>> streamParticipants(String eventId) {
    return _participantRef.where('eventId', isEqualTo: eventId).snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map((doc) => EventParticipantModel.fromMap(doc.data()))
            .toList();
      },
    );
  }

  /// Removes a participant profile completely from the cloud cluster tracking paths
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

  /// Dispatches transaction payload modifications or insertions cleanly down to the ledger document cloud line
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

  /// Real-time transactional tracking streaming down newly calculated entry points instantly
  Stream<List<EventTransactionModel>> streamActiveTransactions(String eventId) {
    return _transactionRef
        .where('eventId', isEqualTo: eventId)
        .where(
          'milestoneId',
          isNull: true,
        ) // Automatically skip previously settled items
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => EventTransactionModel.fromMap(doc.data()))
              .toList();
        });
  }

  /// Erases a single transaction calculation node record out from the database
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

  /// Executes an atomic transactional settlement checkpoint across the entire ledger workspace group.
  /// Stamps all active open transaction records with the milestone checkout tracker tag to reset balances to zero.
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

      // Step A: Push the new settlement milestone folder envelope record to cloud
      batch.set(_milestoneRef.doc(milestone.id), milestone.toMap());

      // Step B: Loop and update the milestone reference field across all specified transaction records
      for (String txId in activeTransactionIdsToFreeze) {
        batch.update(_transactionRef.doc(txId), {'milestoneId': milestone.id});
      }

      // Step C: Push modifications down to the central network simultaneously
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

  /// Fetches historically frozen settlement checkpoint folders once
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
