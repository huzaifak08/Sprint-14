import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sprint_14/helpers/constants.dart';
import 'package:sprint_14/models/sale_model.dart';

class SaleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid;

  SaleService({required this.uid});

  CollectionReference<Map<String, dynamic>> _saleRef(String businessId) =>
      _firestore
          .collection(businessesCollection)
          .doc(businessId)
          .collection(salesCollection);

  /// Record or Update a sale (Set with merge covers both)
  Future<bool> recordSale({required SaleModel sale}) async {
    try {
      dev.log("Syncing Sale: ${sale.productTitle}", name: "SaleService");
      await _saleRef(
        sale.businessId,
      ).doc(sale.id).set(sale.toMap(), SetOptions(merge: true));
      return true;
    } catch (err) {
      dev.log("Cloud Sale Sync Error: $err", name: "SaleService");
      return false;
    }
  }

  /// NEW: Delete sale data from cloud
  Future<bool> deleteSaleData({
    required String businessId,
    required String saleId,
  }) async {
    try {
      dev.log("Deleting Sale ID: $saleId from cloud", name: "SaleService");
      await _saleRef(businessId).doc(saleId).delete();
      return true;
    } catch (err) {
      dev.log("Cloud Sale Delete Error: $err", name: "SaleService");
      return false;
    }
  }

  Future<List<SaleModel>> getBusinessSales(String businessId) async {
    try {
      final snapshot = await _saleRef(
        businessId,
      ).orderBy('dateTime', descending: true).get();
      return snapshot.docs.map((doc) {
        return SaleModel.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (err) {
      dev.log("Error fetching sales: $err", name: "SaleService");
      throw Exception(err.toString());
    }
  }
}
