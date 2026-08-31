import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/pricing/pricing.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('DuplicateOrderUseCase', () {
    late _FakeOrderDraftRepository orderDraftRepository;
    late AddItemsToOrderDraftUseCase addItemsToOrderDraft;

    setUp(() {
      orderDraftRepository = _FakeOrderDraftRepository();
      addItemsToOrderDraft = AddItemsToOrderDraftUseCase(orderDraftRepository);
    });

    DuplicateOrderUseCase buildUseCase({
      required AppResult<Order> sourceResult,
      Map<String, ProductVariant> variantsById =
          const <String, ProductVariant>{},
      Map<String, VariantAvailability> availabilityByVariantId =
          const <String, VariantAvailability>{},
      List<PriceListItem> priceListItems = const <PriceListItem>[],
    }) {
      return DuplicateOrderUseCase(
        _FakeGetOrderByIdUseCase(sourceResult),
        _FakeStartOrderDraftForCustomerUseCase(),
        orderDraftRepository,
        addItemsToOrderDraft,
        _FakeProductVariantRepository(variantsById),
        GetVariantAvailabilityUseCase(
          _FakeVariantAvailabilityRepository(availabilityByVariantId),
        ),
        ResolvePriceForVariantUseCase(
          ResolveApplicablePriceListsUseCase(const _FakePriceListRepository()),
          _FakePriceListItemRepository(priceListItems),
        ),
      );
    }

    test('creates a new draft in draft status, never inheriting the source '
        "order's own status/statusHistory, revalidating price and "
        'availability per item', () async {
      final source = _sourceOrder(
        items: <OrderItem>[
          _item(
            id: 'item-a',
            variantId: 'variant-active',
            productId: 'product-a',
            quantity: 2,
            unitPrice: 10,
          ),
          _item(
            id: 'item-b',
            variantId: 'variant-discontinued',
            productId: 'product-b',
            quantity: 1,
            unitPrice: 20,
          ),
          _item(
            id: 'item-c',
            variantId: 'variant-unavailable',
            productId: 'product-c',
            quantity: 3,
            unitPrice: 30,
          ),
          _item(
            id: 'item-d',
            variantId: 'variant-nopricing',
            productId: 'product-d',
            quantity: 1,
            unitPrice: 40,
          ),
        ],
      );

      final useCase = buildUseCase(
        sourceResult: AppSuccess<Order>(source),
        variantsById: <String, ProductVariant>{
          'variant-active': _activeVariant('variant-active', 'product-a'),
          'variant-unavailable': _activeVariant(
            'variant-unavailable',
            'product-c',
          ),
          'variant-nopricing': _activeVariant('variant-nopricing', 'product-d'),
          // 'variant-discontinued' intentionally absent: getById fails
          // with NotFoundFailure.
        },
        availabilityByVariantId: <String, VariantAvailability>{
          'variant-active': VariantAvailability(
            variantId: 'variant-active',
            productId: 'product-a',
            status: VariantAvailabilityStatus.readyStock,
            availableQuantity: 50,
          ),
          'variant-unavailable': VariantAvailability(
            variantId: 'variant-unavailable',
            productId: 'product-c',
            status: VariantAvailabilityStatus.unavailable,
          ),
          'variant-nopricing': VariantAvailability(
            variantId: 'variant-nopricing',
            productId: 'product-d',
            status: VariantAvailabilityStatus.readyStock,
            availableQuantity: 10,
          ),
        },
        priceListItems: <PriceListItem>[
          _priceListItem(
            productId: 'product-a',
            variantId: 'variant-active',
            price: 12,
          ),
          // No price list item at all for product-d/variant-nopricing.
        ],
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        sellerId: 'rep-1',
        sourceOrderId: 'order-source-1',
        newDraftId: 'order-new-1',
      );

      expect(result, isA<AppSuccess<OrderDuplicationResult>>());
      final duplication = (result as AppSuccess<OrderDuplicationResult>).value;

      // Never inherits status/statusHistory from the source order.
      expect(duplication.draft.status, OrderStatus.draft);
      expect(duplication.draft.statusHistory, hasLength(1));
      expect(
        duplication.draft.statusHistory.single.newStatus,
        OrderStatus.draft,
      );
      expect(duplication.draft.duplicatedFromOrderId, 'order-source-1');
      expect(duplication.draft.duplicatedFromOrderNumber, '000123');
      expect(duplication.sourceOrderId, 'order-source-1');
      expect(duplication.sourceOrderNumber, '000123');

      // Only the fully-revalidated item survives, with the *current*
      // price, never the source's own captured (now stale) unitPrice.
      expect(duplication.draft.items, hasLength(1));
      final survivingItem = duplication.draft.items.single;
      expect(survivingItem.variantId, 'variant-active');
      expect(survivingItem.quantity, 2);
      expect(survivingItem.unitPrice, 12);
      expect(survivingItem.subtotal, 24);

      expect(duplication.priceChanges, hasLength(1));
      expect(duplication.priceChanges.single.variantId, 'variant-active');
      expect(duplication.priceChanges.single.previousUnitPrice, 10);
      expect(duplication.priceChanges.single.newUnitPrice, 12);

      expect(duplication.issues, hasLength(3));
      final issuesByVariant = <String, OrderDuplicationItemIssueType>{
        for (final issue in duplication.issues) issue.variantId: issue.type,
      };
      expect(
        issuesByVariant['variant-discontinued'],
        OrderDuplicationItemIssueType.discontinued,
      );
      expect(
        issuesByVariant['variant-unavailable'],
        OrderDuplicationItemIssueType.unavailable,
      );
      expect(
        issuesByVariant['variant-nopricing'],
        OrderDuplicationItemIssueType.priceUnavailable,
      );
    });

    test('fails validation without creating any draft when the source order '
        'has no items', () async {
      final source = _sourceOrder(items: const <OrderItem>[]);
      final useCase = buildUseCase(sourceResult: AppSuccess<Order>(source));

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        sellerId: 'rep-1',
        sourceOrderId: 'order-source-1',
        newDraftId: 'order-new-1',
      );

      expect(result, isA<AppFailure<OrderDuplicationResult>>());
      expect(
        (result as AppFailure<OrderDuplicationResult>).failure,
        isA<ValidationFailure>(),
      );
      expect(orderDraftRepository.savedOrders, isEmpty);
    });

    test('propagates the failure when the caller may not read the source '
        'order at all (RBAC denied)', () async {
      const failure = PermissionFailure(
        'User is not allowed to view this order.',
        code: 'order_not_visible',
      );
      final useCase = buildUseCase(
        sourceResult: const AppFailure<Order>(failure),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        sellerId: 'rep-1',
        sourceOrderId: 'order-source-1',
        newDraftId: 'order-new-1',
      );

      expect(result, isA<AppFailure<OrderDuplicationResult>>());
      expect(
        (result as AppFailure<OrderDuplicationResult>).failure,
        isA<PermissionFailure>(),
      );
      expect(orderDraftRepository.savedOrders, isEmpty);
    });
  });
}

