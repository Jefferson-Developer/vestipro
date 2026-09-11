import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/pre_book/pre_book.dart';

void main() {
  group('EvaluatePreBookRevisionUseCase', () {
    test(
      'requires approval when quantity or delivery window changes after approval',
      () {
        final useCase = EvaluatePreBookRevisionUseCase();
        final original = PreBookOrderDraft(
          programId: 'program-1',
          order: _order(status: OrderStatus.approved),
          lines: <PreBookOrderLine>[
            _line(quantity: 4, deliveryWindowId: 'jan'),
          ],
        );
        final revised = PreBookOrderDraft(
          programId: 'program-1',
          order: _order(status: OrderStatus.approved),
          lines: <PreBookOrderLine>[
            _line(quantity: 6, deliveryWindowId: 'feb'),
          ],
        );

        final decision = useCase(
          program: _program(),
          original: original,
          revised: revised,
        );

        expect(decision.requiresApproval, isTrue);
        expect(
          decision.reasons,
          contains('Quantidade alterada apos aprovacao.'),
        );
        expect(
          decision.reasons,
          contains('Data ou janela de entrega alterada apos aprovacao.'),
        );
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
    deliveryWindows: const <PreBookDeliveryWindow>[],
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

PreBookOrderLine _line({
  required int quantity,
  required String deliveryWindowId,
}) {
  return PreBookOrderLine(
    item: OrderItem(
      id: 'item-1',
      variantId: 'variant-1',
      productId: 'product-1',
      quantity: quantity,
      unitPrice: 100,
      subtotal: quantity * 100,
    ),
    deliveryWindowId: deliveryWindowId,
    promisedDeliveryDate: DateTime.utc(
      2027,
      deliveryWindowId == 'jan' ? 1 : 2,
      10,
    ),
    availabilityStatus: PreBookAvailabilityStatus.allocated,
  );
}

Order _order({required OrderStatus status}) {
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
    collectionId: 'col-1',
    orderType: preBookOrderType,
    status: status,
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: OrderSyncStatus.pending,
  );
}
