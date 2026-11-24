import 'package:flutter/material.dart';
import 'package:digital_munshi/components/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:digital_munshi/components/category_selector.dart';
import 'package:digital_munshi/helpers/app_data.dart';
import 'package:digital_munshi/helpers/number_input.dart';
import 'package:digital_munshi/models/product_model.dart';
import 'package:digital_munshi/models/sale_model.dart';
import 'package:digital_munshi/providers/business_provider/business_provider.dart';
import 'package:digital_munshi/providers/current_user_provider/current_user_provider.dart';
import 'package:digital_munshi/providers/product_provider/product_provider.dart';
import 'package:digital_munshi/providers/sale_provider/sale_provider.dart';
import 'package:digital_munshi/providers/stock_provider/stock_provider.dart';

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

  /// New sales move stock. Sales recorded before stock tracking existed
  /// stay untracked when edited, so hand-counted stock isn't disturbed.
  bool get _tracksStock => widget.sale?.stockTracked ?? true;

  /// Stock the sale being edited already takes (added back when checking
  /// how much is available for the edited version).
  Map<String, double> get _originalStockUse =>
      widget.sale?.stockEffects ?? const {};

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
    _isInitialized = true;

    final sale = widget.sale!;
    final items = sale.items.isNotEmpty
        ? sale.items
        : _legacyItems(sale, products);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _basketItems.clear();
        _basketItems.addAll(items.map(_SaleBasketItem.fromItem));
        _billingController.text = _fmt(sale.soldAtPrice);
        _recalculate();
      });
    });
  }

  /// Rebuilds lines for a sale recorded before per-item lines existed.
  /// Only totals were stored then, so quantities are a best guess and the
  /// cost of products deleted since is shared out from the stored profit,
  /// keeping the sale's profit unchanged unless the user edits it.
  List<SaleItem> _legacyItems(SaleModel sale, List<ProductModel> products) {
    final byId = {for (final p in products) p.id: p};
    final isMulti = sale.productIds.length > 1;
    final items = <SaleItem>[];
    final missing = <int>[];

    for (var i = 0; i < sale.productIds.length; i++) {
      final id = sale.productIds[i];
      final product = byId[id];
      final title = i < sale.productTitles.length
          ? sale.productTitles[i]
          : (product?.title ?? 'Unknown item');
      final unitType = product?.unitType ?? 'Piece';
      if (product == null) missing.add(items.length);
      items.add(
        SaleItem(
          productId: id,
          title: title,
          unitType: unitType,
          quantity: isMulti ? 1 : sale.quantity,
          measurement: isLinearUnit(unitType) ? sale.measurement : 1,
          unitCost: product?.retailPrice ?? 0,
          unitMsrp: product?.msrpPrice ?? 0,
          tracksStock: false,
        ),
      );
    }

    if (missing.isNotEmpty) {
      final knownCost = items.fold<double>(
        0,
        (sum, item) => sum + item.totalCost,
      );
      final storedCost = sale.soldAtPrice - sale.profit;
      final share = ((storedCost - knownCost) / missing.length).clamp(
        0.0,
        double.infinity,
      );
      for (final index in missing) {
        final item = items[index];
        final units = item.effectiveQuantity == 0 ? 1 : item.effectiveQuantity;
        items[index] = SaleItem(
          productId: item.productId,
          title: item.title,
          unitType: item.unitType,
          quantity: item.quantity,
          measurement: item.measurement,
          unitCost: share / units,
          unitMsrp: share / units,
          tracksStock: false,
        );
      }
    }
    return items;
  }

  void _recalculate() {
    double collectiveMsrp = 0;
    double collectiveCost = 0;

    for (final item in _basketItems) {
      final line = item.toItem();
      collectiveMsrp += line.totalMsrp;
      collectiveCost += line.totalCost;
    }

    final billing = parseAmount(_billingController.text) ?? 0;

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

  /// Stock left for [productId] for this sale: what's on hand plus what
  /// the sale being edited already took.
  double _allowedStock(String productId, Map<String, double> levels) {
    return (levels[productId] ?? 0) + (_originalStockUse[productId] ?? 0);
  }

  /// Basket lines that need more stock than is left.
  List<String> _stockShortfalls(Map<String, double> levels) {
    if (!_tracksStock) return const [];
    final shortfalls = <String>[];
    for (final item in _basketItems) {
      if (!item.tracksStock) continue;
      final needed = item.toItem().effectiveQuantity;
      final allowed = _allowedStock(item.productId, levels);
      if (needed > allowed + 1e-9) {
        shortfalls.add(
          "${item.title}: needs ${_fmt(needed)}, only "
          "${_fmt(allowed < 0 ? 0 : allowed)} left",
        );
      }
    }
    return shortfalls;
  }

  /// Returns an error message, or null when the form can be saved.
  String? _validate() {
    if (_basketItems.isEmpty) return "Add at least one product.";
    for (final item in _basketItems) {
      final qty = parseAmount(item.qtyController.text);
      if (qty == null || qty <= 0) {
        return "Enter a quantity above 0 for ${item.title}.";
      }
      if (item.isLinear) {
        final m = parseAmount(item.measurementController.text);
        if (m == null || m <= 0) {
          return "Enter a measurement above 0 for ${item.title}.";
        }
      }
    }
    final billing = parseAmount(_billingController.text);
    if (billing == null || billing <= 0) {
      return "Enter the total bill (above 0).";
    }
    return null;
  }

  Future<void> _submit(Map<String, double> stockLevels) async {
    final error = _validate();
    if (error != null) {
      AppToast.error(error);
      return;
    }

    final shortfalls = _stockShortfalls(stockLevels);
    if (shortfalls.isNotEmpty && !await _confirmOverStock(shortfalls)) {
      return;
    }
    if (!mounted) return;

    final items = _basketItems.map((e) => e.toItem()).toList();
    final firstLinear = items.where((i) => i.isLinear).firstOrNull;
    final billing = parseAmount(_billingController.text)!;
    final uid = ref.read(currentUserProvider).value?.uid ?? '';

    final sale = SaleModel(
      id: _isEditMode ? widget.sale!.id : AppData.shared.uuid.v4(),
      businessId: widget.businessId,
      productIds: items.map((e) => e.productId).toList(),
      productTitles: items.map((e) => e.title).toList(),
      soldAtPrice: billing,
      profit: billing - items.fold<double>(0, (s, i) => s + i.totalCost),
      // Totals kept for older app versions that don't read `items`.
      quantity: items.fold<double>(0, (s, i) => s + i.quantity),
      measurement: firstLinear?.measurement ?? 1.0,
      dateTime: _selectedDate,
      items: items,
      recordedById: (_isEditMode && widget.sale!.recordedById.isNotEmpty)
          ? widget.sale!.recordedById
          : uid,
      stockTracked: _tracksStock,
      isSynced: false,
      isDeleted: false,
    );

    if (_isEditMode) {
      await ref.read(saleProvider(widget.businessId).notifier).updateSale(sale);
    } else {
      await ref.read(saleProvider(widget.businessId).notifier).recordSale(sale);
    }
    if (!mounted) return;

    if (_saveAndAddAnother && !_isEditMode) {
      _resetForm();

      AppToast.success('Sale recorded');

      return;
    }

    Navigator.pop(context);
  }

  Future<bool> _confirmOverStock(List<String> shortfalls) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Not enough stock"),
        content: Text(
          "${shortfalls.join('\n')}\n\nRecord the sale anyway? Stock will "
          "go below zero until you correct it in the product.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("RECORD ANYWAY"),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String get _currency =>
      ref.watch(singleBusinessProvider(widget.businessId)).value?.currency ??
      'PKR';

  static String _fmt(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final productState = ref.watch(productProvider(widget.businessId));
    final stockLevels =
        ref.watch(stockLevelsProvider(widget.businessId)).value ??
        const <String, double>{};

    productState.whenData((products) => _initializeEditData(products));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildHeader(theme),
      body: productState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (products) {
          final filteredProducts = products
              .where(
                (p) =>
                    p.isTheya == _isTheyaFilter &&
                    p.isAvailableForSale(stockLevels[p.id] ?? p.currentStock),
              )
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
                      selectedIds: _basketItems
                          .map((e) => e.productId)
                          .toSet(),
                      onSelected: (product) {
                        final exists = _basketItems.any(
                          (e) => e.productId == product.id,
                        );

                        if (exists) return;

                        setState(() {
                          _basketItems.add(
                            _SaleBasketItem.fromProduct(product),
                          );

                          if (_basketItems.length == 1) {
                            _billingController.text = product.msrpPrice
                                .toStringAsFixed(0);
                          }

                          _recalculate();
                        });
                      },
                    ),

                    _buildSectionLabel("BASKET"),

                    _buildBasket(theme, stockLevels),

                    _buildSectionLabel("COLLECTIVE BILLING"),

                    _buildBillingField(theme),

                    const SizedBox(height: 28),

                    if (_basketItems.isNotEmpty) _buildProfitCard(theme),

                    if (!_isEditMode) _buildBulkToggle(theme),

                    const SizedBox(height: 40),
                  ],
                ),
              ),

              _buildSubmitButton(theme, stockLevels),
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

  Widget _buildBasket(ThemeData theme, Map<String, double> stockLevels) {
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
        final bool isLinear = item.isLinear;
        final showStock = _tracksStock && item.tracksStock;
        final allowed = _allowedStock(item.productId, stockLevels);
        final short = showStock && item.toItem().effectiveQuantity > allowed;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        if (showStock)
                          Text(
                            "IN STOCK: ${_fmt(allowed < 0 ? 0 : allowed)}"
                            "${isLinear ? ' ${item.unitType}' : ''}",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: short ? Colors.red : Colors.grey,
                            ),
                          ),
                      ],
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
                            "MEASUREMENT (${item.unitType.toUpperCase()})",
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
                          "${item.measurementController.text} ${item.unitType}",
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
                            parseAmount(item.measurementController.text) ?? 1;

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
      label: "TOTAL BILLING ($_currency)",
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
            onChanged: onChanged,
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
                "$_currency ${_totalMSRP.toStringAsFixed(0)}",
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
                "$_currency ${_totalCost.toStringAsFixed(0)}",
                theme.colorScheme.onSurface,
              ),
              _statBlock(
                healthy ? "NET PROFIT" : "NET LOSS",
                "$_currency ${_profit.toStringAsFixed(0)}",
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

  Widget _buildSubmitButton(ThemeData theme, Map<String, double> stockLevels) {
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
          onPressed: _basketItems.isEmpty ? null : () => _submit(stockLevels),
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

/// One editable basket line. Prices are a snapshot: taken from the product
/// when it is added, or from the saved sale when editing.
class _SaleBasketItem {
  final String productId;
  final String title;
  final String unitType;
  final double unitCost;
  final double unitMsrp;
  final bool tracksStock;

  final TextEditingController qtyController;

  final TextEditingController measurementController;

  _SaleBasketItem({
    required this.productId,
    required this.title,
    required this.unitType,
    required this.unitCost,
    required this.unitMsrp,
    required this.tracksStock,
    double quantity = 1,
    double measurement = 1,
  }) : qtyController = TextEditingController(
         text: quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 2),
       ),
       measurementController = TextEditingController(
         text: measurement.toStringAsFixed(2),
       );

  factory _SaleBasketItem.fromProduct(ProductModel product) {
    return _SaleBasketItem(
      productId: product.id,
      title: product.title,
      unitType: product.unitType,
      unitCost: product.retailPrice,
      unitMsrp: product.msrpPrice,
      tracksStock: product.tracksStock,
    );
  }

  factory _SaleBasketItem.fromItem(SaleItem item) {
    return _SaleBasketItem(
      productId: item.productId,
      title: item.title,
      unitType: item.unitType,
      unitCost: item.unitCost,
      unitMsrp: item.unitMsrp,
      tracksStock: item.tracksStock,
      quantity: item.quantity,
      measurement: item.measurement,
    );
  }

  bool get isLinear => isLinearUnit(unitType);

  SaleItem toItem() {
    return SaleItem(
      productId: productId,
      title: title,
      unitType: unitType,
      quantity: parseAmount(qtyController.text) ?? 0,
      measurement: isLinear
          ? (parseAmount(measurementController.text) ?? 0)
          : 1,
      unitCost: unitCost,
      unitMsrp: unitMsrp,
      tracksStock: tracksStock,
    );
  }

  void dispose() {
    qtyController.dispose();
    measurementController.dispose();
  }
}

class _ProductDropdown extends StatefulWidget {
  final List<ProductModel> products;

  final Set<String> selectedIds;

  final Function(ProductModel) onSelected;

  const _ProductDropdown({
    super.key,
    required this.products,
    required this.selectedIds,
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
        final alreadySelected = widget.selectedIds.contains(p.id);

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
