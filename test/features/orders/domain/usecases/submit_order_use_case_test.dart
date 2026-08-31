import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('SubmitOrderUseCase', () {
    test(
      'submits using Order.id as the idempotency key and logs orderSubmitted '
      'on success',
      () async {
        final repository = _FakeOrderSubmissionRepository(
          AppSuccess<OrderSubmissionResult>(_result()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = SubmitOrderUseCase(repository, analytics);

        final result = await useCase(order: _order());

        expect(result, isA<AppSuccess<OrderSubmissionResult>>());
        expect(
          (result as AppSuccess<OrderSubmissionResult>).value.orderNumber,
          '000001',
        );
        expect(repository.lastIdempotencyKey, 'order-1');
        expect(
          analytics.loggedEvents.any(
            (event) => event.name == AnalyticsEvents.orderSubmitted,
          ),
          isTrue,
        );
      },
    );

    test(
      'fails without calling the repository when the order has no items',
      () async {
        final repository = _FakeOrderSubmissionRepository(
          AppSuccess<OrderSubmissionResult>(_result()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = SubmitOrderUseCase(repository, analytics);

        final result = await useCase(order: _order(items: const <OrderItem>[]));

        expect(result, isA<AppFailure<OrderSubmissionResult>>());
        expect(
          (result as AppFailure<OrderSubmissionResult>).failure.code,
          'order_submission_no_items',
        );
        expect(repository.lastIdempotencyKey, isNull);
        expect(analytics.loggedEvents, isEmpty);
      },
    );

    test(
      'propagates a server-side revalidation failure without logging analytics',
      () async {
        final repository = _FakeOrderSubmissionRepository(
          const AppFailure<OrderSubmissionResult>(
            ValidationFailure(
              'Este cliente está inativo.',
              code: 'failed-precondition',
            ),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = SubmitOrderUseCase(repository, analytics);

        final result = await useCase(order: _order());

        expect(result, isA<AppFailure<OrderSubmissionResult>>());
        expect(analytics.loggedEvents, isEmpty);
      },
    );

    test(
      'resubmitting the exact same order reuses the exact same idempotency key',
      () async {
        final repository = _FakeOrderSubmissionRepository(
          AppSuccess<OrderSubmissionResult>(_result()),
        );
        final useCase = SubmitOrderUseCase(repository, FakeAnalyticsService());

        await useCase(order: _order());
        final firstKey = repository.lastIdempotencyKey;
        await useCase(order: _order());
        final secondKey = repository.lastIdempotencyKey;

        expect(secondKey, firstKey);
      },
    );
  });
}

Order _order({List<OrderItem>? items}) {
  final now = DateTime.utc(2026, 6, 1);
  return Order(
    id: 'order-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'rep-1',
    deliveryAddress: const OrderAddress(
      street: 'Rua das Flores',
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
    ),
    billingAddress: const OrderAddress(
      street: 'Rua das Flores',
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
    ),
    priceListId: 'price-list-1',
    paymentTermId: 'term-1',
    items:
        items ??
        <OrderItem>[
          OrderItem(
            id: 'item-1',
            variantId: 'variant-1',
            productId: 'product-1',
            quantity: 2,
            unitPrice: 100,
            subtotal: 200,
          ),
        ],
    status: OrderStatus.pendingSync,
    statusHistory: <OrderStatusHistoryEntry>[
      OrderStatusHistoryEntry(
        newStatus: OrderStatus.draft,
        changedAt: now,
        actorId: 'rep-1',
      ),
    ],
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: OrderSyncStatus.pending,
  );
}

OrderSubmissionResult _result() {
  return OrderSubmissionResult(
    orderId: 'order-1',
    orderNumber: '000001',
    status: OrderStatus.submitted,
    discountAmount: 0,
    surchargeAmount: 0,
    shippingAmount: 0,
    total: 200,
    submittedAt: DateTime.utc(2026, 6, 1, 12),
  );
}

final class _FakeOrderSubmissionRepository
    implements OrderSubmissionRepository {
  _FakeOrderSubmissionRepository(this._result);

  final AppResult<OrderSubmissionResult> _result;
  String? lastIdempotencyKey;

  @override
  Future<AppResult<OrderSubmissionResult>> submit({
    required Order order,
    required String idempotencyKey,
  }) async {
    lastIdempotencyKey = idempotencyKey;
    return _result;
  }
}
