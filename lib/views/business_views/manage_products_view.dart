import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/models/business_model.dart';
import 'package:sprint_14/models/product_model.dart';
import 'package:sprint_14/providers/product_provider/product_provider.dart';
import 'package:sprint_14/views/business_views/add_update_product_view.dart';

class ManageProductsView extends ConsumerWidget {
  final BusinessModel business;
  const ManageProductsView({super.key, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final products = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Premium Header
          _buildSliverHeader(context, theme),

          // 2. Catalog Stats Summary
          SliverToBoxAdapter(child: _buildCatalogStats(theme, products)),

          // 3. Product List
          products.isEmpty
              ? SliverFillRemaining(child: _buildEmptyCatalog(theme))
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ProductCatalogCard(
                        product: products[index],
                        businessId: business.id,
                      ),
                      childCount: products.length,
                    ),
                  ),
                ),
        ],
      ),
      floatingActionButton: _buildFab(context, theme),
    );
  }

  Widget _buildSliverHeader(BuildContext context, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Text(
          "PRODUCT CATALOG",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogStats(ThemeData theme, List<ProductModel> products) {
    final theyaCount = products.where((p) => p.isTheya).length;
    final insideCount = products.length - theyaCount;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildStatChip(
            theme,
            "THEYA",
            theyaCount.toString(),
            Colors.amber.shade700,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            theme,
            "INSIDE",
            insideCount.toString(),
            theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    ThemeData theme,
    String label,
    String count,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 1,
              ),
            ),
            Text(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCatalog(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            "Catalog is empty.",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context, ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddUpdateProductView(businessId: business.id),
        ),
      ),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        "NEW PRODUCT",
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }
}

class _ProductCatalogCard extends ConsumerWidget {
  final ProductModel product;
  final String businessId;
  const _ProductCatalogCard({required this.product, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accentColor = product.isTheya
        ? Colors.amber.shade700
        : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddUpdateProductView(
                businessId: businessId,
                product: product,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Visual Indicator for Classification
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      product.classification.substring(0, 1),
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${product.classification} • ${product.unitType}",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Pricing Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Rs. ${product.msrpPrice.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "MSRP",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade400,
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
}
