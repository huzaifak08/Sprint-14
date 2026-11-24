import 'package:digital_munshi/models/product_model.dart';
import 'package:digital_munshi/models/sale_model.dart';

/// Stock maths shared by the sale sync, the product sync and the screens.
///
/// How stock is kept consistent across devices:
/// * The cloud product's `currentStock` is only ever changed inside Firestore
///   transactions (a sale upload/delete, or a manual stock adjustment), so
///   two devices can't overwrite each other's figures.
/// * Locally, `ProductModel.currentStock` mirrors the cloud figure, and
///   changes not uploaded yet are added on top: pending manual adjustments
///   (`pendingStockDelta`) and unsynced sales ([pendingStockUse]).

/// Stock use per product (productId -> units) that unsynced sales still need
/// to apply to the cloud. Each sale contributes what it consumes now minus
/// what the cloud already has for it, so an edited sale only counts its
/// difference and a deleted sale gives its stock back.
Map<String, double> pendingStockUse(Iterable<SaleModel> unsyncedSales) {
  final use = <String, double>{};
  for (final sale in unsyncedSales) {
    stockDelta(sale.syncedStock, sale.stockEffects).forEach((id, delta) {
      use[id] = (use[id] ?? 0) + delta;
    });
  }
  return use;
}

/// Change in stock use going from [before] to [after] (productId -> units,
/// positive means more stock consumed). Zero changes are left out.
Map<String, double> stockDelta(
  Map<String, double> before,
  Map<String, double> after,
) {
  final delta = <String, double>{};
  for (final id in {...before.keys, ...after.keys}) {
    final d = (after[id] ?? 0) - (before[id] ?? 0);
    if (d.abs() > 1e-9) delta[id] = d;
  }
  return delta;
}

/// Stock actually on hand for [product], counting changes not uploaded yet.
double availableStock(ProductModel product, Map<String, double> pendingUse) {
  return product.currentStock +
      product.pendingStockDelta -
      (pendingUse[product.id] ?? 0);
}
