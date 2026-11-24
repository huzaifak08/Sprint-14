import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_munshi/cache/sync/sync_utils.dart';
import 'package:digital_munshi/helpers/constants.dart';
import 'package:digital_munshi/models/business_model.dart';

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

      // Fetched doc-by-doc rather than with `whereIn` on the document id:
      // security rules can't check a document-id query, so it would be
      // rejected. A business the user lost access to is skipped, not fatal.
      final businesses = <BusinessModel>[];
      for (final chunk in chunked(businessIds)) {
        final docs = await Future.wait(
          chunk.map((id) async {
            try {
              return await _businessRef.doc(id).get();
            } on FirebaseException catch (e) {
              if (e.code == 'permission-denied') return null;
              rethrow;
            }
          }),
        );
        for (final doc in docs) {
          if (doc == null || !doc.exists || doc.data() == null) continue;
          businesses.add(
            BusinessModel.fromMap({...doc.data()!, 'id': doc.id}),
          );
        }
      }

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
        "Fetching consolidated workspace intersections for user: $uid",
        name: "BusinessService",
      );

      // 1. Query the participants collection (for roles like Salesman/Admin)
      final participantQuery = await _firestore
          .collection(participantsCollection)
          .where('userId', isEqualTo: uid)
          .where('isActive', isEqualTo: true)
          .get();

      // 2. Query the businesses collection directly (for the Owner role)
      final ownedQuery = await _firestore
          .collection(businessesCollection)
          .where('ownerId', isEqualTo: uid)
          .get();

      // Use a Set to naturally eliminate duplicate IDs
      final Set<String> combinedBusinessIds = {};

      // Extract IDs from participant links
      for (var doc in participantQuery.docs) {
        final id = doc.data()['businessId'] as String?;
        if (id != null) combinedBusinessIds.add(id);
      }

      // Extract IDs from owned businesses
      for (var doc in ownedQuery.docs) {
        combinedBusinessIds.add(doc.id);
      }

      return combinedBusinessIds.toList();
    } on FirebaseException catch (e) {
      dev.log(
        "Firebase Participant/Owner Query Error: ${e.message}",
        name: "BusinessService",
      );
      throw Exception(e.message);
    } catch (e) {
      dev.log("General Workspace Query Error: $e", name: "BusinessService");
      throw Exception(e.toString());
    }
  }

  /// Deletes a business and everything under it from the cloud: products,
  /// sales, expenses and staff links, then the business document itself.
  ///
  /// Safe to retry: each step deletes whatever is left, and the business
  /// document goes last so a half-finished delete is retried on next sync.
  Future<bool> deleteBusinessData({required String businessId}) async {
    try {
      dev.log(
        "Permanently deleting business from cloud: $businessId",
        name: "BusinessService",
      );

      final businessDoc = _businessRef.doc(businessId);
      for (final sub in [
        productsCollection,
        salesCollection,
        expensesCollection,
      ]) {
        await _deleteAll(businessDoc.collection(sub));
      }
      await _deleteAll(
        _firestore
            .collection(participantsCollection)
            .where('businessId', isEqualTo: businessId),
      );

      await businessDoc.delete();

      return true;
    } catch (err) {
      dev.log("Cloud Business Deletion Error: $err", name: "BusinessService");
      return false;
    }
  }

  /// Deletes every document matched by [query], in batches.
  Future<void> _deleteAll(Query<Map<String, dynamic>> query) async {
    const pageSize = 400; // Firestore batches hold at most 500 writes.
    while (true) {
      final snapshot = await query.limit(pageSize).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < pageSize) return;
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
