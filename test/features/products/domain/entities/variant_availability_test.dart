import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('VariantAvailability', () {
    test('maps active variant without manual data to ready stock fallback', () {
      final availability = VariantAvailability.fromVariant(
        _variant(id: 'variant-ready'),
      );

      expect(availability.variantId, 'variant-ready');
      expect(availability.status, VariantAvailabilityStatus.readyStock);
      expect(availability.acceptsQuantity, isTrue);
      expect(availability.availableQuantity, isNull);
      expect(availability.futureAvailableAt, isNull);
    });

    test('maps future stock with optional quantity and expected date', () {
      final availability = VariantAvailability.fromVariant(
        _variant(
          id: 'variant-future',
          manualAvailabilityStatus: VariantAvailabilityStatus.futureStock,
          manualAvailableQuantity: 8,
          manualFutureAvailableAt: DateTime.utc(2026, 9, 15),
        ),
      );

      expect(availability.status, VariantAvailabilityStatus.futureStock);
      expect(availability.acceptsQuantity, isTrue);
      expect(availability.availableQuantity, 8);
      expect(availability.futureAvailableAt, DateTime.utc(2026, 9, 15));
      expect(availability.hasFutureDate, isTrue);
    });

    test(
      'inactive variant is always unavailable and keeps visible contract',
      () {
        final availability = VariantAvailability.fromVariant(
          _variant(
            id: 'variant-inactive',
            status: ProductVariantStatus.inactive,
            manualAvailabilityStatus: VariantAvailabilityStatus.readyStock,
            manualAvailableQuantity: 99,
          ),
        );

        expect(availability.status, VariantAvailabilityStatus.unavailable);
        expect(availability.acceptsQuantity, isFalse);
        expect(availability.availableQuantity, isNull);
      },
    );

    test(
      'snapshot chooses ready, then future, then unavailable per product',
      () {
        final snapshot =
            VariantAvailabilitySnapshot.fromList(<VariantAvailability>[
              const VariantAvailability(
                variantId: 'variant-unavailable',
                productId: 'product-1',
                status: VariantAvailabilityStatus.unavailable,
              ),
              const VariantAvailability(
                variantId: 'variant-future',
                productId: 'product-1',
                status: VariantAvailabilityStatus.futureStock,
              ),
              const VariantAvailability(
                variantId: 'variant-ready',
                productId: 'product-1',
                status: VariantAvailabilityStatus.readyStock,
              ),
            ]);

        expect(
          snapshot.primaryForProduct('product-1')!.variantId,
          'variant-ready',
        );
        expect(snapshot.forVariant('variant-future')!.productId, 'product-1');
      },
    );
  });
}

ProductVariant _variant({
  required String id,
  ProductVariantStatus status = ProductVariantStatus.active,
  VariantAvailabilityStatus? manualAvailabilityStatus,
  int? manualAvailableQuantity,
  DateTime? manualFutureAvailableAt,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return ProductVariant(
    id: id,
    organizationId: 'org-1',
    productId: 'product-1',
    colorId: 'color-preto',
    sizeGridTemplateId: 'grid-p-m',
    sizeId: 'size-p',
    sku: Sku.parse('CAMISA-001-PRETO-P'),
    manualAvailabilityStatus: manualAvailabilityStatus,
    manualAvailableQuantity: manualAvailableQuantity,
    manualFutureAvailableAt: manualFutureAvailableAt,
    status: status,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}
