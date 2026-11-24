import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_munshi/cache/tables/product_table.dart';
import 'package:digital_munshi/cache/tables/sale_table.dart';
import 'package:digital_munshi/helpers/number_input.dart';
import 'package:digital_munshi/helpers/stock_ledger.dart';
import 'package:digital_munshi/models/product_model.dart';
import 'package:digital_munshi/providers/business_provider/business_provider.dart';
import 'package:digital_munshi/providers/product_provider/product_provider.dart';
import 'package:uuid/uuid.dart';

class AddUpdateProductView extends ConsumerStatefulWidget {
  final String businessId;
  final ProductModel? product;

  const AddUpdateProductView({
    super.key,
    required this.businessId,
    this.product,
  });

  @override
  ConsumerState<AddUpdateProductView> createState() =>
      _AddUpdateProductViewState();
}

class _AddUpdateProductViewState extends ConsumerState<AddUpdateProductView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _retailController;
  late TextEditingController _msrpController;
  late TextEditingController _stockController;

  bool _isTheya = false;
  String _classification = "Fixed";
  String _unitType = "Piece";

  /// Stock on hand when the form was filled in. Saving with a different
  /// figure records the difference as a restock / correction.
  double _shownStock = 0;
  String _shownStockText = "";

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product?.title);
    _retailController = TextEditingController(
      text: widget.product?.retailPrice != null
          ? widget.product!.retailPrice.toStringAsFixed(0)
          : "",
    );
    _msrpController = TextEditingController(
      text: widget.product?.msrpPrice != null
          ? widget.product!.msrpPrice.toStringAsFixed(0)
          : "",
    );
    _stockController = TextEditingController();
    final product = widget.product;
    if (product != null) {
      // Pending sales are added in _loadAvailableStock; this is a first guess.
      _setShownStock(product.currentStock + product.pendingStockDelta);
      _loadAvailableStock(product.id);
    }

    if (widget.product != null) {
      _isTheya = widget.product!.isTheya;
      _unitType = widget.product!.unitType;
      final oldClass = widget.product!.classification;
      if (oldClass == "Matching" || oldClass == "Fancy") {
        _classification = "Matching";
      } else if (oldClass == "Open" ||
          _unitType == "Meter" ||
          _unitType == "Gazz") {
        _classification = "Open";
      } else {
        _classification = "Fixed";
      }
    }
  }

  void _setShownStock(double value) {
    _shownStock = value;
    _shownStockText = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    _stockController.text = _shownStockText;
  }

  /// Shows stock on hand including sales not uploaded yet.
  Future<void> _loadAvailableStock(String productId) async {
    final row = await ProductTable.getById(productId);
    if (row == null) return;
    final pending = pendingStockUse(
      await SaleTable.getPendingRows(row.businessId),
    );
    if (!mounted) return;
    // Don't overwrite a figure the user has already started typing.
    if (_stockController.text != _shownStockText) return;
    setState(() => _setShownStock(availableStock(row, pending)));
  }

  String? _validateTitle(String? value, List<ProductModel> allProducts) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return "Required";
    final duplicate = allProducts.any(
      (p) =>
          p.id != widget.product?.id &&
          p.isTheya == _isTheya &&
          p.title.trim().toLowerCase() == title.toLowerCase(),
    );
    return duplicate
        ? "A ${_isTheya ? 'Theya' : 'Inside'} product with this name exists"
        : null;
  }

  String? _validateAmount(String? value) {
    final amount = parseAmount(value ?? '');
    if (amount == null) return "Enter a number";
    if (amount < 0) return "Can't be negative";
    return null;
  }

  String? _validateSalePrice(String? value) {
    final error = _validateAmount(value);
    if (error != null) return error;
    final cost = parseAmount(_retailController.text);
    final price = parseAmount(value ?? '')!;
    if (cost != null && price < cost) return "Below cost";
    return null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _retailController.dispose();
    _msrpController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final tracksStock = _classification != "Matching";
    final enteredStock = tracksStock
        ? (parseAmount(_stockController.text) ?? 0.0)
        : 0.0;
    final existing = widget.product;

    final details = (existing ??
            ProductModel(
              id: const Uuid().v4(),
              businessId: widget.businessId,
              title: '',
              isTheya: _isTheya,
              classification: _classification,
              retailPrice: 0,
              msrpPrice: 0,
              unitType: _unitType,
              currentStock: 0,
              isSynced: false,
              isDeleted: false,
            ))
        .copyWith(
          title: _titleController.text.trim(),
          isTheya: _isTheya,
          classification: _classification,
          retailPrice: parseAmount(_retailController.text),
          msrpPrice: parseAmount(_msrpController.text),
          unitType: _unitType,
        );

    final notifier = ref.read(productProvider(widget.businessId).notifier);
    if (existing == null) {
      notifier.addProduct(details, initialStock: enteredStock);
    } else {
      // Only a figure the user actually changed is a stock adjustment.
      final changed =
          tracksStock && _stockController.text.trim() != _shownStockText;
      notifier.updateProduct(
        details,
        stockDelta: changed ? enteredStock - _shownStock : 0,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allProducts =
        ref.watch(productProvider(widget.businessId)).value ?? [];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          widget.product == null ? "Initialize Item" : "Refine Product",
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (widget.product != null)
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
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            _buildPlacementSelector(theme),
            const SizedBox(height: 32),
            _SectionHeader(
              title: "INVENTORY LOGIC",
              icon: Icons.warehouse_outlined,
            ),
            const SizedBox(height: 16),
            _buildTypeSelectors(),
            if (_classification != "Matching") ...[
              const SizedBox(height: 24),
              _buildPremiumTextField(
                controller: _stockController,
                label: _classification == "Fixed"
                    ? "Available Pieces"
                    : "Available Length",
                hint: _classification == "Fixed" ? "e.g., 6" : "e.g., 40.0",
                icon: Icons.numbers_rounded,
                isNumber: true,
                validator: _validateAmount,
              ),
            ],
            const SizedBox(height: 32),
            _SectionHeader(
              title: "IDENTITY",
              icon: Icons.label_important_outline,
            ),
            const SizedBox(height: 16),

            // 🔥 DISPLAY NAME WITH AUTOCOMPLETE (Duplicate Prevention UX)
            _buildAutocompleteTitleField(theme, allProducts),

            const SizedBox(height: 32),
            _SectionHeader(title: "FINANCIALS", icon: Icons.payments_outlined),
            const SizedBox(height: 16),
            _buildPriceInputs(),
            const SizedBox(height: 48),
            _buildSubmitButton(theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- NEW: Autocomplete Title Field ---
  Widget _buildAutocompleteTitleField(
    ThemeData theme,
    List<ProductModel> products,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Display Name",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        RawAutocomplete<String>(
          textEditingController: _titleController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return products
                .where(
                  (p) => p.title.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                )
                .map((p) => p.title);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: _inputDecoration(
                theme,
                "e.g., Midnight Silk 3-PC",
                Icons.inventory_2_rounded,
              ),
              validator: (v) => _validateTitle(v, products),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: MediaQuery.of(context).size.width - 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return GestureDetector(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 4,
                            left: 8,
                            top: 4,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.history,
                                size: 18,
                                color: Colors.grey,
                              ),

                              const SizedBox(width: 12),

                              Text(
                                option,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Helper for Input Decoration
  InputDecoration _inputDecoration(
    ThemeData theme,
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.grey.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
    );
  }

  // --- UI Building Blocks ---

  Widget _buildPlacementSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _PlacementOption(
            title: "INSIDE",
            isActive: !_isTheya,
            activeColor: theme.colorScheme.primary,
            icon: Icons.chair_rounded,
            onTap: () => setState(() => _isTheya = false),
          ),
          _PlacementOption(
            title: "THEYA",
            isActive: _isTheya,
            activeColor: Colors.amber.shade700,
            icon: Icons.storefront_rounded,
            onTap: () => setState(() => _isTheya = true),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelectors() {
    return Row(
      children: [
        Expanded(
          child: _PremiumDropdown(
            label: "Stock Behavior",
            value: (["Fixed", "Open", "Matching"].contains(_classification))
                ? _classification
                : "Fixed",
            items: const ["Fixed", "Open", "Matching"],
            onChanged: (v) => setState(() => _classification = v!),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _PremiumDropdown(
            label: "Unit",
            value: _unitType,
            items: const ["Piece", "Meter", "Gazz"],
            onChanged: (v) => setState(() => _unitType = v!),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInputs() {
    final currency =
        ref.watch(singleBusinessProvider(widget.businessId)).value?.currency ??
        'PKR';
    return Row(
      children: [
        Expanded(
          child: _buildPremiumTextField(
            controller: _retailController,
            label: "Our Cost",
            hint: "0",
            isNumber: true,
            prefix: currency,
            validator: _validateAmount,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPremiumTextField(
            controller: _msrpController,
            label: "Sale Price",
            hint: "0",
            isNumber: true,
            prefix: currency,
            validator: _validateSalePrice,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Text(
          widget.product == null ? "FINALIZE PRODUCT" : "UPDATE PRODUCT",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    bool isNumber = false,
    String? prefix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: isNumber
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : [],
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, size: 20)
                : (prefix != null
                      ? Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            prefix,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : null),
            filled: true,
            fillColor: Colors.grey.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          validator:
              validator ??
              (v) => v == null || v.trim().isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Remove Product?"),
        content: const Text(
          "This product will be archived and hidden from the catalog.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(productProvider(widget.businessId).notifier)
                  .deleteProduct(widget.product!.id, widget.businessId);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// --- Component Classes ---

class _PlacementOption extends StatelessWidget {
  final String title;
  final bool isActive;
  final Color activeColor;
  final IconData icon;
  final VoidCallback onTap;

  const _PlacementOption({
    required this.title,
    required this.isActive,
    required this.activeColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _PremiumDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Function(String?) onChanged;

  const _PremiumDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: const TextStyle(fontSize: 14)),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
