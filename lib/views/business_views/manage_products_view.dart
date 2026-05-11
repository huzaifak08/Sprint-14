import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/components/category_selector.dart';
import 'package:sprint_14/components/sync_status_badge.dart';
import 'package:sprint_14/models/product_model.dart';
import 'package:sprint_14/providers/product_provider/product_provider.dart';
import 'package:sprint_14/views/business_views/add_update_product_view.dart';

class ManageProductsView extends ConsumerStatefulWidget {
  final String businessId;
  const ManageProductsView({super.key, required this.businessId});

  @override
  ConsumerState<ManageProductsView> createState() => _ManageProductsViewState();
}

class _ManageProductsViewState extends ConsumerState<ManageProductsView> {
  bool isTheyaView = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // Load the FULL unfiltered inventory for this business
      ref
          .read(productProvider(widget.businessId).notifier)
          .loadProducts(widget.businessId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productState = ref.watch(productProvider(widget.businessId));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(theme),

          // Category Selector
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                CategorySelector(
                  isTheya: isTheyaView,
                  onChanged: (val) => setState(() => isTheyaView = val),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Data Handling with UI-Side Filtering
          productState.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) =>
                SliverFillRemaining(child: Center(child: Text("Error: $err"))),
            data: (allProducts) {
              // 🔥 Filter the data right here in the UI
              final filteredProducts =
                  allProducts.where((p) => p.isTheya == isTheyaView).toList()
                    ..sort(
                      (a, b) => a.title.toLowerCase().compareTo(
                        b.title.toLowerCase(),
                      ),
                    );

              if (filteredProducts.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyCatalog(theme));
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ProductCatalogCard(
                      product: filteredProducts[index],
                      businessId: widget.businessId,
                    ),
                    childCount: filteredProducts.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _buildFab(theme),
    );
  }

  Widget _buildSliverHeader(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 80,
      pinned: true,
      centerTitle: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        "PRODUCT CATALOG",
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: 2,
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
            size: 48,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            "No ${isTheyaView ? 'Theya' : 'Inside'} items found.",
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
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
          builder: (_) => AddUpdateProductView(businessId: widget.businessId),
        ),
      ),
      backgroundColor: theme.colorScheme.primary,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        "NEW PRODUCT",
        style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }
}

class _ProductCatalogCard extends StatelessWidget {
  final ProductModel product;
  final String businessId;
  const _ProductCatalogCard({required this.product, required this.businessId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = product.isTheya
        ? Colors.amber.shade700
        : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AddUpdateProductView(businessId: businessId, product: product),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon Box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    product.classification.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "${product.classification} • ${product.unitType}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Rs. ${product.msrpPrice.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  SyncStatusBadge(isSynced: product.isSynced),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
