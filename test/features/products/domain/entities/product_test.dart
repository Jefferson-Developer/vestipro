import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('Product', () {
    final createdAt = DateTime.utc(2026, 1, 1);

    Product buildProduct({List<String> tags = const <String>[]}) {
      return Product(
        id: 'product-1',
        organizationId: 'org-1',
        sku: Sku.parse('CAMISA-001'),
        reference: 'REF-001',
        name: 'Camisa Essential',
        status: ProductStatus.draft,
        tags: tags,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: createdAt,
        updatedBy: 'user-1',
        version: 1,
        syncStatus: ProductSyncStatus.pending,
      );
    }

    test('is equal by value for identical fields', () {
      expect(buildProduct(), buildProduct());
      expect(buildProduct().hashCode, buildProduct().hashCode);
    });

    test('is not equal when a scalar field differs', () {
      expect(
        buildProduct(),
        isNot(buildProduct().copyWith(name: 'Camisa Essential Slim')),
      );
    });

    test('is not equal when the tags list differs', () {
      expect(
        buildProduct(tags: const <String>['lancamento']),
        isNot(buildProduct(tags: const <String>['promocao'])),
      );
      expect(
        buildProduct(tags: const <String>['lancamento']),
        buildProduct(tags: const <String>['lancamento']),
      );
    });

    test('has no EAN by default, per the color/variant business rule', () {
      expect(buildProduct().ean, isNull);
    });

    test('accepts a custom field value linked to a definition', () {
      final withCustomField = buildProduct().copyWith(
        customFieldValues: const <ProductCustomFieldValue>[
          ProductCustomFieldValue(
            fieldDefinitionId: 'field-1',
            value: 'algodao-organico',
          ),
        ],
      );

      expect(
        withCustomField.customFieldValues.single.fieldDefinitionId,
        'field-1',
      );
      expect(
        withCustomField.customFieldValues.single.value,
        'algodao-organico',
      );
    });
  });

  group('ProductCustomFieldDefinition', () {
    test('is equal by value for identical fields', () {
      const first = ProductCustomFieldDefinition(
        id: 'field-1',
        organizationId: 'org-1',
        key: 'composicao_extra',
        label: 'Composicao extra',
        type: ProductCustomFieldType.list,
        isRequired: false,
        options: <String>['algodao', 'poliester'],
      );
      const second = ProductCustomFieldDefinition(
        id: 'field-1',
        organizationId: 'org-1',
        key: 'composicao_extra',
        label: 'Composicao extra',
        type: ProductCustomFieldType.list,
        isRequired: false,
        options: <String>['algodao', 'poliester'],
      );

      expect(first, second);
    });
  });
}
