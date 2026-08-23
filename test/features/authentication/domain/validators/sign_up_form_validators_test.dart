import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/authentication/domain/validators/sign_up_form_validators.dart';

void main() {
  group('validateSignUpName', () {
    test('rejects null', () {
      expect(validateSignUpName(null), 'Informe seu nome.');
    });

    test('rejects an empty value', () {
      expect(validateSignUpName(''), 'Informe seu nome.');
    });

    test('rejects a value with only whitespace', () {
      expect(validateSignUpName('   '), 'Informe seu nome.');
    });

    test('rejects a single-character name', () {
      expect(validateSignUpName('A'), 'Informe um nome válido.');
    });

    test('accepts a well-formed name', () {
      expect(validateSignUpName('Ana Souza'), isNull);
    });

    test('accepts a well-formed name surrounded by whitespace', () {
      expect(validateSignUpName('  Ana Souza  '), isNull);
    });
  });

  group('validateSignUpEmail', () {
    test('rejects null', () {
      expect(validateSignUpEmail(null), 'Informe seu e-mail.');
    });

    test('rejects an empty value', () {
      expect(validateSignUpEmail(''), 'Informe seu e-mail.');
    });

    test('rejects a malformed e-mail', () {
      expect(validateSignUpEmail('not-an-email'), 'Informe um e-mail válido.');
    });

    test('accepts a well-formed e-mail', () {
      expect(validateSignUpEmail('vendedor@vestipro.com.br'), isNull);
    });
  });

  group('validateSignUpPassword', () {
    test('rejects null', () {
      expect(validateSignUpPassword(null), isNotNull);
    });

    test('rejects an empty value', () {
      expect(validateSignUpPassword(''), 'Informe uma senha.');
    });

    test('rejects a password shorter than 8 characters', () {
      expect(validateSignUpPassword('abc123'), isNotNull);
    });

    test('rejects a password with only letters', () {
      expect(validateSignUpPassword('abcdefgh'), isNotNull);
    });

    test('rejects a password with only digits', () {
      expect(validateSignUpPassword('12345678'), isNotNull);
    });

    test('accepts a password with at least 8 chars, letters and digits', () {
      expect(validateSignUpPassword('senha123'), isNull);
    });
  });

  group('validateSignUpPasswordConfirmation', () {
    test('rejects an empty confirmation', () {
      expect(
        validateSignUpPasswordConfirmation('senha123', ''),
        'Confirme sua senha.',
      );
    });

    test('rejects a null confirmation', () {
      expect(
        validateSignUpPasswordConfirmation('senha123', null),
        'Confirme sua senha.',
      );
    });

    test('rejects a confirmation that does not match the password', () {
      expect(
        validateSignUpPasswordConfirmation('senha123', 'outraSenha123'),
        'As senhas não coincidem.',
      );
    });

    test('accepts a confirmation equal to the password', () {
      expect(
        validateSignUpPasswordConfirmation('senha123', 'senha123'),
        isNull,
      );
    });
  });
}