OrderItem _item({
  required String id,
  required String variantId,
  required String productId,
  required int quantity,
  required double unitPrice,
}) {
  return OrderItem(
    id: id,
    variantId: variantId,
    productId: productId,
    quantity: quantity,
    unitPrice: unitPrice,
    subtotal: quantity * unitPrice,
  );
}

Order _sourceOrder({required List<OrderItem> items}) {
  final createdAt = DateTime.utc(2026, 6, 1);
  final submittedAt = DateTime.utc(2026, 6, 2);
  return Order(
    id: 'order-source-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-old',
    customerId: 'customer-1',
    sellerId: 'rep-1',
    orderNumber: '000123',
    deliveryAddress: const OrderAddress(
      street: 'Rua Antiga',
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
    ),
    billingAddress: const OrderAddress(
      street: 'Rua Antiga',
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
    ),
    priceListId: 'price-list-old',
    paymentTermId: 'term-old',
    items: items,
    status: OrderStatus.submitted,
    statusHistory: <OrderStatusHistoryEntry>[
      OrderStatusHistoryEntry(
        newStatus: OrderStatus.draft,
        changedAt: createdAt,
        actorId: 'rep-1',
      ),
      OrderStatusHistoryEntry(
        previousStatus: OrderStatus.draft,
        newStatus: OrderStatus.submitted,
        changedAt: submittedAt,
        actorId: 'rep-1',
      ),
    ],
    createdAt: createdAt,
    createdBy: 'rep-1',
    updatedAt: submittedAt,
    updatedBy: 'rep-1',
    version: 2,
    syncStatus: OrderSyncStatus.synced,
  );
}

