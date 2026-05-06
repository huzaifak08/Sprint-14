import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sprint_14/helpers/constants.dart';
import 'package:sprint_14/models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid;

  ProductService({required this.uid});

  /// Helper to get the sub-collection reference for products
  /// Path: users/{uid}/businesses/{businessId}/products
  CollectionReference<Map<String, dynamic>> _productRef(String businessId) =>
      _firestore
          .collection(businessesCollection)
          .doc(businessId)
          .collection(productsCollection);

  /// Save or Update Product
  Future<bool> saveProduct({required ProductModel product}) async {
    try {
      dev.log(
        "Syncing Product: ${product.title} to Business: ${product.businessId}",
      );
      await _productRef(
        product.businessId,
      ).doc(product.id).set(product.toMap(), SetOptions(merge: true));
      return true;
    } catch (err) {
      dev.log("Cloud Product Sync Error: $err");
      return false;
    }
  }

  /// Fetch all products for a specific business
  Future<List<ProductModel>> getBusinessProducts(String businessId) async {
    try {
      final snapshot = await _productRef(businessId).get();
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (err) {
      dev.log("Error fetching products: $err");
      throw Exception(err.toString());
    }
  }
}
