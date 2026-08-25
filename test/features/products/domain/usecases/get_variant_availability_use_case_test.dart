import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/repositories/product_variant_availability_repository.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_product_variant_repository.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('GetVariantAvailabilityUseCase', () {
    late SharedPreferencesProductVariantRepository variantRepository;
    late GetVariantAvailabilityUseCase useCase;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      variantRepository = const SharedPreferencesProductVariantRepository();
      useCase = GetVariantAvailabilityUseCase(
        ProductVariantAvailabilityRepository(variantRepository),
      );
    });

    Future<void> seed(List<ProductVariant> variants) async {
      for (final variant in variants) {
        await variantRepository.create(variant: variant);
      }
    }

    test(
      'loads ready, future and unavailable from manual variant fields',
      () async {
        await seed(<ProductVariant>[
          _variant(id: 'variant-ready'),
          _variant(
            id: 'variant-future',
            sizeId: 'size-m',
            sku: 'CAMISA-001-PRETO-M',
            manualAvailabilityStatus: VariantAvailabilityStatus.futureStock,
            manualAvailableQuantity: 6,
            manualFutureAvailableAt: DateTime.utc(2026, 9, 15),
          ),
          _variant(
            id: 'variant-unavailable',
            sizeId: 'size-g',
            sku: 'CAMISA-001-PRETO-G',
            manualAvailabilityStatus: VariantAvailabilityStatus.unavailable,
          ),
        ]);

        final result = await useCase(
          organizationId: 'org-1',
          variantIds: const <String>[
            'variant-ready',
            'variant-future',
            'variant-unavailable',
          ],
        );

        final snapshot =
            (result as AppSuccess<VariantAvailabilitySnapshot>).value;
        expect(
          snapshot.forVariant('variant-ready')!.status,
          VariantAvailabilityStatus.readyStock,
        );
        expect(
          snapshot.forVariant('variant-future')!.status,
          VariantAvailabilityStatus.futureStock,
        );
        expect(
          snapshot.forVariant('variant-future')!.futureAvailableAt,
          DateTime.utc(2026, 9, 15),
        );
        expect(
          snapshot.forVariant('variant-unavailable')!.acceptsQuantity,
          isFalse,
        );
      },
    );

    test(
      'falls back safely to ready stock when manual data is absent',
      () async {
        await seed(<ProductVariant>[_variant(id: 'variant-ready')]);

        final result = await useCase(
          organizationId: 'org-1',
          variantIds: const <String>['variant-ready'],
        );

        final availability = (result as AppSuccess<VariantAvailabilitySnapshot>)
            .value
            .forVariant('variant-ready')!;
        expect(availability.status, VariantAvailabilityStatus.readyStock);
        expect(availability.availableQuantity, isNull);
      },
    );

    test(
      'returns product summary without exposing inventory source details',
      () async {
        await seed(<ProductVariant>[
          _variant(
            id: 'variant-future',
            manualAvailabilityStatus: VariantAvailabilityStatus.futureStock,
            manualFutureAvailableAt: DateTime.utc(2026, 9, 15),
          ),
        ]);

        final result = await useCase(
          organizationId: 'org-1',
          productIds: const <String>['product-1'],
        );

        final snapshot =
            (result as AppSuccess<VariantAvailabilitySnapshot>).value;
        expect(
          snapshot.primaryForProduct('product-1')!.status,
          VariantAvailabilityStatus.futureStock,
        );
        expect(
          snapshot.primaryForProduct('product-1')!.futureAvailableAt,
          DateTime.utc(2026, 9, 15),
        );
      },
    );

    test('keeps TASK-090 replaceable behind the repository contract', () async {
      final inventoryBacked = GetVariantAvailabilityUseCase(
        const _InventoryBackedAvailabilityRepository(),
      );

      final result = await inventoryBacked(
        organizationId: 'org-1',
        variantIds: const <String>['variant-task-090'],
      );

      final availability = (result as AppSuccess<VariantAvailabilitySnapshot>)
          .value
          .forVariant('variant-task-090')!;
      expect(availability.status, VariantAvailabilityStatus.futureStock);
      expect(availability.futureAvailableAt, DateTime.utc(2026, 10, 1));
    });
  });
}

final class _InventoryBackedAvailabilityRepository
    implements VariantAvailabilityRepository {
  const _InventoryBackedAvailabilityRepository();

  @override
  Future<AppResult<List<VariantAvailability>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async {
    return const AppSuccess<List<VariantAvailability>>(<VariantAvailability>[]);
  }

  @override
  Future<AppResult<List<VariantAvailability>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async {
    return AppSuccess<List<VariantAvailability>>(
      variantIds
          .map(
            (variantId) => VariantAvailability(
              variantId: variantId,
              productId: 'product-task-090',
              status: VariantAvailabilityStatus.futureStock,
              futureAvailableAt: DateTime.utc(2026, 10, 1),
            ),
          )
          .toList(growable: false),
    );
  }
}

ProductVariant _variant({
  required String id,
  String sizeId = 'size-p',
  String sku = 'CAMISA-001-PRETO-P',
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
    sizeId: sizeId,
    sku: Sku.parse(sku),
    manualAvailabilityStatus: manualAvailabilityStatus,
    manualAvailableQuantity: manualAvailableQuantity,
    manualFutureAvailableAt: manualFutureAvailableAt,
    status: ProductVariantStatus.active,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}