ProductVariant _activeVariant(String id, String productId) {
  final now = DateTime.utc(2026, 1, 1);
  return ProductVariant(
    id: id,
    organizationId: 'org-1',
    productId: productId,
    colorId: 'color-1',
    sizeGridTemplateId: 'grid-1',
    sizeId: 'size-1',
    sku: Sku.parse('SKU-$id'),
    status: ProductVariantStatus.active,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}

PriceListItem _priceListItem({
  required String productId,
  required String variantId,
  required double price,
}) {
  return PriceListItem(
    id: PriceListItem.composeId(
      priceListId: 'price-list-1',
      productId: productId,
      variantId: variantId,
    ),
    organizationId: 'org-1',
    companyId: 'company-1',
    priceListId: 'price-list-1',
    productId: productId,
    variantId: variantId,
    price: price,
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'user-1',
  );
}

final class _FakeGetOrderByIdUseCase implements GetOrderByIdUseCase {
  _FakeGetOrderByIdUseCase(this._result);

  final AppResult<Order> _result;

  @override
  Future<AppResult<Order>> call({
    required String organizationId,
    required String companyId,
    required String userId,
    required String orderId,
  }) async => _result;
}

final class _FakeStartOrderDraftForCustomerUseCase
    implements StartOrderDraftForCustomerUseCase {
  @override
  Future<AppResult<Order>> call({
    required String id,
    required String organizationId,
    required String companyId,
    required String sellerId,
    required String customerId,
    DateTime? now,
  }) async {
    final resolvedNow = (now ?? DateTime.utc(2026, 8, 30)).toUtc();
    return AppSuccess<Order>(
      Order(
        id: id,
        organizationId: organizationId,
        companyId: companyId,
        branchId: 'branch-current',
        customerId: customerId,
        sellerId: sellerId,
        deliveryAddress: const OrderAddress(
          street: 'Rua Atual',
          city: 'Blumenau',
          state: 'SC',
          zipCode: '89010000',
        ),
        billingAddress: const OrderAddress(
          street: 'Rua Atual',
          city: 'Blumenau',
          state: 'SC',
          zipCode: '89010000',
        ),
        priceListId: 'price-list-current',
        paymentTermId: 'term-current',
        status: OrderStatus.draft,
        statusHistory: <OrderStatusHistoryEntry>[
          OrderStatusHistoryEntry(
            newStatus: OrderStatus.draft,
            changedAt: resolvedNow,
            actorId: sellerId,
          ),
        ],
        createdAt: resolvedNow,
        createdBy: sellerId,
        updatedAt: resolvedNow,
        updatedBy: sellerId,
        version: 1,
        syncStatus: OrderSyncStatus.pending,
      ),
    );
  }
}

final class _FakeOrderDraftRepository implements OrderDraftRepository {
  final Map<String, Order> _byId = <String, Order>{};
  final List<Order> savedOrders = <Order>[];

  @override
  Future<AppResult<void>> saveDraft({required Order order}) async {
    _byId[order.id] = order;
    savedOrders.add(order);
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<Order?>> getDraftById({
    required String organizationId,
    required String companyId,
    required String id,
  }) async {
    return AppSuccess<Order?>(_byId[id]);
  }

  @override
  Future<AppResult<List<Order>>> getLocalOrdersForCompany({
    required String organizationId,
    required String companyId,
  }) async {
    return const AppSuccess<List<Order>>(<Order>[]);
  }
}

final class _FakeProductVariantRepository implements ProductVariantRepository {
  _FakeProductVariantRepository(this._byId);

  final Map<String, ProductVariant> _byId;

  @override
  Future<AppResult<ProductVariant>> getById({
    required String organizationId,
    required String id,
  }) async {
    final variant = _byId[id];
    if (variant == null) {
      return const AppFailure<ProductVariant>(
        NotFoundFailure('Variant not found.', code: 'variant_not_found'),
      );
    }
    return AppSuccess<ProductVariant>(variant);
  }

  @override
  Future<AppResult<ProductVariant>> create({required ProductVariant variant}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<ProductVariant>> update({required ProductVariant variant}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<List<ProductVariant>>> listByOrganization(
    String organizationId,
  ) => throw UnimplementedError();

  @override
  Future<AppResult<List<ProductVariant>>> listByProduct({
    required String organizationId,
    required String productId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingVariantId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> existsByEan({
    required String organizationId,
    required Ean ean,
    String? excludingVariantId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<bool>> isReferencedByOrder({
    required String organizationId,
    required String variantId,
  }) => throw UnimplementedError();
}

final class _FakeVariantAvailabilityRepository
    implements VariantAvailabilityRepository {
  _FakeVariantAvailabilityRepository(this._byVariantId);

  final Map<String, VariantAvailability> _byVariantId;

  @override
  Future<AppResult<List<VariantAvailability>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async {
    return AppSuccess<List<VariantAvailability>>(<VariantAvailability>[
      for (final id in variantIds)
        if (_byVariantId.containsKey(id)) _byVariantId[id]!,
    ]);
  }

  @override
  Future<AppResult<List<VariantAvailability>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async =>
      const AppSuccess<List<VariantAvailability>>(<VariantAvailability>[]);
}

final class _FakePriceListRepository implements PriceListRepository {
  const _FakePriceListRepository();

  @override
  Future<AppResult<PriceList>> create({required PriceList priceList}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<PriceList?>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<PriceList>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async => AppSuccess<List<PriceList>>(<PriceList>[
    PriceList(
      id: 'price-list-1',
      organizationId: organizationId,
      companyId: companyId,
      name: 'Tabela padrão',
      currency: 'BRL',
      validFrom: DateTime.utc(2026, 1, 1),
      status: PriceListStatus.active,
      scope: PriceListScopeType.company,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'user-1',
      version: 1,
      syncStatus: PriceListSyncStatus.synced,
    ),
  ]);

  @override
  Future<AppResult<PriceList>> update({required PriceList priceList}) =>
      throw UnimplementedError();
}

final class _FakePriceListItemRepository implements PriceListItemRepository {
  const _FakePriceListItemRepository(this._items);

  final List<PriceListItem> _items;

  @override
  Future<AppResult<List<PriceListItem>>> listByPriceList({
    required String organizationId,
    required String companyId,
    required String priceListId,
  }) async => AppSuccess<List<PriceListItem>>(
    _items
        .where((item) => item.priceListId == priceListId)
        .toList(growable: false),
  );

  @override
  Future<AppResult<List<PriceListItem>>> listByProduct({
    required String organizationId,
    required String companyId,
    required String productId,
  }) async => AppSuccess<List<PriceListItem>>(
    _items.where((item) => item.productId == productId).toList(growable: false),
  );

  @override
  Future<AppResult<List<PriceListItem>>> upsertBatch({
    required String organizationId,
    required String companyId,
    required String priceListId,
    required List<PriceListItem> items,
    required bool confirmOverwrite,
  }) => throw UnimplementedError();
}
