import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('validateProductCompletenessForPublish', () {
    test('returns no errors when every minimal field is present', () {
      final errors = validateProductCompletenessForPublish(
        name: 'Camisa Essential',
        sku: 'CAMISA-001',
        reference: 'REF-001',
        categoryId: 'category-1',
      );

      expect(errors, isEmpty);
    });

    test('flags a blank name, sku and reference even if non-null', () {
      final errors = validateProductCompletenessForPublish(
        name: '   ',
        sku: '  ',
        reference: '',
        categoryId: 'category-1',
      );

      expect(errors['name'], isNotNull);
      expect(errors['sku'], isNotNull);
      expect(errors['reference'], isNotNull);
      expect(errors, isNot(contains('categoryId')));
    });

    test('flags a missing or blank category', () {
      final missing = validateProductCompletenessForPublish(
        name: 'Camisa Essential',
        sku: 'CAMISA-001',
        reference: 'REF-001',
      );
      final blank = validateProductCompletenessForPublish(
        name: 'Camisa Essential',
        sku: 'CAMISA-001',
        reference: 'REF-001',
        categoryId: '   ',
      );

      expect(missing['categoryId'], isNotNull);
      expect(blank['categoryId'], isNotNull);
    });
  });
}
