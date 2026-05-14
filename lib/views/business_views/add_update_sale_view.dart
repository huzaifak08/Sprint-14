import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

  final List<_SaleBasketItem> _basketItems = [];

  final TextEditingController _billingController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  bool _saveAndAddAnother = false;

  bool _isEditMode = false;

  bool _isInitialized = false;

  double _totalMSRP = 0.0;

  double _totalCost = 0.0;

  double _profit = 0.0;

  @override
  void initState() {
    super.initState();

    _isEditMode = widget.sale != null;

    if (_isEditMode) {
      _selectedDate = widget.sale!.dateTime;
    }
  }

  @override
  void dispose() {
    _billingController.dispose();

    for (final item in _basketItems) {
      item.dispose();
    }

    super.dispose();
  }

  void _initializeEditData(List<ProductModel> products) {
    if (_isInitialized || widget.sale == null) return;

    final sale = widget.sale!;

    final matchedProducts = products
        .where((p) => sale.productIds.contains(p.id))
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _basketItems.clear();

        final bool isMultiProduct = matchedProducts.length > 1;

        for (final product in matchedProducts) {
          final bool isLinear =
              product.unitType == "Meter" || product.unitType == "Gazz";

          _basketItems.add(
            _SaleBasketItem(
              product: product,

              quantity: isMultiProduct ? 1 : sale.quantity,

              measurement: isLinear ? sale.measurement : 1,
            ),
          );
        }

        _billingController.text = sale.soldAtPrice.toStringAsFixed(0);

        _isInitialized = true;

        _recalculate();
      });
    });
  }

  void _recalculate() {
    double collectiveMsrp = 0;

    double collectiveCost = 0;

    for (final item in _basketItems) {
      final qty = double.tryParse(item.qtyController.text) ?? 1;

      final measurement = double.tryParse(item.measurementController.text) ?? 1;

      final bool isLinear =
          item.product.unitType == "Meter" || item.product.unitType == "Gazz";

      final effectiveQty = isLinear ? qty * measurement : qty;

      collectiveMsrp += item.product.msrpPrice * effectiveQty;

      collectiveCost += item.product.retailPrice * effectiveQty;
    }

    final billing = double.tryParse(_billingController.text) ?? 0;

    setState(() {
      _totalMSRP = collectiveMsrp;
      _totalCost = collectiveCost;
      _profit = billing - collectiveCost;
    });
  }

  void _resetForm() {
    for (final item in _basketItems) {
      item.dispose();
    }

    final preservedDate = _selectedDate;

    setState(() {
      _basketItems.clear();

      _billingController.clear();

      /// 🔥 Preserve selected date in bulk mode
      _selectedDate = preservedDate;

      _totalMSRP = 0;
      _totalCost = 0;
      _profit = 0;
    });
  }

  void _submit() {
    if (_basketItems.isEmpty) return;

    final totalQuantity = _basketItems.fold<double>(0, (sum, item) {
      final qty = double.tryParse(item.qtyController.text) ?? 1;

      return sum + qty;
    });

    final firstLinearItem = _basketItems.cast<_SaleBasketItem?>().firstWhere(
      (e) =>
          e != null &&
          (e.product.unitType == "Meter" || e.product.unitType == "Gazz"),
      orElse: () => null,
    );

    final measurement = firstLinearItem == null
        ? 1.0
        : (double.tryParse(firstLinearItem.measurementController.text) ?? 1.0);

    final sale = SaleModel(
      id: _isEditMode ? widget.sale!.id : AppData.shared.uuid.v4(),
      businessId: widget.businessId,
      productIds: _basketItems.map((e) => e.product.id).toList(),
      productTitles: _basketItems.map((e) => e.product.title).toList(),
      soldAtPrice: double.tryParse(_billingController.text) ?? 0,
      profit: _profit,
      quantity: totalQuantity,
      measurement: measurement,
      dateTime: _selectedDate,
      isSynced: false,
      isDeleted: false,
    );

    if (_isEditMode) {
      ref.read(saleProvider(widget.businessId).notifier).updateSale(sale);
    } else {
      ref.read(saleProvider(widget.businessId).notifier).recordSale(sale);
    }

    if (_saveAndAddAnother && !_isEditMode) {
      _resetForm();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Sale Recorded")));

      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final productState = ref.watch(productProvider(widget.businessId));

    productState.whenData((products) => _initializeEditData(products));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildHeader(theme),
      body: productState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (products) {
          final filteredProducts = products
              .where((p) => p.isTheya == _isTheyaFilter && p.isAvailableForSale)
              .toList();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildSectionLabel("TRANSACTION DATE"),

                    _buildDatePicker(theme),

                    _buildSectionLabel("SELECT PRODUCTS"),

                    CategorySelector(
                      isTheya: _isTheyaFilter,
                      onChanged: (val) {
                        FocusScope.of(context).unfocus();

                        setState(() {
                          _isTheyaFilter = val;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    _ProductDropdown(
                      key: ValueKey(_isTheyaFilter),
                      products: filteredProducts,
                      selectedProducts: _basketItems
                          .map((e) => e.product)
                          .toList(),
                      onSelected: (product) {
                        final exists = _basketItems.any(
                          (e) => e.product.id == product.id,
                        );

                        if (exists) return;

                        setState(() {
                          _basketItems.add(_SaleBasketItem(product: product));

                          if (_basketItems.length == 1) {
                            _billingController.text = product.msrpPrice
                                .toStringAsFixed(0);
                          }

                          _recalculate();
                        });
                      },
                    ),

                    _buildSectionLabel("BASKET"),

                    _buildBasket(theme),

                    _buildSectionLabel("COLLECTIVE BILLING"),

                    _buildBillingField(theme),

                    const SizedBox(height: 28),

                    if (_basketItems.isNotEmpty) _buildProfitCard(theme),

                    if (!_isEditMode) _buildBulkToggle(theme),

                    const SizedBox(height: 40),
                  ],
                ),
              ),

              _buildSubmitButton(theme),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildHeader(ThemeData theme) {
    return AppBar(
      title: Text(
        _isEditMode ? "UPDATE SALE" : "RECORD SALE",
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 2,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      actions: [
        if (_isEditMode)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
            ),
            onPressed: () => _confirmDelete(context),
          ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Remove Sale?"),
          content: const Text(
            "This sale will permanently be removed from your device and database.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            TextButton(
              onPressed: () {
                if (widget.sale != null) {
                  ref
                      .read(saleProvider(widget.businessId).notifier)
                      .deleteSale(widget.sale!.id, widget.businessId);
                }

                Navigator.pop(context);

                Navigator.pop(context);
              },
              child: const Text("DELETE", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDatePicker(ThemeData theme) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );

        if (d != null) {
          setState(() {
            _selectedDate = d;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasket(ThemeData theme) {
    if (_basketItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: const Center(
          child: Text(
            "Basket is empty",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      children: _basketItems.map((item) {
        final product = item.product;

        final bool isLinear =
            product.unitType == "Meter" || product.unitType == "Gazz";

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.title.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        item.dispose();

                        _basketItems.remove(item);

                        _recalculate();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _inputCard(
                      theme,
                      label: "QUANTITY",
                      controller: item.qtyController,
                      onChanged: (_) => _recalculate(),
                    ),
                  ),

                  if (isLinear) const SizedBox(width: 12),

                  if (isLinear)
                    Expanded(
                      child: _inputCard(
                        theme,
                        label:
                            "MEASUREMENT (${product.unitType.toUpperCase()})",
                        controller: item.measurementController,
                        onChanged: (_) => _recalculate(),
                      ),
                    ),
                ],
              ),

              if (isLinear) ...[
                const SizedBox(height: 18),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "LINEAR MEASUREMENT",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          "${item.measurementController.text} ${product.unitType}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),

                    Slider(
                      value: (() {
                        final parsed =
                            double.tryParse(item.measurementController.text) ??
                            1;

                        return parsed.clamp(0.25, 20.0);
                      })(),
                      min: 0.25,
                      max: 20,
                      divisions: 79,
                      activeColor: theme.colorScheme.primary,
                      inactiveColor: theme.colorScheme.primary.withValues(
                        alpha: 0.15,
                      ),
                      onChanged: (v) {
                        HapticFeedback.selectionClick();

                        setState(() {
                          item.measurementController.text = v.toStringAsFixed(
                            2,
                          );

                          _recalculate();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBillingField(ThemeData theme) {
    return _inputCard(
      theme,
      label: "TOTAL BILLING (PKR)",
      controller: _billingController,
      onChanged: (_) => _recalculate(),
    );
  }

  Widget _inputCard(
    ThemeData theme, {
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              if (label.contains("MEASUREMENT")) {
                final parsed = double.tryParse(value);

                if (parsed == null || parsed <= 0) {
                  controller.text = "0.25";

                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                }
              }

              onChanged(value);
            },
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCard(ThemeData theme) {
    final healthy = _profit >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "COLLECTIVE MSRP",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                ),
              ),
              Text(
                "Rs. ${_totalMSRP.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const Divider(height: 28),

          Row(
            children: [
              _statBlock(
                "YOUR COST",
                "Rs. ${_totalCost.toStringAsFixed(0)}",
                theme.colorScheme.onSurface,
              ),
              _statBlock(
                healthy ? "NET PROFIT" : "NET LOSS",
                "Rs. ${_profit.toStringAsFixed(0)}",
                healthy ? Colors.green : Colors.red,
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
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkToggle(ThemeData theme) {
    return SwitchListTile.adaptive(
      value: _saveAndAddAnother,
      onChanged: (v) {
        setState(() {
          _saveAndAddAnother = v;
        });
      },
      title: const Text(
        "Bulk Mode",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      secondary: Icon(Icons.layers_outlined, color: theme.colorScheme.primary),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: _basketItems.isEmpty ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            _isEditMode ? "SAVE CHANGES" : "RECORD TRANSACTION",
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.grey,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SaleBasketItem {
  final ProductModel product;

  final TextEditingController qtyController;

  final TextEditingController measurementController;

  _SaleBasketItem({
    required this.product,
    double quantity = 1,
    double measurement = 1,
  }) : qtyController = TextEditingController(
         text: quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 2),
       ),
       measurementController = TextEditingController(
         text: measurement.toStringAsFixed(2),
       );

  void dispose() {
    qtyController.dispose();
    measurementController.dispose();
  }
}

class _ProductDropdown extends StatefulWidget {
  final List<ProductModel> products;

  final List<ProductModel> selectedProducts;

  final Function(ProductModel) onSelected;

  const _ProductDropdown({
    super.key,
    required this.products,
    required this.selectedProducts,
    required this.onSelected,
  });

  @override
  State<_ProductDropdown> createState() => _ProductDropdownState();
}

class _ProductDropdownState extends State<_ProductDropdown> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final products = [...widget.products];

    products.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );

    return DropdownButtonFormField<ProductModel>(
      initialValue: null,
      isExpanded: true,
      hint: const Text("Tap to add item...", style: TextStyle(fontSize: 13)),
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.add_shopping_cart_rounded),
      ),
      items: products.map((p) {
        final alreadySelected = widget.selectedProducts.any(
          (e) => e.id == p.id,
        );

        return DropdownMenuItem<ProductModel>(
          value: p,
          enabled: !alreadySelected,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "${p.title.toUpperCase()} (${p.classification})",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: alreadySelected ? Colors.grey : null,
                  ),
                ),
              ),
              if (alreadySelected)
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
            ],
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val == null) return;

        widget.onSelected(val);

        Future.microtask(() {
          if (mounted) {
            setState(() {});
          }
        });
      },
    );
  }
}
