import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_munshi/cache/sync/sync_utils.dart';
import 'package:digital_munshi/helpers/constants.dart';
import 'package:digital_munshi/helpers/stock_ledger.dart';
import 'package:digital_munshi/models/sale_model.dart';

/// Outcome of uploading one sale.
class SaleSyncResult {
  /// False when the cloud already had a newer edit of this sale; the local
  /// change was dropped and [newerCloudSale] should replace it.
  final bool applied;
  final SaleModel? newerCloudSale;

  /// Cloud stock of every product the transaction changed (id -> stock).
  final Map<String, double> cloudStock;

  /// Stock use the cloud now reflects for this sale.
  final Map<String, double> syncedStock;

  const SaleSyncResult({
    required this.applied,
    this.newerCloudSale,
    this.cloudStock = const {},
    this.syncedStock = const {},
  });
}

class SaleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid;

  SaleService({required this.uid});

  CollectionReference<Map<String, dynamic>> _saleRef(String businessId) =>
      _firestore
          .collection(businessesCollection)
          .doc(businessId)
          .collection(salesCollection);

  DocumentReference<Map<String, dynamic>> _productDoc(
    String businessId,
    String productId,
  ) => _firestore
      .collection(businessesCollection)
      .doc(businessId)
      .collection(productsCollection)
      .doc(productId);

  /// Uploads (or deletes, when `sale.isDeleted`) a sale and moves product
  /// stock by the difference, all in one transaction.
  ///
  /// The stock change is worked out from the sale as it is in the cloud, so
  /// retrying after a failure never applies it twice. If the cloud copy was
  /// edited more recently than [sale], nothing is written and the newer
  /// cloud copy is returned instead.
  Future<SaleSyncResult> syncSale(SaleModel sale) {
    final saleDoc = _saleRef(sale.businessId).doc(sale.id);

    return _firestore.runTransaction((tx) async {
      final snap = await tx.get(saleDoc);
      final data = snap.data();
      final cloudSale = data == null
          ? null
          : SaleModel.fromMap({...data, 'id': snap.id});

      if (cloudSale != null && isNewerEdit(cloudSale.updatedAt, sale.updatedAt)) {
        return SaleSyncResult(applied: false, newerCloudSale: cloudSale);
      }

      final before = cloudSale?.stockEffects ?? const <String, double>{};
      final after = sale.stockEffects; // empty when deleted
      final delta = stockDelta(before, after);

      // Transactions need every read before the first write.
      final productSnaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final productId in delta.keys) {
        productSnaps[productId] = await tx.get(
          _productDoc(sale.businessId, productId),
        );
      }

      final cloudStock = <String, double>{};
      productSnaps.forEach((productId, productSnap) {
        // A deleted product has no stock left to adjust.
        if (!productSnap.exists) return;
        final current =
            (productSnap.data()?['currentStock'] as num?)?.toDouble() ?? 0;
        final next = current - delta[productId]!;
        tx.update(productSnap.reference, {'currentStock': next});
        cloudStock[productId] = next;
      });

      if (sale.isDeleted) {
        if (snap.exists) tx.delete(saleDoc);
      } else {
        tx.set(saleDoc, sale.toMap());
      }

      return SaleSyncResult(
        applied: true,
        cloudStock: cloudStock,
        syncedStock: after,
      );
    });
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
