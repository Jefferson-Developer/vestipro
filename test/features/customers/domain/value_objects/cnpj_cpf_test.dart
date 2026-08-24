import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/customers/customers.dart';

void main() {
  group('CnpjCpf', () {
    test('parses, normalizes and formats a valid CPF', () {
      final document = CnpjCpf.parse('529.982.247-25');

      expect(document.digits, '52998224725');
      expect(document.type, CnpjCpfType.cpf);
      expect(document.isCpf, isTrue);
      expect(document.isCnpj, isFalse);
      expect(document.formatted, '529.982.247-25');
    });

    test('parses, normalizes and formats a valid CNPJ', () {
      final document = CnpjCpf.parse('04.252.011/0001-10');

      expect(document.digits, '04252011000110');
      expect(document.type, CnpjCpfType.cnpj);
      expect(document.isCpf, isFalse);
      expect(document.isCnpj, isTrue);
      expect(document.formatted, '04.252.011/0001-10');
    });

    test('rejects a CPF with incorrect check digits', () {
      expect(
        () => CnpjCpf.parse('529.982.247-24'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects a CNPJ with incorrect check digits', () {
      expect(
        () => CnpjCpf.parse('04.252.011/0001-11'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects documents with an invalid length', () {
      expect(
        () => CnpjCpf.parse('1234567890'),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
      'rejects repeated digits even when the check digit math would pass',
      () {
        expect(
          () => CnpjCpf.parse('000.000.000-00'),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => CnpjCpf.parse('00.000.000/0000-00'),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test('compares by normalized value', () {
      expect(CnpjCpf.parse('52998224725'), CnpjCpf.parse('529.982.247-25'));
    });
  });
}
