import 'package:flutter/material.dart';
import 'package:sprint_14/views/business_views/add_update_sale_view.dart';
import 'package:sprint_14/views/business_views/manage_products_view.dart';

class QuickActionHeader extends StatelessWidget {
  final String businessId;
  const QuickActionHeader({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // 1. ADD SALE BUTTON (Primary Accent)
        _buildActionButton(
          theme,
          label: "RECORD SALE",
          icon: Icons.add_shopping_cart_rounded,
          isPrimary: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddUpdateSaleView(businessId: businessId),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 2. MANAGE PRODUCTS BUTTON (Outline Style)
        _buildActionButton(
          theme,
          label: "INVENTORY",
          icon: Icons.inventory_2_outlined,
          isPrimary: false,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManageProductsView(businessId: businessId),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    ThemeData theme, {
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isPrimary
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: isPrimary
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
