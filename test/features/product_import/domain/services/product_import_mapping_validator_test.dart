import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/product_import/product_import.dart';

void main() {
  group('validateProductImportMapping', () {
    ProductImportMapping mappingWith(
      Map<ProductImportField, int> columnByField, {
      String sizeGridTemplateId = 'grid-1',
    }) {
      return ProductImportMapping(
        hasHeaderRow: true,
        columnByField: columnByField,
        sizeGridTemplateId: sizeGridTemplateId,
      );
    }

    const requiredColumns = <ProductImportField, int>{
      ProductImportField.sku: 0,
      ProductImportField.reference: 1,
      ProductImportField.name: 2,
      ProductImportField.colorName: 3,
      ProductImportField.sizeLabel: 4,
    };

    test(
      'accepts a mapping with every required field, a size grid and no collisions',
      () {
        expect(validateProductImportMapping(mappingWith(requiredColumns)), isEmpty);
      },
    );

    test('rejects a mapping missing the sku column', () {
      final columns = Map<ProductImportField, int>.of(requiredColumns)
        ..remove(ProductImportField.sku);
      final errors = validateProductImportMapping(mappingWith(columns));
      expect(errors, contains(ProductImportField.sku.code));
    });

    test('rejects a mapping missing the colorName column', () {
      final columns = Map<ProductImportField, int>.of(requiredColumns)
        ..remove(ProductImportField.colorName);
      final errors = validateProductImportMapping(mappingWith(columns));
      expect(errors, contains(ProductImportField.colorName.code));
    });

    test('rejects a mapping missing the sizeLabel column', () {
      final columns = Map<ProductImportField, int>.of(requiredColumns)
        ..remove(ProductImportField.sizeLabel);
      final errors = validateProductImportMapping(mappingWith(columns));
      expect(errors, contains(ProductImportField.sizeLabel.code));
    });

    test('rejects two fields mapped to the very same column', () {
      final columns = Map<ProductImportField, int>.of(requiredColumns);
      columns[ProductImportField.brand] = columns[ProductImportField.sku]!;
      final errors = validateProductImportMapping(mappingWith(columns));
      expect(errors, contains('columnByField'));
    });

    test('rejects a mapping without a sizeGridTemplateId', () {
      final errors = validateProductImportMapping(
        mappingWith(requiredColumns, sizeGridTemplateId: ''),
      );
      expect(errors, contains('sizeGridTemplateId'));
    });
  });

  group('ProductImportField.fromCode', () {
    test('round-trips every value through its own code', () {
      for (final field in ProductImportField.values) {
        expect(ProductImportFieldCode.fromCode(field.code), field);
      }
    });

    test('returns null for an unknown code', () {
      expect(ProductImportFieldCode.fromCode('not-a-real-field'), isNull);
    });
  });
}
