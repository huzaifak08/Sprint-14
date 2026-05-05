import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sprint_14/helpers/constants.dart';
import 'package:sprint_14/models/ledger_model.dart';

class LedgerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 Added UID to scope ledger data to the specific user
  final String uid;

  LedgerService({required this.uid});

  // 🔥 Helper getter to point to the user's private ledger subcollection
  CollectionReference<Map<String, dynamic>> get _ledgerRef => _firestore
      .collection(usersCollection)
      .doc(uid)
      .collection(ledgersCollection);

  /// Saves or Updates a Ledger entry in Firestore (Upsert)
  Future<bool> saveLedger({required LedgerModel ledger}) async {
    try {
      dev.log("Syncing Ledger entry to subcollection: ${ledger.title}");

      // 🔥 Using the subcollection reference instead of root
      await _ledgerRef
          .doc(ledger.id)
          .set(ledger.toMap(), SetOptions(merge: true));

      return true;
    } catch (err) {
      dev.log("Ledger Subcollection Sync Error: $err");
      return false;
    }
  }

  /// Fetches all Ledger entries from Firestore once
  Future<List<LedgerModel>> getAllLedgers() async {
    try {
      dev.log("Fetching ledger entries from: users/$uid/ledgers");

      // 🔥 Fetching from subcollection path
      final snapshot = await _ledgerRef
          .orderBy('dateTime', descending: true) // Most recent first
          .get();

      final ledgers = snapshot.docs.map((doc) {
        return LedgerModel.fromMap({...doc.data(), 'id': doc.id});
      }).toList();

      return ledgers;
    } on FirebaseException catch (exception) {
      dev.log("Firebase Ledger Error: ${exception.message}");
      throw Exception(exception.message);
    } catch (err) {
      dev.log("General Ledger Error: $err");
      throw Exception(err.toString());
    }
  }

  /// Deletes a Ledger entry from Firestore
  Future<bool> deleteLedgerData({required String ledgerId}) async {
    try {
      dev.log("Deleting Ledger from Cloud Subcollection: $ledgerId");

      // 🔥 Deleting from subcollection path
      await _ledgerRef.doc(ledgerId).delete();

      return true;
    } catch (err) {
      dev.log("Cloud Ledger Deletion Error: $err");
      return false;
    }
  }
}
