import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/models/product_model.dart';
import 'package:sprint_14/models/sale_model.dart';
import 'package:sprint_14/providers/product_provider/product_provider.dart';
import 'package:sprint_14/providers/sale_provider/sale_provider.dart';
import 'package:uuid/uuid.dart';

class AddSaleView extends ConsumerStatefulWidget {
  final String businessId;
  final bool isTheya;

  const AddSaleView({
    super.key,
    required this.businessId,
    required this.isTheya,
  });

  @override
  ConsumerState<AddSaleView> createState() => _AddSaleViewState();
}

class _AddSaleViewState extends ConsumerState<AddSaleView> {
  ProductModel? _selectedProduct;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: "1");
  double _currentProfit = 0.0;

  @override
  void dispose() {
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _updateProfit() {
    if (_selectedProduct == null) return;
    final soldPrice = double.tryParse(_priceController.text) ?? 0.0;
    final qty = double.tryParse(_qtyController.text) ?? 1.0;
    setState(() {
      _currentProfit = (soldPrice - _selectedProduct!.retailPrice) * qty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      // Using a CustomScrollView to ensure no overflow when keyboard appears
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildModernHeader(theme),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 24),
                      _buildSectionLabel("INVENTORY SELECTION"),
                      const SizedBox(height: 12),
                      _buildProductSelector(theme, products),
                      const SizedBox(height: 24),
                      _buildSectionLabel("TRANSACTION DETAILS"),
                      const SizedBox(height: 12),
                      _buildInputGrid(theme),
                      const SizedBox(height: 32),
                      if (_selectedProduct != null) _buildProfitInsight(theme),
                      const SizedBox(height: 40), // Bottom padding for scroll
                    ]),
                  ),
                ),
              ],
            ),
          ),
          _buildConfirmButton(theme),
        ],
      ),
    );
  }

  Widget _buildModernHeader(ThemeData theme) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      expandedHeight: 100,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Text(
          "Record ${widget.isTheya ? 'Theya' : 'Inside'} Sale",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildProductSelector(ThemeData theme, List<ProductModel> products) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonFormField<ProductModel>(
        value: _selectedProduct,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.colorScheme.primary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          hintText: "Search Catalog...",
        ),
        items: products
            .map(
              (p) => DropdownMenuItem(
                value: p,
                child: Text(
                  "${p.title} (${p.classification})",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (val) {
          setState(() {
            _selectedProduct = val;
            _priceController.text = val?.msrpPrice.toString() ?? "";
            _updateProfit();
          });
        },
      ),
    );
  }

  Widget _buildInputGrid(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quantity Field
        Expanded(
          flex: 1,
          child: _buildRefinedField(
            theme,
            label: "QTY",
            controller: _qtyController,
            isNumber: true,
          ),
        ),
        const SizedBox(width: 12),
        // Price Field
        Expanded(
          flex: 2,
          child: _buildRefinedField(
            theme,
            label: "SALE PRICE (PKR)",
            controller: _priceController,
            isNumber: true,
            hint: _selectedProduct != null
                ? "Suggest: ${_selectedProduct!.msrpPrice}"
                : "0",
          ),
        ),
      ],
    );
  }

  Widget _buildRefinedField(
    ThemeData theme, {
    required String label,
    required TextEditingController controller,
    bool isNumber = false,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            onChanged: (_) => _updateProfit(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitInsight(ThemeData theme) {
    final isHealthy = _currentProfit >= 0;
    final accentColor = isHealthy ? Colors.green.shade600 : Colors.red.shade600;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accentColor.withOpacity(0.1),
            child: Icon(
              isHealthy ? Icons.trending_up : Icons.trending_down,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHealthy ? "PROFIT" : "LOSS",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
                Text(
                  "Rs. ${_currentProfit.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.05)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _selectedProduct == null ? null : _submitSale,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            "CONFIRM SALE",
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  void _submitSale() {
    final sale = SaleModel(
      id: const Uuid().v4(),
      businessId: widget.businessId,
      productId: _selectedProduct!.id,
      productTitle: _selectedProduct!.title,
      soldAtPrice: double.parse(_priceController.text),
      profit: _currentProfit,
      quantity: double.parse(_qtyController.text),
      dateTime: DateTime.now(),
      isSynced: false,
      isDeleted: false,
    );
    ref.read(saleProvider.notifier).recordSale(sale);
    Navigator.pop(context);
  }
}
