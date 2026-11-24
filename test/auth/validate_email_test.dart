import 'package:flutter_test/flutter_test.dart';
import 'package:digital_munshi/views/auth/widgets/auth_widgets.dart';

void main() {
  test('accepts normal addresses (with surrounding spaces)', () {
    expect(validateEmail('ali@mail.com'), isNull);
    expect(validateEmail('  first.last+tag@sub.domain.pk '), isNull);
  });

  test('rejects broken addresses', () {
    for (final bad in [
      '',
      '   ',
      'ali',
      'ali@',
      '@mail.com',
      'ali@mail',
      'a li@mail.com',
      'ali@mail.c',
    ]) {
      expect(validateEmail(bad), isNotNull, reason: bad);
    }
  });
}
