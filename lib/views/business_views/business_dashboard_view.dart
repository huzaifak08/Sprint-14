import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/models/business_model.dart';
import 'package:sprint_14/models/sale_model.dart';
import 'package:sprint_14/models/product_model.dart';
import 'package:sprint_14/providers/business_provider/business_provider.dart';
import 'package:sprint_14/providers/product_provider/product_provider.dart';
import 'package:sprint_14/providers/sale_provider/sale_provider.dart';
import 'package:sprint_14/views/business_views/manage_products_view.dart';
import 'package:sprint_14/views/business_views/add_update_sale_view.dart';

// --- SHARED CATEGORY SELECTOR WIDGET ---
class CategorySelector extends StatelessWidget {
  final bool isTheya;
  final Function(bool) onChanged;

  const CategorySelector({
    super.key,
    required this.isTheya,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _buildTab(context, "INSIDE", !isTheya, theme.colorScheme.primary),
            const SizedBox(width: 6),
            _buildTab(context, "THEYA", isTheya, Colors.amber.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String label,
    bool active,
    Color color,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(label == "THEYA"),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: active ? Colors.white : color.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

// --- MAIN VIEW ---
class BusinessDashboardView extends ConsumerStatefulWidget {
  final BusinessModel business;
  const BusinessDashboardView({super.key, required this.business});

  @override
  ConsumerState<BusinessDashboardView> createState() =>
      _BusinessDashboardViewState();
}

class _BusinessDashboardViewState extends ConsumerState<BusinessDashboardView> {
  bool isTheya = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productProvider.notifier).loadProducts(widget.business.id);
      ref.read(saleProvider.notifier).loadSales(widget.business.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final saleState = ref.watch(saleProvider);
    final productState = ref.watch(productProvider);
    final theme = Theme.of(context);

    // Initial Loading State
    if (saleState.isLoading || productState.isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: saleState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (allSales) {
          final products = productState.value ?? [];

          // Deriving UI filter from product metadata
          final filteredSales = allSales.where((s) {
            final product = products.cast<ProductModel?>().firstWhere(
              (p) => p?.id == s.productId,
              orElse: () => null,
            );
            return (product?.isTheya ?? false) == isTheya;
          }).toList();

          final totalSales = allSales.fold(
            0.0,
            (sum, item) => sum + item.soldAtPrice,
          );
          final totalProfit = allSales.fold(
            0.0,
            (sum, item) => sum + item.profit,
          );

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(theme),
              SliverToBoxAdapter(
                child: _buildFinancialSummary(theme, totalSales, totalProfit),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: CategorySelector(
                    isTheya: isTheya,
                    onChanged: (val) => setState(() => isTheya = val),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildSectionHeader(filteredSales.length),
              ),
              filteredSales.isEmpty
                  ? SliverFillRemaining(child: _buildEmptySales())
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _SaleHistoryCard(
                            sale: filteredSales[index],
                            businessId: widget.business.id,
                          ),
                          childCount: filteredSales.length,
                        ),
                      ),
                    ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: _buildFab(theme),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        widget.business.name.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: 1,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _handleDeleteBusiness(context, ref),
          icon: Icon(
            Icons.delete_outline_rounded,
            color: theme.colorScheme.error,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManageProductsView(business: widget.business),
            ),
          ),
          icon: Icon(
            Icons.inventory_2_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildFinancialSummary(ThemeData theme, double sales, double profit) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "NET PROFIT TODAY",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Rs. ${profit.toStringAsFixed(0)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat("REVENUE", "Rs. ${sales.toStringAsFixed(0)}"),
              _buildMiniStat(
                "MARGIN",
                "${sales > 0 ? ((profit / sales) * 100).toStringAsFixed(1) : 0}%",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "RECENT ACTIVITY",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            "$count Sales",
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySales() => const Center(
    child: Padding(
      padding: EdgeInsets.only(top: 40),
      child: Text(
        "No transactions recorded yet.",
        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
      ),
    ),
  );

  Widget _buildFab(ThemeData theme) => FloatingActionButton.extended(
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddUpdateSaleView(businessId: widget.business.id),
      ),
    ),
    backgroundColor: theme.colorScheme.primary,
    icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
    label: const Text(
      "RECORD SALE",
      style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
    ),
  );

  void _handleDeleteBusiness(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Delete Business?",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          "This will remove '${widget.business.name}' and all associated products and sales. This action is permanent.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(businessProvider.notifier)
                  .deleteBusiness(widget.business.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Exit Dashboard
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text(
              "DELETE",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleHistoryCard extends ConsumerWidget {
  final SaleModel sale;
  final String businessId;
  const _SaleHistoryCard({required this.sale, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = sale.profit > 0
        ? Colors.green.shade600
        : Colors.red.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AddUpdateSaleView(businessId: businessId, sale: sale),
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  sale.profit > 0 ? Icons.trending_up : Icons.trending_down,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.productTitle.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      "Qty: ${sale.quantity.toStringAsFixed(1)} • Rs. ${sale.soldAtPrice.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Rs. ${sale.profit.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const Text(
                    "PROFIT",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
