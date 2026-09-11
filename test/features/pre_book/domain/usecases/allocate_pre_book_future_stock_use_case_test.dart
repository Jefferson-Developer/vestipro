import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/inventory/domain/entities/future_stock_entry.dart';
import 'package:vestipro/features/inventory/domain/value_objects/future_stock_source.dart';
import 'package:vestipro/features/pre_book/pre_book.dart';

void main() {
  group('AllocatePreBookFutureStockUseCase', () {
    test(
      'allocates only future stock and reports ready-stock-only variants',
      () {
        final useCase = AllocatePreBookFutureStockUseCase();
        final result = useCase(
          program: _program(),
          futureStock: <FutureStockEntry>[
            FutureStockEntry(
              variantId: 'future-1',
              productId: 'product-1',
              quantity: 12,
              expectedDate: DateTime.utc(2027, 1, 12),
              source: FutureStockSource.productionOrder,
            ),
          ],
          requests: const <PreBookFutureStockAllocationRequest>[
            PreBookFutureStockAllocationRequest(
              variantId: 'future-1',
              quantity: 8,
              deliveryWindowId: 'jan',
            ),
            PreBookFutureStockAllocationRequest(
              variantId: 'ready-1',
              quantity: 4,
              deliveryWindowId: 'jan',
            ),
          ],
          readyStockVariantIds: const <String>{'ready-1'},
        );

        expect(
          result.availability['future-1']!.status,
          PreBookAvailabilityStatus.allocated,
        );
        expect(
          result.availability['ready-1']!.status,
          PreBookAvailabilityStatus.unavailable,
        );
        expect(result.blockedReadyStockVariantIds, contains('ready-1'));
      },
    );
  });
}

PreBookProgram _program() {
  return PreBookProgram(
    id: 'program-1',
    organizationId: 'org-1',
    collectionId: 'col-1',
    name: 'Pre-book Verao 2027',
    salesWindowStart: DateTime.utc(2026, 9, 1),
    salesWindowEnd: DateTime.utc(2026, 10, 31),
    deliveryWindows: <PreBookDeliveryWindow>[
      PreBookDeliveryWindow(
        id: 'jan',
        label: 'Janeiro',
        startsAt: DateTime.utc(2027, 1, 1),
        endsAt: DateTime.utc(2027, 1, 31),
      ),
    ],
    status: PreBookProgramStatus.open,
    audiencePolicy: const PreBookAudiencePolicy(
      profiles: <PreBookAudienceProfile>{PreBookAudienceProfile.seller},
    ),
    targetPieces: 100,
    cancellationRules: 'Sem cancelamento apos aprovacao.',
    pricingPolicy: const PreBookPricingPolicy(
      type: PreBookPricingPolicyType.launchPrice,
    ),
    commitmentRules: const PreBookCommitmentRules(),
    updatedAt: DateTime.utc(2026, 9, 1),
  );
}
