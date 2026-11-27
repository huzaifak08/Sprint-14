/// Pulls Google-style backup codes (8 digits, often shown as "1234 5678")
/// out of OCR text. Order is kept and duplicates are dropped.
///
/// Common OCR letter/digit mix-ups (O→0, I/l→1) are fixed only inside
/// tokens that are mostly digits, so ordinary words are left alone.
List<String> extractBackupCodes(String text) {
  final normalized = text.replaceAllMapped(_digitLikeToken, (m) {
    final token = m[0]!;
    final digits = token.replaceAll(RegExp(r'\D'), '').length;
    if (digits * 2 < token.length) return token;
    return token
        .replaceAll(RegExp('[Oo]'), '0')
        .replaceAll(RegExp('[Il]'), '1');
  });

  return {
    for (final m in _codePattern.allMatches(normalized)) '${m[1]}${m[2]}',
  }.toList();
}

/// Splits typed or pasted codes on whitespace and commas.
List<String> splitBackupCodes(String text) =>
    text.split(RegExp(r'[\s,]+')).where((c) => c.isNotEmpty).toList();

/// Whether [code] has the usual backup-code shape (8 digits).
bool isStandardBackupCode(String code) => _standardCode.hasMatch(code);

final _digitLikeToken = RegExp(r'\b[0-9OoIl]{4,8}\b');
final _codePattern = RegExp(r'(?<!\d)(\d{4})[  -]?(\d{4})(?!\d)');
final _standardCode = RegExp(r'^\d{8}$');
