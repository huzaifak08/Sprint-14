import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/components/category_selector.dart';
import 'package:sprint_14/models/product_model.dart';
import 'package:sprint_14/models/sale_model.dart';
import 'package:sprint_14/providers/product_provider/product_provider.dart';
import 'package:sprint_14/providers/sale_provider/sale_provider.dart';
import 'package:uuid/uuid.dart';

class AddUpdateSaleView extends ConsumerStatefulWidget {
  final String businessId;
  final SaleModel? sale;

  const AddUpdateSaleView({super.key, required this.businessId, this.sale});

  @override
  ConsumerState<AddUpdateSaleView> createState() => _AddUpdateSaleViewState();
}

class _AddUpdateSaleViewState extends ConsumerState<AddUpdateSaleView> {
  bool _isTheyaFilter = false;
  ProductModel? _selectedProduct;

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();

  double _measurementValue = 1.0;
  double _currentProfit = 0.0;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.sale != null;

    if (_isEditMode) {
      _initializeEditData();
    } else {
      _qtyController.text = "1";
    }
  }

  void _initializeEditData() {
    final sale = widget.sale!;
    _priceController.text = sale.soldAtPrice.toString();

    // Check if we need to split quantity into measurement and pieces
    // Note: This logic assumes we can find the product to check its unit type
    Future.microtask(() {
      final products = ref.read(productProvider).value ?? [];
      final product = products.firstWhere((p) => p.id == sale.productId);

      setState(() {
        _selectedProduct = product;
        _isTheyaFilter = product.isTheya;

        if (product.unitType == "Meter" || product.unitType == "Gazz") {
          // If total quantity is 7.5 and piece multiplier is 1 (default during edit)
          // You might need a more complex way to store original pieces vs length,
          // but here we default to the total quantity as length and 1 as piece.
          _measurementValue = sale.quantity;
          _qtyController.text = "1";
        } else {
          _qtyController.text = sale.quantity.toStringAsFixed(0);
        }
        _updateProfit();
      });
    });
  }

  void _updateProfit() {
    if (_selectedProduct == null) return;

    final soldPrice = double.tryParse(_priceController.text) ?? 0.0;
    final multiplier = double.tryParse(_qtyController.text) ?? 1.0;

    final bool isLinear =
        _selectedProduct!.unitType == "Meter" ||
        _selectedProduct!.unitType == "Gazz";
    final totalUnitsSold = isLinear
        ? (_measurementValue * multiplier)
        : multiplier;

    setState(() {
      _currentProfit =
          (soldPrice - _selectedProduct!.retailPrice) * totalUnitsSold;
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productState = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(theme),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 24),
                      _buildSectionLabel("SELECT CATALOG CATEGORY"),
                      const SizedBox(height: 12),
                      CategorySelector(
                        isTheya: _isTheyaFilter,
                        onChanged: (val) {
                          setState(() {
                            _isTheyaFilter = val;
                            _selectedProduct = null;
                            _priceController.clear();
                            _currentProfit = 0;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionLabel("AVAILABLE INVENTORY"),
                      const SizedBox(height: 12),
                      _buildProductSelector(theme, productState),
                      const SizedBox(height: 24),
                      if (_selectedProduct != null) ...[
                        _buildMeasurementSection(theme),
                        const SizedBox(height: 24),
                      ],
                      _buildSectionLabel("TRANSACTION DETAILS"),
                      const SizedBox(height: 12),
                      _buildInputGrid(theme),
                      const SizedBox(height: 32),
                      if (_selectedProduct != null) _buildProfitInsight(theme),
                      const SizedBox(height: 40),
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

  Widget _buildHeader(ThemeData theme) {
    return SliverAppBar(
      pinned: true,
      centerTitle: true,
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _isEditMode ? "UPDATE SALE" : "RECORD SALE",
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: 2,
        ),
      ),
      actions: [
        if (_isEditMode)
          IconButton(
            onPressed: () => _handleDelete(theme),
            icon: Icon(
              Icons.delete_outline_rounded,
              color: theme.colorScheme.error,
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProductSelector(
    ThemeData theme,
    AsyncValue<List<ProductModel>> state,
  ) {
    return state.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text("Error: $e"),
      data: (allProducts) {
        final filteredList = allProducts
            .where((p) => p.isTheya == _isTheyaFilter)
            .toList();

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: DropdownButtonFormField<ProductModel>(
            value: _selectedProduct,
            hint: Text("Select ${_isTheyaFilter ? 'Theya' : 'Inside'} Item..."),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: filteredList
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(
                      p.title.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedProduct = val;
                _priceController.text = val?.msrpPrice.toString() ?? "";
                _measurementValue = 1.0;
                _updateProfit();
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildMeasurementSection(ThemeData theme) {
    final bool isLinear =
        _selectedProduct!.unitType == "Meter" ||
        _selectedProduct!.unitType == "Gazz";
    if (!isLinear) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel("MEASUREMENT"),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_measurementValue.toStringAsFixed(2)} ${_selectedProduct!.unitType}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Icon(Icons.straighten_rounded, color: Colors.grey),
                ],
              ),
              Slider(
                value: _measurementValue,
                min: 0.25,
                max: 10.0,
                divisions: 39,
                activeColor: theme.colorScheme.primary,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _measurementValue = val;
                    _updateProfit();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputGrid(ThemeData theme) {
    final isLinear =
        _selectedProduct?.unitType == "Meter" ||
        _selectedProduct?.unitType == "Gazz";
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildRefinedField(
            theme,
            label: isLinear ? "PIECES" : "QTY",
            controller: _qtyController,
            isNumber: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _buildRefinedField(
            theme,
            label: "UNIT PRICE",
            controller: _priceController,
            isNumber: true,
            hint: "0.0",
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            onChanged: (_) => _updateProfit(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: hint,
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
          Icon(
            isHealthy ? Icons.trending_up : Icons.trending_down,
            color: accentColor,
            size: 32,
          ),
          const SizedBox(width: 16),
          Column(
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
        height: 58,
        child: ElevatedButton(
          onPressed: _selectedProduct == null ? null : _submitSale,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 0,
          ),
          child: Text(
            _isEditMode ? "SAVE CHANGES" : "RECORD TRANSACTION",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w900,
      color: Colors.grey,
      letterSpacing: 1.5,
    ),
  );

  void _handleDelete(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Delete Sale?",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          "This will permanently remove this transaction from your ledger.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(saleProvider.notifier)
                  .deleteSale(widget.sale!.id, widget.businessId);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close view
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _submitSale() {
    final multiplier = double.tryParse(_qtyController.text) ?? 1.0;
    final bool isLinear =
        _selectedProduct!.unitType == "Meter" ||
        _selectedProduct!.unitType == "Gazz";
    final finalQuantity = isLinear
        ? (_measurementValue * multiplier)
        : multiplier;

    final sale = SaleModel(
      id: _isEditMode ? widget.sale!.id : const Uuid().v4(),
      businessId: widget.businessId,
      productId: _selectedProduct!.id,
      productTitle: _selectedProduct!.title,
      soldAtPrice: double.parse(_priceController.text),
      profit: _currentProfit,
      quantity: finalQuantity,
      dateTime: _isEditMode ? widget.sale!.dateTime : DateTime.now(),
      isSynced: false,
      isDeleted: false,
    );

    if (_isEditMode) {
      ref.read(saleProvider.notifier).updateSale(sale);
    } else {
      ref.read(saleProvider.notifier).recordSale(sale);
    }
    Navigator.pop(context);
  }
}
