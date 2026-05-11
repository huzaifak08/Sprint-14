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

  final List<ProductModel> _selectedProducts = [];

  final TextEditingController _priceController = TextEditingController();

  final TextEditingController _qtyController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  bool _saveAndAddAnother = false;

  double _measurementValue = 1.0;

  double _totalMSRP = 0.0;

  double _totalCost = 0.0;

  double _currentProfit = 0.0;

  bool _isEditMode = false;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    _isEditMode = widget.sale != null;

    _qtyController.text = "1";

    if (_isEditMode) {
      _selectedDate = widget.sale!.dateTime;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _initializeEditData(List<ProductModel> products) {
    if (_isInitialized || widget.sale == null) return;

    final matching = products
        .where((p) => widget.sale!.productIds.contains(p.id))
        .toList();

    if (matching.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() {
          _selectedProducts.clear();
          _selectedProducts.addAll(matching);

          _priceController.text = widget.sale!.soldAtPrice.toStringAsFixed(0);

          _isInitialized = true;

          _updateProfit();
        });
      });
    }
  }

  void _updateProfit() {
    if (_selectedProducts.isEmpty) {
      setState(() {
        _totalMSRP = 0;
        _totalCost = 0;
        _currentProfit = 0;
      });

      return;
    }

    final totalBilling = double.tryParse(_priceController.text) ?? 0.0;

    final multiplier = double.tryParse(_qtyController.text) ?? 1.0;

    double collectiveMSRP = 0.0;

    double collectiveCost = 0.0;

    for (final p in _selectedProducts) {
      final bool isLinear = p.unitType == "Meter" || p.unitType == "Gazz";

      final itemQty = isLinear ? (_measurementValue * multiplier) : multiplier;

      collectiveMSRP += (p.msrpPrice * itemQty);

      collectiveCost += (p.retailPrice * itemQty);
    }

    setState(() {
      _totalMSRP = collectiveMSRP;
      _totalCost = collectiveCost;
      _currentProfit = totalBilling - collectiveCost;
    });
  }

  void _submit() {
    final sale = SaleModel(
      id: _isEditMode ? widget.sale!.id : AppData.shared.uuid.v4(),
      businessId: widget.businessId,
      productIds: _selectedProducts.map((p) => p.id).toList(),
      productTitles: _selectedProducts.map((p) => p.title).toList(),
      soldAtPrice: double.tryParse(_priceController.text) ?? 0.0,
      profit: _currentProfit,
      quantity: double.tryParse(_qtyController.text) ?? 1.0,
      dateTime: _selectedDate,
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

                    /// 🔥 FIXED DROPDOWN
                    _ProductDropdown(
                      key: ValueKey(_isTheyaFilter),
                      products: filteredProducts,
                      selectedProducts: _selectedProducts,
                      onSelected: (product) {
                        setState(() {
                          final exists = _selectedProducts.any(
                            (p) => p.id == product.id,
                          );

                          if (!exists) {
                            _selectedProducts.add(product);

                            if (_selectedProducts.length == 1) {
                              _priceController.text = product.msrpPrice
                                  .toStringAsFixed(0);
                            }

                            _updateProfit();
                          }
                        });
                      },
                    ),

                    _buildSectionLabel("BASKET"),

                    _buildBasketList(theme),

                    if (_selectedProducts.any(
                      (p) => p.unitType == "Meter" || p.unitType == "Gazz",
                    ))
                      _buildMeasurementSection(theme),

                    _buildSectionLabel("TRANSACTION DETAILS"),

                    _buildInputGrid(theme),

                    const SizedBox(height: 32),

                    if (_selectedProducts.isNotEmpty)
                      _buildProfitInsight(theme),

                    if (!_isEditMode) _buildBulkToggle(theme),

                    const SizedBox(height: 40),
                  ],
                ),
              ),

              _buildConfirmButton(theme),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildHeader(ThemeData theme) => AppBar(
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
      if (_isEditMode) ...{
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
      },
    ],
  );

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Remove Sale?"),
        content: const Text(
          "This Sale will permanently be remove from your device as well as our Database.",
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
                    .deleteSale(
                      widget.sale?.id ?? 'NO SALE ID',
                      widget.businessId,
                    );
              }

              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(ThemeData theme) => InkWell(
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
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
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

  Widget _buildBasketList(ThemeData theme) {
    if (_selectedProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
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
      children: _selectedProducts
          .map(
            (p) => Padding(
              padding: const EdgeInsets.only(
                bottom: 8.0,
              ), // 🔥 Added space between products
              child: ListTile(
                dense: true,
                tileColor: theme.colorScheme.primary.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  p.title.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: () => setState(() {
                    _selectedProducts.removeWhere((e) => e.id == p.id);
                    _updateProfit();
                  }),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMeasurementSection(ThemeData theme) {
    final linearProduct = _selectedProducts.firstWhere(
      (p) => p.unitType == "Meter" || p.unitType == "Gazz",
    );

    final unitType = linearProduct.unitType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel("LINEAR MEASUREMENT"),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _measurementValue.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        TextSpan(
                          text: " $unitType",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.straighten_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Slider(
                value: _measurementValue,
                min: 0.25,
                max: 10.0,
                divisions: 39,
                activeColor: theme.colorScheme.primary,
                inactiveColor: theme.colorScheme.primary.withValues(
                  alpha: 0.15,
                ),
                label: "${_measurementValue.toStringAsFixed(2)} $unitType",
                onChanged: (val) {
                  HapticFeedback.selectionClick();

                  setState(() {
                    _measurementValue = val;
                    _updateProfit();
                  });
                },
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "0.25 $unitType",
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    "10 $unitType",
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputGrid(ThemeData theme) => Row(
    children: [
      Expanded(
        child: _buildRefinedField(
          theme,
          label: "QTY",
          controller: _qtyController,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: _buildRefinedField(
          theme,
          label: "COLLECTIVE BILLING (PKR)",
          controller: _priceController,
        ),
      ),
    ],
  );

  Widget _buildRefinedField(
    ThemeData theme, {
    required String label,
    required TextEditingController controller,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
      borderRadius: BorderRadius.circular(16),
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
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (_) => _updateProfit(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          decoration: const InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
          ),
        ),
      ],
    ),
  );

  Widget _buildProfitInsight(ThemeData theme) {
    final isHealthy = _currentProfit >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
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
          const Divider(height: 24),
          Row(
            children: [
              _statBlock(
                "YOUR COST",
                "Rs. ${_totalCost.toStringAsFixed(0)}",
                theme.colorScheme.onSurface,
              ),
              _statBlock(
                isHealthy ? "NET PROFIT" : "NET LOSS",
                "Rs. ${_currentProfit.toStringAsFixed(0)}",
                isHealthy ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBlock(String label, String value, Color color) => Expanded(
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

  Widget _buildBulkToggle(ThemeData theme) => SwitchListTile.adaptive(
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

  Widget _buildConfirmButton(ThemeData theme) => Container(
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
        onPressed: _selectedProducts.isEmpty ? null : _submit,
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

  Widget _buildSectionLabel(String label) => Padding(
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
  void didUpdateWidget(covariant _ProductDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// 🔥 FULL RESET WHEN CATEGORY CHANGES
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final products = [...widget.products];

    products.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );

    return DropdownButtonFormField<ProductModel>(
      isExpanded: true,
      value: null,
      hint: const Text("Tap to add item...", style: TextStyle(fontSize: 13)),
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
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
