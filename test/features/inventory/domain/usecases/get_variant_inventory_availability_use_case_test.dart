import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/inventory/inventory.dart';

class _MockVariantStockBalanceRepository extends Mock
    implements VariantStockBalanceRepository {}

void main() {
  group('GetVariantInventoryAvailabilityUseCase', () {
    late _MockVariantStockBalanceRepository repository;
    late GetVariantInventoryAvailabilityUseCase useCase;

    setUp(() {
      repository = _MockVariantStockBalanceRepository();
      useCase = GetVariantInventoryAvailabilityUseCase(repository);
    });

    test(
      'returns zero instead of error when a variant has no stock yet',
      () async {
        when(
          () => repository.getAvailability(
            organizationId: 'org-1',
            variantId: 'variant-1',
            warehouseId: null,
          ),
        ).thenAnswer(
          (_) async => const AppSuccess<VariantInventoryAvailability>(
            VariantInventoryAvailability(
              variantId: 'variant-1',
              productId: 'product-1',
              totalSellableQuantity: 0,
              byWarehouse: <VariantStockBalance>[],
            ),
          ),
        );

        final result = await useCase(
          organizationId: 'org-1',
          variantId: 'variant-1',
        );

        expect(result, isA<AppSuccess<VariantInventoryAvailability>>());
        expect(
          (result as AppSuccess<VariantInventoryAvailability>)
              .value
              .totalSellableQuantity,
          0,
        );
      },
    );
  });
}
