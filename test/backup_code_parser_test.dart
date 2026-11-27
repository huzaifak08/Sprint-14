import 'package:digital_munshi/helpers/backup_code_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractBackupCodes', () {
    test('reads Google-style "1234 5678" codes from a printout', () {
      const ocr = '''
Google
Backup verification codes
Keep these backup codes somewhere safe but accessible.
1. 4821 3907   6. 7064 1258
2. 3519 8842   7. 6290 4713
user@example.com
Generated Nov 27, 2026
''';
      expect(extractBackupCodes(ocr), [
        '48213907',
        '70641258',
        '35198842',
        '62904713',
      ]);
    });

    test('accepts codes without a space and drops duplicates', () {
      expect(extractBackupCodes('48213907\n4821 3907\n1234-5678'), [
        '48213907',
        '12345678',
      ]);
    });

    test('fixes O/I/l misreads inside digit tokens only', () {
      expect(extractBackupCodes('O205 7736  5l46 9083'), [
        '02057736',
        '51469083',
      ]);
      // Ordinary words are untouched, so nothing is invented.
      expect(extractBackupCodes('Hello Google'), isEmpty);
    });

    test('ignores longer numbers and lone 4-digit years', () {
      expect(extractBackupCodes('Phone 03001234567, year 2026'), isEmpty);
    });

    test('does not join halves across lines', () {
      expect(extractBackupCodes('1234\n5678'), isEmpty);
    });
  });

  test('splitBackupCodes splits on whitespace and commas', () {
    expect(splitBackupCodes(' 11112222,\n33334444  55556666 '), [
      '11112222',
      '33334444',
      '55556666',
    ]);
  });

  test('isStandardBackupCode', () {
    expect(isStandardBackupCode('12345678'), isTrue);
    expect(isStandardBackupCode('1234567'), isFalse);
    expect(isStandardBackupCode('1234567O'), isFalse);
  });
}
