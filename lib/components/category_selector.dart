import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final bool isTheya;
  final Function(bool) onChanged;

  const CategorySelector({
    super.key,
    required this.isTheya,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _buildTab(context, "INSIDE", !isTheya, theme.colorScheme.primary),
            const SizedBox(width: 6),
            _buildTab(context, "THEYA", isTheya, Colors.amber.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String label,
    bool active,
    Color color,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(label == "THEYA"),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: active ? Colors.white : color.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
