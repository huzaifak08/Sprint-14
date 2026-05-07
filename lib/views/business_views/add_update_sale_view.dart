import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_14/components/category_selector.dart';
import 'package:sprint_14/helpers/app_data.dart';
import 'package:sprint_14/models/product_model.dart';
import 'package:sprint_14/models/sale_model.dart';
import 'package:sprint_14/providers/product_provider/product_provider.dart';
import 'package:sprint_14/providers/sale_provider/sale_provider.dart';

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
  bool _isInitialized = false; // Prevents re-initialization loops

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.sale != null;
    if (!_isEditMode) {
      _qtyController.text = "1";
    }
  }

  /// Reactive initialization: Populates fields once products are available
  void _initializeEditData(List<ProductModel> products) {
    if (_isInitialized || widget.sale == null) return;

    final sale = widget.sale!;
    final product = products.cast<ProductModel?>().firstWhere(
      (p) => p?.id == sale.productId,
      orElse: () => null,
    );

    if (product != null) {
      // Use addPostFrameCallback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedProduct = product;
          _isTheyaFilter = product.isTheya;
          _priceController.text = sale.soldAtPrice.toStringAsFixed(0);

          final isLinear =
              product.unitType == "Meter" || product.unitType == "Gazz";
          if (isLinear) {
            _measurementValue = sale.quantity;
            _qtyController.text = "1";
          } else {
            _qtyController.text = sale.quantity.toStringAsFixed(0);
          }

          _isInitialized = true;
          _updateProfit();
        });
      });
    }
  }

  void _updateProfit() {
    if (_selectedProduct == null) return;

    final totalBilling = double.tryParse(_priceController.text) ?? 0.0;
    final multiplier = double.tryParse(_qtyController.text) ?? 1.0;

    final bool isLinear =
        _selectedProduct!.unitType == "Meter" ||
        _selectedProduct!.unitType == "Gazz";
    final totalQty = isLinear ? (_measurementValue * multiplier) : multiplier;

    setState(() {
      final totalCostOfStock = _selectedProduct!.retailPrice * totalQty;
      _currentProfit = totalBilling - totalCostOfStock;
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
    final productState = ref.watch(productProvider(widget.businessId));

    // Reactive Listener: Auto-populates when data arrives
    productState.whenData((products) => _initializeEditData(products));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: productState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (products) => Column(
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
                        _buildProductSelector(theme, products),
                        const SizedBox(height: 24),
                        if (_selectedProduct != null) ...[
                          _buildMeasurementSection(theme),
                          const SizedBox(height: 24),
                        ],
                        _buildSectionLabel("TRANSACTION DETAILS"),
                        const SizedBox(height: 12),
                        _buildInputGrid(theme),
                        const SizedBox(height: 32),
                        if (_selectedProduct != null)
                          _buildProfitInsight(theme),
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
    List<ProductModel> allProducts,
  ) {
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
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.inventory_2_outlined),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            _priceController.text = val?.msrpPrice.toStringAsFixed(0) ?? "";
            _measurementValue = 1.0;
            _updateProfit();
          });
        },
      ),
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
            label: "FINAL BILLING (PKR)",
            controller: _priceController,
            isNumber: true,
            hint: "Total Amount",
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
    if (_selectedProduct == null) return const SizedBox.shrink();

    final isHealthy = _currentProfit >= 0;
    final accentColor = isHealthy ? Colors.green.shade600 : Colors.red.shade600;

    final multiplier = double.tryParse(_qtyController.text) ?? 1.0;
    final bool isLinear =
        _selectedProduct!.unitType == "Meter" ||
        _selectedProduct!.unitType == "Gazz";
    final totalQty = isLinear ? (_measurementValue * multiplier) : multiplier;

    final totalCost = _selectedProduct!.retailPrice * totalQty;
    final suggestedMSRP = _selectedProduct!.msrpPrice * totalQty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "CATALOG PRICE (MSRP)",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                ),
              ),
              Text(
                "Rs. ${suggestedMSRP.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _statBlock(
                "YOUR COST",
                "Rs. ${totalCost.toStringAsFixed(0)}",
                Colors.grey.shade700,
              ),
              Container(
                height: 30,
                width: 1,
                color: theme.colorScheme.outline.withOpacity(0.2),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _statBlock(
                isHealthy ? "NET PROFIT" : "NET LOSS",
                "Rs. ${_currentProfit.toStringAsFixed(0)}",
                accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBlock(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
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
                  .read(saleProvider(widget.businessId).notifier)
                  .deleteSale(widget.sale!.id, widget.businessId);
              Navigator.pop(context);
              Navigator.pop(context);
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
    final totalBilling = double.tryParse(_priceController.text) ?? 0.0;
    final multiplier = double.tryParse(_qtyController.text) ?? 1.0;
    final bool isLinear =
        _selectedProduct!.unitType == "Meter" ||
        _selectedProduct!.unitType == "Gazz";
    final finalQuantity = isLinear
        ? (_measurementValue * multiplier)
        : multiplier;

    final sale = SaleModel(
      id: _isEditMode ? widget.sale!.id : AppData.shared.uuid.v4(),
      businessId: widget.businessId,
      productId: _selectedProduct!.id,
      productTitle: _selectedProduct!.title,
      soldAtPrice: totalBilling,
      profit: _currentProfit,
      quantity: finalQuantity,
      dateTime: _isEditMode ? widget.sale!.dateTime : DateTime.now(),
      isSynced: false,
      isDeleted: false,
    );

    if (_isEditMode) {
      ref.read(saleProvider(widget.businessId).notifier).updateSale(sale);
    } else {
      ref.read(saleProvider(widget.businessId).notifier).recordSale(sale);
    }
    Navigator.pop(context);
  }
}
