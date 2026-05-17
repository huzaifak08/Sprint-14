import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sprint_14/helpers/constants.dart';
import 'package:sprint_14/models/business_model.dart';

class BusinessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// The UID of the authenticated user to scope the business data operations
  final String uid;

  BusinessService({required this.uid});

  /// Helper getter to point to the root businesses collection
  CollectionReference<Map<String, dynamic>> get _businessRef =>
      _firestore.collection(businessesCollection);

  /// Saves or Updates a Business profile in Firestore (Upsert)
  /// Used for both initial creation and editing (name change, etc.)
  Future<bool> saveBusiness({required BusinessModel business}) async {
    try {
      dev.log(
        "Syncing Business profile to cloud: ${business.name}",
        name: "BusinessService",
      );

      await _businessRef
          .doc(business.id)
          .set(business.toMap(), SetOptions(merge: true));

      return true;
    } catch (err) {
      dev.log("Cloud Business Sync Error: $err", name: "BusinessService");
      return false;
    }
  }

  /// 🔥 NEW & UPDATED METHOD: Fetches specific businesses by a list of document IDs
  /// This supports pulling shops where the user is an owner OR a participant.
  Future<List<BusinessModel>> getBusinessesByIds(
    List<String> businessIds,
  ) async {
    if (businessIds.isEmpty) return [];

    try {
      dev.log(
        "Fetching matching workspaces for IDs count: ${businessIds.length}",
        name: "BusinessService",
      );

      // Firestore 'whereIn' supports checking collections of up to 30 elements per pass
      final snapshot = await _businessRef
          .where(FieldPath.documentId, whereIn: businessIds)
          .get();

      final businesses = snapshot.docs.map((doc) {
        return BusinessModel.fromMap({...doc.data(), 'id': doc.id});
      }).toList();

      // Sort locally by design preferences since 'whereIn' cannot be combined easily with dynamic orderBys
      businesses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return businesses;
    } on FirebaseException catch (exception) {
      dev.log(
        "Firebase Workspaces Fetch Error: ${exception.message}",
        name: "BusinessService",
      );
      throw Exception(exception.message);
    } catch (err) {
      dev.log("General Workspaces Fetch Error: $err", name: "BusinessService");
      throw Exception(err.toString());
    }
  }

  /// DEPRECATED: Replaced by getBusinessesByIds to accommodate multi-user permissions
  /// Kept fallback reference if needed for explicit troubleshooting
  Future<List<BusinessModel>> getAllBusinesses() async {
    try {
      dev.log(
        "Fetching business profiles owned by user: $uid",
        name: "BusinessService",
      );

      final snapshot = await _businessRef
          .where('ownerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return BusinessModel.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    } on FirebaseException catch (exception) {
      throw Exception(exception.message);
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  /// 🔥 NEW METHOD: Fetches all active business IDs where this user is registered as a participant
  Future<List<String>> getParticipantBusinessIds() async {
    try {
      dev.log(
        "Fetching participant links for user: $uid",
        name: "BusinessService",
      );

      final participantQuery = await _firestore
          .collection(participantsCollection)
          .where('userId', isEqualTo: uid)
          .where('isActive', isEqualTo: true)
          .get();

      if (participantQuery.docs.isEmpty) return [];

      // Extract and return just the raw businessId strings
      return participantQuery.docs
          .map((doc) => doc.data()['businessId'] as String)
          .toList();
    } on FirebaseException catch (e) {
      dev.log(
        "Firebase Participant Query Error: ${e.message}",
        name: "BusinessService",
      );
      throw Exception(e.message);
    } catch (e) {
      dev.log("General Participant Query Error: $e", name: "BusinessService");
      throw Exception(e.toString());
    }
  }

  /// Deletes a Business profile from the Cloud
  Future<bool> deleteBusinessData({required String businessId}) async {
    try {
      dev.log(
        "Permanently deleting business from cloud: $businessId",
        name: "BusinessService",
      );

      await _businessRef.doc(businessId).delete();

      return true;
    } catch (err) {
      dev.log("Cloud Business Deletion Error: $err", name: "BusinessService");
      return false;
    }
  }

  /// Stream for real-time updates (Optional but helpful for Dashboards)
  Stream<List<BusinessModel>> streamBusinesses() {
    return _businessRef.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return BusinessModel.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }
}
