import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/models/business_model.dart';
import 'package:sprint_14/models/product_model.dart';
import 'package:sprint_14/providers/product_provider/product_provider.dart';
import 'package:sprint_14/views/business_views/add_update_product_view.dart';

class ManageProductsView extends ConsumerStatefulWidget {
  final BusinessModel business;
  const ManageProductsView({super.key, required this.business});

  @override
  ConsumerState<ManageProductsView> createState() => _ManageProductsViewState();
}

class _ManageProductsViewState extends ConsumerState<ManageProductsView> {
  // We keep track of the current view filter (Theya vs Inside)
  bool isTheyaView = false;

  @override
  void initState() {
    super.initState();
    // 🔥 Trigger the contextual load immediately on entry
    Future.microtask(() {
      _fetchProducts();
    });
  }

  void _fetchProducts() {
    ref
        .read(productProvider.notifier)
        .loadProducts(widget.business.id, isTheyaView);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Watch the AsyncValue from the new ProductNotifier
    final productState = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Premium Header
          _buildSliverHeader(context, theme),

          // 2. Catalog Stats Summary & Tab Toggle
          productState.when(
            data: (products) => SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildCatalogStats(theme, products),
                  const SizedBox(height: 12),
                  _buildToggleFilter(theme),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // 3. Product List Handling
          productState.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) =>
                SliverFillRemaining(child: Center(child: Text("Error: $err"))),
            data: (products) => products.isEmpty
                ? SliverFillRemaining(child: _buildEmptyCatalog(theme))
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ProductCatalogCard(
                          product: products[index],
                          businessId: widget.business.id,
                        ),
                        childCount: products.length,
                      ),
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

  Widget _buildToggleFilter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _filterButton("INSIDE", !isTheyaView, theme.colorScheme.primary),
          const SizedBox(width: 10),
          _filterButton("THEYA", isTheyaView, Colors.amber.shade700),
        ],
      ),
    );
  }

  Widget _filterButton(String label, bool active, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => isTheyaView = (label == "THEYA"));
          _fetchProducts();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? color : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: active ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogStats(ThemeData theme, List<ProductModel> products) {
    // In a real scenario, you'd likely fetch total counts from a separate provider
    // or local DB, but for the current view:
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildStatChip(
            theme,
            "Total Products",
            products.length.toString(),
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
          builder: (_) => AddUpdateProductView(businessId: widget.business.id),
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
