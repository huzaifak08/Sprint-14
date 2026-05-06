import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sprint_14/helpers/constants.dart';
import 'package:sprint_14/models/sale_model.dart';

class SaleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid;

  SaleService({required this.uid});

  /// Helper to get the sub-collection reference for sales
  /// Path: users/{uid}/businesses/{businessId}/sales
  CollectionReference<Map<String, dynamic>> _saleRef(String businessId) =>
      _firestore
          .collection(businessesCollection)
          .doc(businessId)
          .collection(salesCollection);

  /// Record a new sale
  Future<bool> recordSale({required SaleModel sale}) async {
    try {
      dev.log("Recording Sale for Product: ${sale.productTitle}");
      await _saleRef(
        sale.businessId,
      ).doc(sale.id).set(sale.toMap(), SetOptions(merge: true));
      return true;
    } catch (err) {
      dev.log("Cloud Sale Sync Error: $err");
      return false;
    }
  }

  /// Fetch sales for a specific business (paginated or filtered by date)
  Future<List<SaleModel>> getBusinessSales(String businessId) async {
    try {
      final snapshot = await _saleRef(
        businessId,
      ).orderBy('dateTime', descending: true).get();
      return snapshot.docs.map((doc) {
        return SaleModel.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (err) {
      dev.log("Error fetching sales: $err");
      throw Exception(err.toString());
    }
  }
}
