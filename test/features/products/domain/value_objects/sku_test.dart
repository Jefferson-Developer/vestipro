import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('Sku', () {
    test('normalizes to upper case after trimming', () {
      final sku = Sku.parse('  camisa-essential-001  ');

      expect(sku.value, 'CAMISA-ESSENTIAL-001');
      expect(sku.toString(), 'CAMISA-ESSENTIAL-001');
    });

    test('accepts letters, numbers, hyphen and underscore', () {
      expect(Sku.parse('AB').value, 'AB');
      expect(Sku.parse('SKU_001').value, 'SKU_001');
      expect(Sku.parse('SKU-001-A').value, 'SKU-001-A');
    });

    test('rejects an empty SKU', () {
      expect(() => Sku.parse('   '), throwsA(isA<ValidationException>()));
    });

    test('rejects a SKU shorter than 2 characters', () {
      expect(() => Sku.parse('A'), throwsA(isA<ValidationException>()));
    });

    test('rejects a SKU longer than 40 characters', () {
      expect(() => Sku.parse('A' * 41), throwsA(isA<ValidationException>()));
    });

    test('rejects a SKU with an invalid separator placement', () {
      expect(() => Sku.parse('-SKU'), throwsA(isA<ValidationException>()));
      expect(() => Sku.parse('SKU-'), throwsA(isA<ValidationException>()));
      expect(() => Sku.parse('SKU--001'), throwsA(isA<ValidationException>()));
    });

    test('rejects characters outside the allowed alphabet', () {
      expect(() => Sku.parse('SKU 001'), throwsA(isA<ValidationException>()));
      expect(() => Sku.parse('SKU#001'), throwsA(isA<ValidationException>()));
    });

    test('compares by normalized value', () {
      expect(Sku.parse('sku-001'), Sku.parse('SKU-001'));
    });
  });
}
