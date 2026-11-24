/// Parses a typed amount, accepting thousands separators and spaces
/// ("12,000", " 1 500.50 "). Returns null for anything that isn't a finite
/// number.
double? parseAmount(String text) {
  final cleaned = text.replaceAll(',', '').replaceAll(' ', '').trim();
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || !value.isFinite) return null;
  return value;
}
