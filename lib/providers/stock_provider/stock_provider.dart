import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:digital_munshi/cache/tables/sale_table.dart';
import 'package:digital_munshi/helpers/stock_ledger.dart';
import 'package:digital_munshi/providers/product_provider/product_provider.dart';
import 'package:digital_munshi/providers/sale_provider/sale_provider.dart';

part 'stock_provider.g.dart';

/// Stock on hand per product (productId -> units) for a business, counting
/// sales and stock adjustments that haven't been uploaded yet.
/// Products that don't track stock ('Matching') are included but meaningless.
@riverpod
Future<Map<String, double>> stockLevels(Ref ref, String businessId) async {
  final products = await ref.watch(productProvider(businessId).future);
  // Recompute whenever sales change (recorded, edited, deleted or synced).
  ref.watch(saleProvider(businessId));

  final pending = pendingStockUse(await SaleTable.getPendingRows(businessId));
  return {for (final p in products) p.id: availableStock(p, pending)};
}
