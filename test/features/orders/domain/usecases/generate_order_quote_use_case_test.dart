import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';

class _MockOrderQuoteRepository extends Mock implements OrderQuoteRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(_order(items: const <OrderItem>[]));
    registerFallbackValue(const Duration(days: 7));
  });

  group('GenerateOrderQuoteUseCase', () {
    test('blocks quote generation when the draft has no items', () async {
      final repository = _MockOrderQuoteRepository();
      final useCase = GenerateOrderQuoteUseCase(
        repository,
        FakeAnalyticsService(),
      );

      final result = await useCase(order: _order(items: const <OrderItem>[]));

      expect(result, isA<AppFailure<Quote>>());
      final failure = (result as AppFailure<Quote>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(failure.code, 'quote_no_items');
      verifyNever(
        () => repository.generate(
          order: any(named: 'order'),
          validity: any(named: 'validity'),
        ),
      );
    });

    test('generates a quote with the default seven-day validity', () async {
      final repository = _MockOrderQuoteRepository();
      final useCase = GenerateOrderQuoteUseCase(
        repository,
        FakeAnalyticsService(),
      );
      final order = _order(items: <OrderItem>[_item]);
      final quote = Quote(
        id: 'quote-1',
        organizationId: order.organizationId,
        companyId: order.companyId,
        orderDraftId: order.id,
        customerId: order.customerId,
        sellerId: order.sellerId,
        priceListId: order.priceListId,
        paymentTermId: order.paymentTermId,
        currency: 'BRL',
        subtotal: 100,
        discountAmount: 0,
        surchargeAmount: 0,
        shippingAmount: 0,
        total: 100,
        status: QuoteStatus.sent,
        expiresAt: DateTime.utc(2026, 1, 8),
        createdAt: DateTime.utc(2026, 1),
        itemCount: 1,
      );
      when(
        () => repository.generate(
          order: any(named: 'order'),
          validity: any(named: 'validity'),
        ),
      ).thenAnswer((_) async => AppSuccess<Quote>(quote));

      final result = await useCase(order: order);

      expect(result, isA<AppSuccess<Quote>>());
      verify(
        () => repository.generate(
          order: order,
          validity: const Duration(days: 7),
        ),
      ).called(1);
    });
  });
}

final _item = OrderItem(
  id: 'item-1',
  productId: 'product-1',
  variantId: 'variant-1',
  quantity: 2,
  unitPrice: 50,
  subtotal: 100,
);

Order _order({required List<OrderItem> items}) {
  final now = DateTime.utc(2026, 1);
  return Order(
    id: 'order-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'seller-1',
    deliveryAddress: const OrderAddress(
      street: 'Rua A',
      city: 'Sao Paulo',
      state: 'SP',
      zipCode: '01000000',
    ),
    billingAddress: const OrderAddress(
      street: 'Rua A',
      city: 'Sao Paulo',
      state: 'SP',
      zipCode: '01000000',
    ),
    priceListId: 'price-list-1',
    paymentTermId: 'term-1',
    items: items,
    status: OrderStatus.draft,
    createdAt: now,
    createdBy: 'seller-1',
    updatedAt: now,
    updatedBy: 'seller-1',
    version: 1,
    syncStatus: OrderSyncStatus.pending,
  );
}
