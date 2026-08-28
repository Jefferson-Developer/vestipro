import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/inventory/inventory.dart';
import 'package:vestipro/features/products/products.dart';

class _MockVariantAvailabilityRepository extends Mock
    implements VariantAvailabilityRepository {}

class _FakeFutureStockRepository implements FutureStockRepository {
  const _FakeFutureStockRepository(this.entries);

  final List<FutureStockEntry> entries;

  @override
  Future<List<FutureStockEntry>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async {
    return entries
        .where((entry) => productIds.contains(entry.productId))
        .toList(growable: false);
  }

  @override
  Future<List<FutureStockEntry>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async {
    return entries
        .where((entry) => variantIds.contains(entry.variantId))
        .toList(growable: false);
  }
}

void main() {
  group('GetVariantFutureStockSummaryUseCase', () {
    late _MockVariantAvailabilityRepository availabilityRepository;

    setUp(() {
      availabilityRepository = _MockVariantAvailabilityRepository();
    });

    test(
      'combines immediate stock with future entries ordered by date',
      () async {
        when(
          () => availabilityRepository.listByVariantIds(
            organizationId: 'org-1',
            variantIds: const <String>['variant-1'],
          ),
        ).thenAnswer(
          (_) async =>
              const AppSuccess<List<VariantAvailability>>(<VariantAvailability>[
                VariantAvailability(
                  variantId: 'variant-1',
                  productId: 'product-1',
                  status: VariantAvailabilityStatus.readyStock,
                  availableQuantity: 12,
                ),
              ]),
        );

        final useCase = GetVariantFutureStockSummaryUseCase(
          availabilityRepository,
          _FakeFutureStockRepository(<FutureStockEntry>[
            FutureStockEntry(
              variantId: 'variant-1',
              productId: 'product-1',
              quantity: 8,
              expectedDate: DateTime.utc(2026, 9, 10),
              source: FutureStockSource.transfer,
            ),
            FutureStockEntry(
              variantId: 'variant-1',
              productId: 'product-1',
              quantity: 24,
              expectedDate: DateTime.utc(2026, 9, 5),
              source: FutureStockSource.purchaseOrder,
            ),
          ]),
        );

        final result = await useCase(
          organizationId: 'org-1',
          variantIds: const <String>['variant-1'],
        );

        expect(result, hasLength(1));
        expect(result.single.immediateQuantity, 12);
        expect(result.single.totalFutureQuantity, 32);
        expect(result.single.nextExpectedDate, DateTime.utc(2026, 9, 5));
        expect(
          result.single.futureEntries.map((entry) => entry.quantity).toList(),
          <int>[24, 8],
        );
      },
    );
  });
}
