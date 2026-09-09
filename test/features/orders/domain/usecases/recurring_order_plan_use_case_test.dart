import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('CreateRecurringOrderPlanUseCase', () {
    test('rejects an empty source order', () async {
      final useCase = CreateRecurringOrderPlanUseCase(
        _FakeRecurringOrderPlanRepository(),
      );

      final result = await useCase(
        sourceOrder: _order(items: const <OrderItem>[]),
        frequency: const RecurringOrderFrequency(
          interval: 7,
          unit: RecurringOrderFrequencyUnit.days,
        ),
        nextExecutionAt: DateTime.now().add(const Duration(days: 1)),
        actorId: 'rep-1',
      );

      expect(result, isA<AppFailure<RecurringOrderPlan>>());
      expect(
        (result as AppFailure<RecurringOrderPlan>).failure,
        isA<ValidationFailure>(),
      );
    });

    test('creates a plan from an existing order', () async {
      final repository = _FakeRecurringOrderPlanRepository();
      final useCase = CreateRecurringOrderPlanUseCase(repository);

      final result = await useCase(
        sourceOrder: _order(items: <OrderItem>[_item()]),
        frequency: const RecurringOrderFrequency(
          interval: 2,
          unit: RecurringOrderFrequencyUnit.weeks,
        ),
        nextExecutionAt: DateTime.now().add(const Duration(days: 1)),
        actorId: 'rep-1',
      );

      expect(result, isA<AppSuccess<RecurringOrderPlan>>());
      expect(repository.createdPlan?.sourceOrderId, 'order-1');
      expect(repository.createdPlan?.items.single.variantId, 'variant-1');
    });
  });
}

OrderItem _item() {
  return const OrderItem(
    id: 'item-1',
    variantId: 'variant-1',
    productId: 'product-1',
    quantity: 2,
    unitPrice: 100,
    subtotal: 200,
  );
}

Order _order({required List<OrderItem> items}) {
  final now = DateTime.utc(2026, 9, 9);
  return Order(
    id: 'order-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'rep-1',
    deliveryAddress: const OrderAddress(
      street: 'Rua A',
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
    ),
    billingAddress: const OrderAddress(
      street: 'Rua A',
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
    ),
    priceListId: 'price-list-1',
    paymentTermId: 'term-1',
    items: items,
    status: OrderStatus.submitted,
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: OrderSyncStatus.synced,
  );
}

final class _FakeRecurringOrderPlanRepository
    implements RecurringOrderPlanRepository {
  RecurringOrderPlan? createdPlan;

  @override
  Future<AppResult<RecurringOrderPlan>> createFromOrder({
    required Order sourceOrder,
    required RecurringOrderFrequency frequency,
    required DateTime nextExecutionAt,
    required String actorId,
  }) async {
    final now = DateTime.utc(2026, 9, 9);
    createdPlan = RecurringOrderPlan(
      id: 'plan-1',
      organizationId: sourceOrder.organizationId,
      companyId: sourceOrder.companyId,
      customerId: sourceOrder.customerId,
      sellerId: sourceOrder.sellerId,
      sourceOrderId: sourceOrder.id,
      frequency: frequency,
      nextExecutionAt: nextExecutionAt,
      status: RecurringOrderPlanStatus.active,
      items: sourceOrder.items,
      executions: const <RecurringOrderExecution>[],
      createdAt: now,
      createdBy: actorId,
      updatedAt: now,
      updatedBy: actorId,
      version: 1,
    );
    return AppSuccess<RecurringOrderPlan>(createdPlan!);
  }

  @override
  Future<AppResult<List<RecurringOrderPlan>>> listByCustomer({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<RecurringOrderPlan>> updatePlan({
    required String organizationId,
    required String companyId,
    required String planId,
    required RecurringOrderFrequency frequency,
    required DateTime nextExecutionAt,
    required List<OrderItem> items,
    required String actorId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<RecurringOrderPlan>> updateStatus({
    required String organizationId,
    required String companyId,
    required String planId,
    required RecurringOrderPlanStatus status,
    required String actorId,
  }) {
    throw UnimplementedError();
  }
}
