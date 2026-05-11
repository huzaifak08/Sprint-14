import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/providers/business_provider/business_provider.dart';
import 'package:sprint_14/providers/product_provider/product_provider.dart';
import 'package:sprint_14/providers/sale_provider/sale_provider.dart';
import 'package:sprint_14/views/business_views/add_update_sale_view.dart';
import 'package:sprint_14/views/business_views/business_dashboard_view/business_dashboard_view_model.dart';
import 'package:sprint_14/views/business_views/business_dashboard_view/components/date_filter_controls.dart';
import 'package:sprint_14/views/business_views/business_dashboard_view/components/header_section.dart';
import 'package:sprint_14/views/business_views/business_dashboard_view/components/sales_data_table.dart';
import 'package:sprint_14/views/business_views/business_dashboard_view/components/summary_card.dart';
import 'package:sprint_14/views/business_views/business_dashboard_view/components/weekly_trend_chart.dart';
import 'package:sprint_14/views/business_views/manage_products_view.dart';

class BusinessDashboardView extends ConsumerStatefulWidget {
  final String businessId;
  const BusinessDashboardView({super.key, required this.businessId});

  @override
  ConsumerState<BusinessDashboardView> createState() =>
      _BusinessDashboardViewState();
}

class _BusinessDashboardViewState extends ConsumerState<BusinessDashboardView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLogic();
  }

  void _initLogic() {
    Connectivity().onConnectivityChanged.listen((result) {
      // Check if any connection exists to trigger sync
      if (result.any((r) => r != ConnectivityResult.none)) {
        ref.read(businessProvider.notifier).syncPending();
        ref
            .read(productProvider(widget.businessId).notifier)
            .syncPending(widget.businessId);
        ref
            .read(saleProvider(widget.businessId).notifier)
            .syncPending(widget.businessId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final saleState = ref.watch(saleProvider(widget.businessId));
    final productState = ref.watch(productProvider(widget.businessId));
    final uiState = ref.watch(dashboardUiProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: _buildFab(context, theme),
      body: saleState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
        data: (allSales) {
          final allProducts = productState.value ?? [];

          // 🔥 FIXED: Multi-product dynamic filtering
          final filteredSales = allSales.where((sale) {
            final dateMatch = _checkDateMatch(sale.dateTime, uiState);
            if (!dateMatch) return false;

            if (uiState.searchQuery.isNotEmpty) {
              final q = uiState.searchQuery.toLowerCase();

              // 1. Check if any title in the basket matches search
              final titleMatch = sale.productTitles.any(
                (title) => title.toLowerCase().contains(q),
              );

              // 2. Check if any associated product category/type matches
              final metaMatch = allProducts
                  .where((p) => sale.productIds.contains(p.id))
                  .any(
                    (p) =>
                        p.classification.toLowerCase().contains(q) ||
                        (p.isTheya ? "theya" : "inside").contains(q),
                  );

              return titleMatch || metaMatch;
            }
            return true;
          }).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, ref, uiState, widget.businessId, theme),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SummaryCard(sales: filteredSales),
                    const SizedBox(height: 24),
                    WeeklyTrendChart(sales: filteredSales),
                    const SizedBox(height: 24),
                    const DateFilterControls(),
                    const SizedBox(height: 32),
                    HeaderSection(
                      uiState: uiState,
                      count: filteredSales.length,
                    ),
                    const SizedBox(height: 12),
                    SalesDataTable(
                      sales: filteredSales,
                      businessId: widget.businessId,
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFab(BuildContext context, ThemeData theme) {
    return FloatingActionButton.extended(
      heroTag: null, // 🔥 FIX: Prevents lag and multiple hero tag exceptions
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddUpdateSaleView(businessId: widget.businessId),
        ),
      ),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      elevation: 4,
      icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
      label: const Text(
        "RECORD SALE",
        style: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  bool _checkDateMatch(DateTime saleDate, DashboardUiState ui) {
    if (ui.activeFilter == DashboardFilterType.daily) {
      return DateUtils.isSameDay(saleDate, ui.selectedDate);
    } else if (ui.activeFilter == DashboardFilterType.monthly) {
      return saleDate.month == ui.selectedDate.month &&
          saleDate.year == ui.selectedDate.year;
    } else if (ui.activeFilter == DashboardFilterType.yearly) {
      return saleDate.year == ui.selectedDate.year;
    }
    return true;
  }

  Widget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    DashboardUiState ui,
    String businessId,
    ThemeData theme,
  ) {
    final notifier = ref.read(dashboardUiProvider.notifier);
    final businessState = ref.watch(singleBusinessProvider(businessId));

    if (ui.isSearching) {
      return SliverAppBar(
        pinned: true,
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: notifier.toggleSearch,
        ),
        title: TextField(
          autofocus: true,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: "Search in basket titles...",
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          onChanged: notifier.updateSearch,
        ),
      );
    }
    return SliverAppBar(
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      title: Text(
        businessState.maybeWhen(
          data: (business) => business.name,
          orElse: () => "BUSINESS",
        ),
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 2,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.layers_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ManageProductsView(businessId: widget.businessId),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(
            ui.isSelectionMode
                ? Icons.check_circle
                : Icons.check_circle_outline,
            color: ui.isSelectionMode ? theme.colorScheme.primary : null,
          ),
          onPressed: notifier.toggleSelectionMode,
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: notifier.toggleSearch,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
