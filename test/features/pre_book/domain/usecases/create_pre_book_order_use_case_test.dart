import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/pre_book/pre_book.dart';

void main() {
  group('CreatePreBookOrderUseCase', () {
    test('creates a pre-book order inside the commercial window', () {
      final useCase = CreatePreBookOrderUseCase();
      final result = useCase(
        baseDraft: _order(),
        program: _program(),
        items: const <PreBookOrderItemInput>[
          PreBookOrderItemInput(
            id: 'item-1',
            variantId: 'variant-1',
            productId: 'product-1',
            quantity: 6,
            unitPrice: 120,
            deliveryWindowId: 'jan',
          ),
        ],
        availabilityByVariantId: <String, PreBookVariantAvailability>{
          'variant-1': _availability(quantity: 20),
        },
        profile: PreBookAudienceProfile.seller,
        customerId: 'customer-1',
        now: DateTime.utc(2026, 9, 15),
      );

      expect(result.draft.isPreBookOrder, isTrue);
      expect(result.draft.order.collectionId, 'col-1');
      expect(
        result.draft.lines.single.promisedDeliveryDate,
        DateTime.utc(2027, 1, 10),
      );
      expect(result.requiresApproval, isFalse);
    });

    test('blocks pre-book creation outside the commercial window', () {
      final useCase = CreatePreBookOrderUseCase();

      expect(
        () => useCase(
          baseDraft: _order(),
          program: _program(),
          items: const <PreBookOrderItemInput>[
            PreBookOrderItemInput(
              id: 'item-1',
              variantId: 'variant-1',
              productId: 'product-1',
              quantity: 6,
              unitPrice: 120,
              deliveryWindowId: 'jan',
            ),
          ],
          availabilityByVariantId: <String, PreBookVariantAvailability>{
            'variant-1': _availability(quantity: 20),
          },
          profile: PreBookAudienceProfile.seller,
          customerId: 'customer-1',
          now: DateTime.utc(2026, 12, 1),
        ),
        throwsA(isA<PreBookOrderValidationException>()),
      );
    });
  });
}

PreBookProgram _program() {
  return PreBookProgram(
    id: 'program-1',
    organizationId: 'org-1',
    companyId: 'company-1',
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
      customerIds: <String>{'customer-1'},
    ),
    targetPieces: 100,
    cancellationRules: 'Cancelamento ate fechamento da janela comercial.',
    pricingPolicy: const PreBookPricingPolicy(
      type: PreBookPricingPolicyType.launchPrice,
      priceListId: 'price-list-1',
    ),
    commitmentRules: const PreBookCommitmentRules(),
    updatedAt: DateTime.utc(2026, 9, 1),
  );
}

PreBookVariantAvailability _availability({required int quantity}) {
  return PreBookVariantAvailability(
    variantId: 'variant-1',
    productId: 'product-1',
    deliveryWindowId: 'jan',
    status: PreBookAvailabilityStatus.forecast,
    futureQuantity: quantity,
    expectedDate: DateTime.utc(2027, 1, 10),
  );
}

Order _order() {
  final now = DateTime.utc(2026, 9, 11);
  return Order(
    id: 'order-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'rep-1',
    deliveryAddress: const OrderAddress(
      street: 'Rua A',
      city: 'Sao Paulo',
      state: 'SP',
      zipCode: '01001000',
    ),
    billingAddress: const OrderAddress(
      street: 'Rua A',
      city: 'Sao Paulo',
      state: 'SP',
      zipCode: '01001000',
    ),
    priceListId: 'price-list-1',
    paymentTermId: 'term-1',
    status: OrderStatus.draft,
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: OrderSyncStatus.pending,
  );
}
