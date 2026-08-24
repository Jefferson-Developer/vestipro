import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('Ean', () {
    test('parses a valid EAN-13 and detects its format', () {
      final ean = Ean.parse('4006381333931');

      expect(ean.digits, '4006381333931');
      expect(ean.format, EanFormat.ean13);
      expect(ean.toString(), '4006381333931');
    });

    test('parses a valid EAN-8 and detects its format', () {
      final ean = Ean.parse('40170725');

      expect(ean.digits, '40170725');
      expect(ean.format, EanFormat.ean8);
    });

    test('normalizes non-digit separators before validating', () {
      final ean = Ean.parse('4006381-333931');

      expect(ean.digits, '4006381333931');
    });

    test('rejects an EAN-13 with an incorrect check digit', () {
      expect(
        () => Ean.parse('4006381333930'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects an EAN-8 with an incorrect check digit', () {
      expect(() => Ean.parse('40170726'), throwsA(isA<ValidationException>()));
    });

    test('rejects a length that is neither 8 nor 13 digits', () {
      expect(() => Ean.parse('123456'), throwsA(isA<ValidationException>()));
      expect(
        () => Ean.parse('123456789012345'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('compares by digits', () {
      expect(Ean.parse('4006381333931'), Ean.parse('4006381333931'));
    });
  });
}
