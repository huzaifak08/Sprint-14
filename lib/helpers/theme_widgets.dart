import 'package:flutter/material.dart';

/// Chip colors from the app theme: selected chips use the primary color
/// (blue in light mode, gold in dark mode) instead of Material's default
/// secondary-container tint.
ChipThemeData themedChips(ThemeData theme) {
  final cs = theme.colorScheme;
  bool sel(Set<WidgetState> s) => s.contains(WidgetState.selected);
  return theme.chipTheme.copyWith(
    color: WidgetStateProperty.resolveWith((s) => sel(s) ? cs.primary : null),
    selectedColor: cs.primary,
    checkmarkColor: cs.onPrimary,
    labelStyle: TextStyle(
      color: WidgetStateColor.resolveWith(
        (s) => sel(s) ? cs.onPrimary : cs.onSurface,
      ),
    ),
    secondaryLabelStyle: TextStyle(color: cs.onPrimary),
  );
}

/// Segmented buttons styled like the Home toggle (primary when selected).
ButtonStyle themedSegments(ThemeData theme, {bool compact = false}) {
  final cs = theme.colorScheme;
  return SegmentedButton.styleFrom(
    selectedBackgroundColor: cs.primary,
    selectedForegroundColor: cs.onPrimary,
    side: BorderSide(color: cs.primary),
    visualDensity: compact ? VisualDensity.compact : null,
    tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
  );
}

/// Green used for money coming in / being owed, readable in both themes.
Color positiveMoneyColor(ThemeData theme) =>
    theme.brightness == Brightness.light
    ? const Color(0xFF2E9E5B)
    : const Color(0xFF4ADE80);

/// Red used for money going out / owed, readable in both themes.
Color negativeMoneyColor(ThemeData theme) =>
    theme.brightness == Brightness.light
    ? const Color(0xFFE5484D)
    : const Color(0xFFFF6B6B);
