import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('OrderProductAdditionCubit', () {
    blocTest<OrderProductAdditionCubit, OrderProductAdditionState>(
      'persists the given items via AddItemsToOrderDraftUseCase and emits '
      'success',
      build: () => OrderProductAdditionCubit(
        _FakeAddItemsToOrderDraftUseCase(
          AppSuccess<Order>(_order(items: const <OrderItem>[])),
        ),
      ),
      act: (cubit) => cubit.add(
        organizationId: 'org-1',
        companyId: 'company-1',
        draftId: 'order-1',
        items: <OrderItem>[
          const OrderItem(
            id: 'item-1',
            variantId: 'variant-1',
            productId: 'product-1',
            quantity: 2,
            unitPrice: 25.5,
            subtotal: 51,
          ),
        ],
      ),
      expect: () => <Object>[
        isA<OrderProductAdditionState>().having(
          (state) => state.status,
          'status',
          OrderProductAdditionStatus.submitting,
        ),
        isA<OrderProductAdditionState>().having(
          (state) => state.status,
          'status',
          OrderProductAdditionStatus.success,
        ),
      ],
    );

    blocTest<OrderProductAdditionCubit, OrderProductAdditionState>(
      'surfaces a failure instead of silently dropping it',
      build: () => OrderProductAdditionCubit(
        _FakeAddItemsToOrderDraftUseCase(
          const AppFailure<Order>(NotFoundFailure('Order draft not found.')),
        ),
      ),
      act: (cubit) => cubit.add(
        organizationId: 'org-1',
        companyId: 'company-1',
        draftId: 'missing-draft',
        items: <OrderItem>[
          const OrderItem(
            id: 'item-1',
            variantId: 'variant-1',
            productId: 'product-1',
            quantity: 1,
            unitPrice: 10,
            subtotal: 10,
          ),
        ],
      ),
      expect: () => <Object>[
        isA<OrderProductAdditionState>().having(
          (state) => state.status,
          'status',
          OrderProductAdditionStatus.submitting,
        ),
        isA<OrderProductAdditionState>()
            .having(
              (state) => state.status,
              'status',
              OrderProductAdditionStatus.failure,
            )
            .having((state) => state.failure, 'failure', isNotNull),
      ],
    );
  });
}

Order _order({required List<OrderItem> items}) {
  final now = DateTime.utc(2026, 6, 1);
  return Order(
    id: 'order-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'seller-1',
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

final class _FakeAddItemsToOrderDraftUseCase
    implements AddItemsToOrderDraftUseCase {
  _FakeAddItemsToOrderDraftUseCase(this._result);

  final AppResult<Order> _result;
  final List<List<OrderItem>> receivedItems = <List<OrderItem>>[];

  @override
  Future<AppResult<Order>> call({
    required String organizationId,
    required String companyId,
    required String draftId,
    required List<OrderItem> items,
  }) async {
    receivedItems.add(items);
    return _result;
  }
}
