import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/models/business_model.dart';
import 'package:sprint_14/models/sale_model.dart';
import 'package:sprint_14/providers/business_provider/business_provider.dart';
import 'package:sprint_14/providers/product_provider/product_provider.dart';
import 'package:sprint_14/providers/sale_provider/sale_provider.dart';
import 'package:sprint_14/views/business_views/add_sale_view.dart';
import 'package:sprint_14/views/business_views/manage_products_view.dart';

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
      ref
          .read(productProvider.notifier)
          .loadProducts(widget.business.id, isTheya);
      ref.read(saleProvider.notifier).loadSales(widget.business.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sales = ref.watch(saleProvider);
    final theme = Theme.of(context);

    // Calculate Daily Stats
    final totalSales = sales.fold(0.0, (sum, item) => sum + item.soldAtPrice);
    final totalProfit = sales.fold(0.0, (sum, item) => sum + item.profit);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // 1. Premium Animated AppBar
          _buildSliverAppBar(theme),

          // 2. Main Financial Summary
          SliverToBoxAdapter(
            child: _buildFinancialSummary(theme, totalSales, totalProfit),
          ),

          // 4. Sales History Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "RECENT ACTIVITY",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    "${sales.length} Sales",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // 5. Sales List
          sales.isEmpty
              ? SliverFillRemaining(child: _buildEmptySales())
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _SaleHistoryCard(sale: sales[index]),
                      childCount: sales.length,
                    ),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: _buildFab(theme),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Text(
          widget.business.name,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _handleDeleteBusiness(context, ref),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: theme.colorScheme.error,
              size: 20,
            ),
          ),
        ),

        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManageProductsView(business: widget.business),
            ),
          ),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: theme.colorScheme.primary,
              size: 20,
            ),
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
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withBlue(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "NET PROFIT TODAY",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Rs. ${profit.toStringAsFixed(0)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white10),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat(
                "TOTAL REVENUE",
                "Rs. ${sales.toStringAsFixed(0)}",
              ),
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
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySales() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            "No transactions yet today",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AddSaleView(businessId: widget.business.id, isTheya: isTheya),
        ),
      ),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_shopping_cart_rounded),
      label: const Text(
        "RECORD SALE",
        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

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
          "This will remove '${widget.business.name}' and all associated data. This action is permanent once synced.",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCEL",
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // 1. Trigger soft delete in the notifier
              await ref
                  .read(businessProvider.notifier)
                  .deleteBusiness(widget.business.id);

              // 2. Close Dialog
              if (context.mounted) Navigator.pop(context);

              // 3. Navigate back to HomeView
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "DELETE",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleHistoryCard extends StatelessWidget {
  final SaleModel sale;
  const _SaleHistoryCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isProfitable = sale.profit > 0;
    final Color statusColor = isProfitable
        ? Colors.green.shade600
        : Colors.red.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        // Subtle depth shadow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          // Soft status accent border on the left
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Section with dynamic background
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isProfitable
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),

                // Content Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.productTitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildMiniBadge(
                            theme,
                            "QTY: ${sale.quantity.toStringAsFixed(0)}",
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Rs. ${sale.soldAtPrice.toStringAsFixed(0)}",
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Financial Summary Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${isProfitable ? '+' : ''}Rs. ${sale.profit.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "PROFIT",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
