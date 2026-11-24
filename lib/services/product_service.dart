import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_munshi/cache/sync/sync_utils.dart';
import 'package:digital_munshi/helpers/constants.dart';
import 'package:digital_munshi/models/product_model.dart';

/// Outcome of uploading one product.
class ProductSyncResult {
  /// Product stock in the cloud after the transaction.
  final double cloudStock;

  /// False when the cloud had a newer edit of the product's details; those
  /// were kept and returned in [newerCloudProduct].
  final bool fieldsApplied;
  final ProductModel? newerCloudProduct;

  /// True when the pending stock adjustment is now in the cloud (applied by
  /// this call, or by an earlier attempt whose reply was lost).
  final bool adjustmentSettled;

  const ProductSyncResult({
    required this.cloudStock,
    required this.fieldsApplied,
    this.newerCloudProduct,
    required this.adjustmentSettled,
  });
}

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid;

  ProductService({required this.uid});

  /// Path: businesses/{businessId}/products
  CollectionReference<Map<String, dynamic>> _productRef(String businessId) =>
      _firestore
          .collection(businessesCollection)
          .doc(businessId)
          .collection(productsCollection);

  /// Uploads a product's details and any pending stock adjustment in one
  /// transaction.
  ///
  /// Stock is never written as a plain value: the adjustment is added to
  /// the cloud figure, so stock moved by sales on other devices is kept.
  /// Each adjustment carries an id stored on the product, so a retried
  /// upload is not applied twice.
  Future<ProductSyncResult> syncProduct(ProductModel product) {
    final doc = _productRef(product.businessId).doc(product.id);

    return _firestore.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final data = snap.data();

      final cloudStock = (data?['currentStock'] as num?)?.toDouble() ?? 0;
      final cloudUpdatedAt = data?['updatedAt'] is Timestamp
          ? (data!['updatedAt'] as Timestamp).toDate()
          : null;
      final cloudIsNewer =
          data != null && isNewerEdit(cloudUpdatedAt, product.updatedAt);

      final adjustmentId = product.stockAdjustmentId;
      final hasAdjustment =
          adjustmentId != null && product.pendingStockDelta != 0;
      final alreadyApplied =
          hasAdjustment && data?['lastStockAdjustmentId'] == adjustmentId;

      final update = <String, dynamic>{};
      if (!cloudIsNewer) update.addAll(product.toMap());

      var stock = cloudStock;
      if (hasAdjustment && !alreadyApplied) {
        stock = cloudStock + product.pendingStockDelta;
        update['currentStock'] = stock;
        update['lastStockAdjustmentId'] = adjustmentId;
      } else if (data == null) {
        update['currentStock'] = stock;
      }

      if (update.isNotEmpty) {
        tx.set(doc, update, SetOptions(merge: true));
      }

      return ProductSyncResult(
        cloudStock: stock,
        fieldsApplied: !cloudIsNewer,
        newerCloudProduct: cloudIsNewer
            ? ProductModel.fromMap({...data, 'id': snap.id})
            : null,
        adjustmentSettled: hasAdjustment,
      );
    });
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

  /// Deletes a product document from the cloud
  Future<bool> deleteProduct({
    required String businessId,
    required String productId,
  }) async {
    try {
      await _productRef(businessId).doc(productId).delete();
      return true;
    } catch (e) {
      dev.log("Cloud Delete Product Error: $e", name: "ProductService");
      return false;
    }
  }
}
