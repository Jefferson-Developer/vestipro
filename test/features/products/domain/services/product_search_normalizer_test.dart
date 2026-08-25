import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/products/products.dart';

import '../../product_factory.dart';

void main() {
  group('ProductSearchNormalizer', () {
    test('normalizes accents, case and punctuation', () {
      expect(
        ProductSearchNormalizer.normalize('  CamisÃO Água-Doce 123  '),
        'camisao agua doce 123',
      );
    });

    test('matches name, SKU, reference, EAN and tags', () {
      final product = buildTestProduct(
        name: 'Vestido Tricô Premium',
        sku: 'VEST-TRICO-01',
        reference: 'REF-INVERNO-26',
        ean: '7891234567895',
        tags: const <String>['Pré-venda', 'Atacado'],
      );

      expect(ProductSearchNormalizer.productMatches(product, 'trico'), isTrue);
      expect(
        ProductSearchNormalizer.productMatches(product, 'vest-trico'),
        isTrue,
      );
      expect(
        ProductSearchNormalizer.productMatches(product, 'inverno 26'),
        isTrue,
      );
      expect(
        ProductSearchNormalizer.productMatches(product, '7891234567895'),
        isTrue,
      );
      expect(
        ProductSearchNormalizer.productMatches(product, 'pre venda'),
        isTrue,
      );
      expect(ProductSearchNormalizer.productMatches(product, 'calca'), isFalse);
    });

    test('builds prefixes for Firestore search fields', () {
      final product = buildTestProduct(
        name: 'Camisa Linho',
        sku: 'CAM-LIN-001',
        reference: 'REF-LINHO',
      );

      final prefixes = ProductSearchNormalizer.prefixesForProduct(product);

      expect(prefixes, containsAll(<String>['c', 'cam', 'camisa l']));
      expect(prefixes, containsAll(<String>['ref', 'linho']));
    });
  });
}
