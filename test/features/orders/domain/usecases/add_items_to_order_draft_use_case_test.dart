import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('AddItemsToOrderDraftUseCase', () {
    test(
      'persists the correct product+variant+price when adding to an existing '
      'draft with no items yet',
      () async {
        final repository = _FakeOrderDraftRepository(
          existingDraft: _order(items: const <OrderItem>[]),
        );
        final useCase = AddItemsToOrderDraftUseCase(repository);

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          draftId: 'order-1',
          items: <OrderItem>[_newItem(variantId: 'variant-1', quantity: 2)],
        );

        expect(result, isA<AppSuccess<Order>>());
        final saved = repository.savedOrders.single;
        expect(saved.items, hasLength(1));
        expect(saved.items.single.variantId, 'variant-1');
        expect(saved.items.single.productId, 'product-1');
        expect(saved.items.single.quantity, 2);
        expect(saved.items.single.unitPrice, 25.5);
        expect(saved.items.single.subtotal, 51);
        expect(saved.version, 2);
      },
    );

    test(
      'merges into an item already on the draft for the same variant',
      () async {
        final repository = _FakeOrderDraftRepository(
          existingDraft: _order(
            items: <OrderItem>[
              OrderItem(
                id: 'existing-item',
                variantId: 'variant-1',
                productId: 'product-1',
                quantity: 1,
                unitPrice: 20,
                subtotal: 20,
              ),
            ],
          ),
        );
        final useCase = AddItemsToOrderDraftUseCase(repository);

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          draftId: 'order-1',
          items: <OrderItem>[_newItem(variantId: 'variant-1', quantity: 2)],
        );

        expect(result, isA<AppSuccess<Order>>());
        final saved = repository.savedOrders.single;
        expect(saved.items, hasLength(1));
        expect(saved.items.single.id, 'existing-item');
        expect(saved.items.single.quantity, 3);
      },
    );

    test(
      'fails without saving when the draft does not exist locally',
      () async {
        final repository = _FakeOrderDraftRepository(existingDraft: null);
        final useCase = AddItemsToOrderDraftUseCase(repository);

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          draftId: 'missing-draft',
          items: <OrderItem>[_newItem(variantId: 'variant-1', quantity: 1)],
        );

        expect(result, isA<AppFailure<Order>>());
        expect((result as AppFailure<Order>).failure, isA<NotFoundFailure>());
        expect(repository.savedOrders, isEmpty);
      },
    );

    test('fails validation for an empty items list', () async {
      final repository = _FakeOrderDraftRepository(
        existingDraft: _order(items: const <OrderItem>[]),
      );
      final useCase = AddItemsToOrderDraftUseCase(repository);

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        draftId: 'order-1',
        items: const <OrderItem>[],
      );

      expect(result, isA<AppFailure<Order>>());
      expect((result as AppFailure<Order>).failure, isA<ValidationFailure>());
      expect(repository.savedOrders, isEmpty);
    });

    test('fails validation for a non-positive quantity', () async {
      final repository = _FakeOrderDraftRepository(
        existingDraft: _order(items: const <OrderItem>[]),
      );
      final useCase = AddItemsToOrderDraftUseCase(repository);

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        draftId: 'order-1',
        items: <OrderItem>[_newItem(variantId: 'variant-1', quantity: 0)],
      );

      expect(result, isA<AppFailure<Order>>());
      expect(repository.savedOrders, isEmpty);
    });

    test('propagates a save failure from the repository', () async {
      final repository = _FakeOrderDraftRepository(
        existingDraft: _order(items: const <OrderItem>[]),
        saveResult: const AppFailure<void>(UnexpectedFailure('disk full')),
      );
      final useCase = AddItemsToOrderDraftUseCase(repository);

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        draftId: 'order-1',
        items: <OrderItem>[_newItem(variantId: 'variant-1', quantity: 1)],
      );

      expect(result, isA<AppFailure<Order>>());
      expect((result as AppFailure<Order>).failure, isA<UnexpectedFailure>());
    });
  });
}

OrderItem _newItem({required String variantId, required int quantity}) {
  return OrderItem(
    id: 'new-item-$variantId',
    variantId: variantId,
    productId: 'product-1',
    quantity: quantity,
    unitPrice: 25.5,
    subtotal: quantity * 25.5,
  );
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

final class _FakeOrderDraftRepository implements OrderDraftRepository {
  _FakeOrderDraftRepository({
    required this._existingDraft,
    this.saveResult = const AppSuccess<void>(null),
  });

  final Order? _existingDraft;
  final AppResult<void> saveResult;
  final List<Order> savedOrders = <Order>[];

  @override
  Future<AppResult<Order?>> getDraftById({
    required String organizationId,
    required String companyId,
    required String id,
  }) async {
    return AppSuccess<Order?>(_existingDraft);
  }

  @override
  Future<AppResult<void>> saveDraft({required Order order}) async {
    savedOrders.add(order);
    return saveResult;
  }

  @override
  Future<AppResult<List<Order>>> getLocalOrdersForCompany({
    required String organizationId,
    required String companyId,
  }) async {
    return const AppSuccess<List<Order>>(<Order>[]);
  }
}
