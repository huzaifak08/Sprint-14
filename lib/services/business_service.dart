import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sprint_14/helpers/constants.dart';
import 'package:sprint_14/models/business_model.dart';

class BusinessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// The UID of the authenticated user to scope the business data
  final String uid;

  BusinessService({required this.uid});

  /// Helper getter to point to the user's private business subcollection
  /// Path: users/{uid}/businesses
  CollectionReference<Map<String, dynamic>> get _businessRef =>
      _firestore.collection(
        businessesCollection,
      ); // You can add 'businessesCollection' to your constants.dart

  /// Saves or Updates a Business profile in Firestore (Upsert)
  /// Used for both initial creation and editing (name change, etc.)
  Future<bool> saveBusiness({required BusinessModel business}) async {
    try {
      dev.log("Syncing Business profile to cloud: ${business.name}");

      await _businessRef
          .doc(business.id)
          .set(business.toMap(), SetOptions(merge: true));

      return true;
    } catch (err) {
      dev.log("Cloud Business Sync Error: $err");
      return false;
    }
  }

  /// Fetches all Business profiles for the current user
  Future<List<BusinessModel>> getAllBusinesses() async {
    try {
      dev.log("Fetching business profiles for user: $uid");

      final snapshot = await _businessRef
          .orderBy('createdAt', descending: true)
          .get();

      final businesses = snapshot.docs.map((doc) {
        return BusinessModel.fromMap({...doc.data(), 'id': doc.id});
      }).toList();

      return businesses;
    } on FirebaseException catch (exception) {
      dev.log("Firebase Business Fetch Error: ${exception.message}");
      throw Exception(exception.message);
    } catch (err) {
      dev.log("General Business Fetch Error: $err");
      throw Exception(err.toString());
    }
  }

  /// Deletes a Business profile from the Cloud
  /// NOTE: In a real-world scenario, you might want to handle the
  /// deletion of related Products and Sales as well.
  Future<bool> deleteBusinessData({required String businessId}) async {
    try {
      dev.log("Permanently deleting business from cloud: $businessId");

      await _businessRef.doc(businessId).delete();

      return true;
    } catch (err) {
      dev.log("Cloud Business Deletion Error: $err");
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
