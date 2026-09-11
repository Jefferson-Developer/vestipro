import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/barcode_scanner/barcode_scanner.dart';

void main() {
  group('ScannedCodeClassifier', () {
    test('classifies a valid EAN-13 barcode', () {
      final code = ScannedCodeClassifier.classify('7891234567895');
      expect(code.format, ScannedCodeFormat.ean13);
      expect(ScannedCodeClassifier.comparableValue(code), '7891234567895');
    });

    test('classifies a valid EAN-8 barcode', () {
      final code = ScannedCodeClassifier.classify('40170725');
      expect(code.format, ScannedCodeFormat.ean8);
    });

    test('classifies a vestipro internal QR payload', () {
      final code = ScannedCodeClassifier.classify(
        'vestipro:v1:variant:org-1:variant-1',
      );
      expect(code.format, ScannedCodeFormat.internalQr);
    });

    test('falls back to sku for a non-EAN alphanumeric code', () {
      final code = ScannedCodeClassifier.classify('cam-bas-001');
      expect(code.format, ScannedCodeFormat.sku);
      expect(ScannedCodeClassifier.comparableValue(code), 'CAM-BAS-001');
    });

    test('classifies a blank code as unknown', () {
      final code = ScannedCodeClassifier.classify('   ');
      expect(code.format, ScannedCodeFormat.unknown);
    });

    test('an EAN with an invalid check digit falls back to sku', () {
      final code = ScannedCodeClassifier.classify('7891234567896');
      expect(code.format, ScannedCodeFormat.sku);
    });
  });
}
