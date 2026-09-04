import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/utils/validators.dart';

void main() {
  group('Validators.notEmpty', () {
    test('rejects null, empty and whitespace-only input', () {
      expect(Validators.notEmpty(null), ValidationError.required);
      expect(Validators.notEmpty(''), ValidationError.required);
      expect(Validators.notEmpty('   '), ValidationError.required);
    });

    test('accepts Devanagari text', () {
      expect(Validators.notEmpty('राधे कृष्ण'), isNull);
    });
  });

  group('Validators.email', () {
    test('accepts ordinary addresses', () {
      expect(Validators.email('committee@thakurbari.in'), isNull);
      expect(Validators.email('a.b-c+tag@sub.domain.co.in'), isNull);
    });

    test('trims surrounding whitespace before checking', () {
      expect(Validators.email('  committee@thakurbari.in  '), isNull);
    });

    test('rejects malformed addresses', () {
      for (final invalid in [
        'no-at-sign',
        'missing@domain',
        'two@@at.example',
        'spaces in@example.com',
        '@example.com',
        'trailing@example.com.',
      ]) {
        expect(
          Validators.email(invalid),
          ValidationError.invalidEmail,
          reason: 'expected "$invalid" to be rejected',
        );
      }
    });

    test('reports a missing value as required, not as invalid', () {
      expect(Validators.email(''), ValidationError.required);
    });

    test('rejects an address longer than the column allows', () {
      final long = '${'a' * 190}@example.com';
      expect(Validators.email(long), ValidationError.invalidEmail);
    });
  });

  group('Validators.password', () {
    test('mirrors the server minimum length', () {
      expect(Validators.passwordMinLength, 8);
      expect(Validators.password('1234567'), ValidationError.passwordTooShort);
      expect(Validators.password('12345678'), isNull);
    });

    test('counts leading and trailing spaces as characters', () {
      expect(Validators.password('  a  b  '), isNull);
    });

    test('reports a missing value as required', () {
      expect(Validators.password(null), ValidationError.required);
    });
  });
}
