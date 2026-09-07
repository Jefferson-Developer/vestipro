import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';

void main() {
  group('CurrencyFormatter', () {
    test(
      'formats BRL under pt_BR with the correct symbol/decimal separator',
      () {
        final formatted = CurrencyFormatter.format(
          1234.5,
          'BRL',
          locale: 'pt_BR',
        );
        expect(formatted, contains('1.234,50'));
        expect(formatted, contains(r'R$'));
      },
    );

    test(
      'formats USD under en_US with the correct symbol/decimal separator',
      () {
        final formatted = CurrencyFormatter.format(
          1234.5,
          'USD',
          locale: 'en_US',
        );
        expect(formatted, contains('1,234.50'));
        expect(formatted, contains(r'$'));
      },
    );

    test('formats EUR under pt_BR using the euro sign, never a BRL symbol', () {
      final formatted = CurrencyFormatter.format(
        1234.5,
        'EUR',
        locale: 'pt_BR',
      );
      expect(formatted, contains('€'));
      expect(formatted, isNot(contains(r'R$')));
    });

    test(
      'the currency symbol always comes from currencyCode, never from locale '
      '(a pt_BR interface showing a USD Price List still renders US\$)',
      () {
        final formatted = CurrencyFormatter.format(10, 'USD', locale: 'pt_BR');
        expect(formatted, isNot(contains(r'R$')));
      },
    );

    test('formatWithCode always appends the explicit ISO 4217 code — the '
        'visual currency indicator TASK-175 requires, never relying on the '
        'symbol alone (several currencies share the same \$ symbol)', () {
      final formatted = CurrencyFormatter.formatWithCode(
        1234.5,
        'USD',
        locale: 'en_US',
      );
      expect(formatted, endsWith('USD'));
      expect(formatted, contains('1,234.50'));
    });

    test('legacyDefaultCurrency is BRL', () {
      expect(CurrencyFormatter.legacyDefaultCurrency, 'BRL');
    });
  });
}
