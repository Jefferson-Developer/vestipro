import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/authentication/domain/validators/login_form_validators.dart';

void main() {
  group('validateLoginEmail', () {
    test('rejects null', () {
      expect(validateLoginEmail(null), 'Informe seu e-mail.');
    });

    test('rejects an empty value', () {
      expect(validateLoginEmail(''), 'Informe seu e-mail.');
    });

    test('rejects a value with only whitespace', () {
      expect(validateLoginEmail('   '), 'Informe seu e-mail.');
    });

    test('rejects a malformed e-mail', () {
      expect(validateLoginEmail('not-an-email'), 'Informe um e-mail válido.');
    });

    test('rejects an e-mail missing the domain', () {
      expect(validateLoginEmail('user@'), 'Informe um e-mail válido.');
    });

    test('accepts a well-formed e-mail', () {
      expect(validateLoginEmail('vendedor@vestipro.com.br'), isNull);
    });

    test('accepts a well-formed e-mail surrounded by whitespace', () {
      expect(validateLoginEmail('  vendedor@vestipro.com.br  '), isNull);
    });
  });

  group('validateLoginPassword', () {
    test('rejects null', () {
      expect(validateLoginPassword(null), 'Informe sua senha.');
    });

    test('rejects an empty value', () {
      expect(validateLoginPassword(''), 'Informe sua senha.');
    });

    test('accepts any non-empty value, without enforcing complexity here', () {
      expect(validateLoginPassword('a'), isNull);
    });
  });
}
