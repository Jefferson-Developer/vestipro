import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/users/users.dart';

void main() {
  group('GetOrderPricingSummaryUseCase', () {
    test(
      'calls the pricing engine with the customer segment and current items, '
      'returning exactly what it responds',
      () async {
        final customerRepository = _FakeCustomerRepository(
          _customer(segment: 'atacado'),
        );
        final pricingRepository = _FakeOrderPricingRepository(
          AppSuccess<OrderPricingSummary>(_summary()),
        );
        final useCase = GetOrderPricingSummaryUseCase(
          pricingRepository,
          GetCustomerByIdUseCase(customerRepository),
        );

        final result = await useCase(order: _order());

        expect(result, isA<AppSuccess<OrderPricingSummary>>());
        final summary = (result as AppSuccess<OrderPricingSummary>).value;
        expect(summary.subtotal, 200);
        expect(summary.total, 190);

        expect(pricingRepository.lastRequest, isNotNull);
        final request = pricingRepository.lastRequest!;
        expect(request.organizationId, 'org-1');
        expect(request.companyId, 'company-1');
        expect(request.customerSegment, 'atacado');
        expect(request.priceListId, 'price-list-1');
        expect(request.paymentTermId, 'term-1');
        expect(request.shippingAmount, 15);
        expect(request.items, hasLength(1));
        expect(request.items.single.productId, 'product-1');
        expect(request.items.single.variantId, 'variant-1');
        expect(request.items.single.quantity, 2);
        expect(request.idempotencyKey, isNotEmpty);
      },
    );

    test('reuses the same idempotency key for the exact same request, and a '
        'different one once the items change', () async {
      final customerRepository = _FakeCustomerRepository(
        _customer(segment: 'atacado'),
      );
      final pricingRepository = _FakeOrderPricingRepository(
        AppSuccess<OrderPricingSummary>(_summary()),
      );
      final useCase = GetOrderPricingSummaryUseCase(
        pricingRepository,
        GetCustomerByIdUseCase(customerRepository),
      );

      await useCase(order: _order());
      final firstKey = pricingRepository.lastRequest!.idempotencyKey;

      await useCase(order: _order());
      final secondKey = pricingRepository.lastRequest!.idempotencyKey;
      expect(secondKey, firstKey);

      await useCase(order: _order(quantity: 3));
      final thirdKey = pricingRepository.lastRequest!.idempotencyKey;
      expect(thirdKey, isNot(firstKey));
    });

    test(
      'propagates a network/connectivity failure from the pricing engine',
      () async {
        final customerRepository = _FakeCustomerRepository(
          _customer(segment: 'atacado'),
        );
        final pricingRepository = _FakeOrderPricingRepository(
          const AppFailure<OrderPricingSummary>(
            ConnectivityFailure('Sem conexão com o servidor.'),
          ),
        );
        final useCase = GetOrderPricingSummaryUseCase(
          pricingRepository,
          GetCustomerByIdUseCase(customerRepository),
        );

        final result = await useCase(order: _order());

        expect(result, isA<AppFailure<OrderPricingSummary>>());
        expect(
          (result as AppFailure<OrderPricingSummary>).failure,
          isA<ConnectivityFailure>(),
        );
      },
    );

    test('surfaces a response whose manual discount exceeds the seller\'s '
        'profile limit as approvalRequired, never hiding it', () async {
      final customerRepository = _FakeCustomerRepository(
        _customer(segment: 'atacado'),
      );
      final pricingRepository = _FakeOrderPricingRepository(
        AppSuccess<OrderPricingSummary>(_summary(approvalRequired: true)),
      );
      final useCase = GetOrderPricingSummaryUseCase(
        pricingRepository,
        GetCustomerByIdUseCase(customerRepository),
      );

      final result = await useCase(order: _order());

      expect(result, isA<AppSuccess<OrderPricingSummary>>());
      expect(
        (result as AppSuccess<OrderPricingSummary>).value.approvalRequired,
        isTrue,
      );
    });

    test(
      'fails without calling the pricing engine when the order has no items',
      () async {
        final customerRepository = _FakeCustomerRepository(
          _customer(segment: 'atacado'),
        );
        final pricingRepository = _FakeOrderPricingRepository(
          AppSuccess<OrderPricingSummary>(_summary()),
        );
        final useCase = GetOrderPricingSummaryUseCase(
          pricingRepository,
          GetCustomerByIdUseCase(customerRepository),
        );

        final result = await useCase(order: _order(items: const <OrderItem>[]));

        expect(result, isA<AppFailure<OrderPricingSummary>>());
        expect(
          (result as AppFailure<OrderPricingSummary>).failure.code,
          'order_pricing_summary_no_items',
        );
        expect(pricingRepository.lastRequest, isNull);
      },
    );

    test('propagates a failure resolving the customer segment', () async {
      final customerRepository = _FakeCustomerRepository(
        null,
        failure: const NotFoundFailure('Customer not found.'),
      );
      final pricingRepository = _FakeOrderPricingRepository(
        AppSuccess<OrderPricingSummary>(_summary()),
      );
      final useCase = GetOrderPricingSummaryUseCase(
        pricingRepository,
        GetCustomerByIdUseCase(customerRepository),
      );

      final result = await useCase(order: _order());

      expect(result, isA<AppFailure<OrderPricingSummary>>());
      expect(
        (result as AppFailure<OrderPricingSummary>).failure,
        isA<NotFoundFailure>(),
      );
      expect(pricingRepository.lastRequest, isNull);
    });
  });
}

Order _order({int quantity = 2, List<OrderItem>? items}) {
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
    shippingAmount: 15,
    items:
        items ??
        <OrderItem>[
          OrderItem(
            id: 'item-1',
            variantId: 'variant-1',
            productId: 'product-1',
            quantity: quantity,
            unitPrice: 100,
            subtotal: quantity * 100,
          ),
        ],
    status: OrderStatus.draft,
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

Customer _customer({String? segment}) {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: 'customer-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.individual,
    document: CnpjCpf.parse('529.982.247-25'),
    fullName: 'Ciclano da Silva',
    status: CustomerStatus.active,
    segment: segment,
    registeredAt: now,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.pending,
  );
}

OrderPricingSummary _summary({bool approvalRequired = false}) {
  return OrderPricingSummary(
    currency: 'BRL',
    subtotal: 200,
    campaignDiscountTotal: 10,
    manualDiscountTotal: 0,
    paymentTermAdjustmentTotal: 0,
    shippingAmount: 15,
    total: 190,
    blocked: false,
    approvalRequired: approvalRequired,
  );
}

final class _OrderPricingCalculateRequest {
  const _OrderPricingCalculateRequest({
    required this.organizationId,
    required this.companyId,
    required this.customerSegment,
    required this.priceListId,
    required this.paymentTermId,
    required this.idempotencyKey,
    required this.shippingAmount,
    required this.items,
  });

  final String organizationId;
  final String companyId;
  final String customerSegment;
  final String priceListId;
  final String paymentTermId;
  final String idempotencyKey;
  final double shippingAmount;
  final List<OrderPricingItemRequest> items;
}

final class _FakeOrderPricingRepository implements OrderPricingRepository {
  _FakeOrderPricingRepository(this._result);

  final AppResult<OrderPricingSummary> _result;
  _OrderPricingCalculateRequest? lastRequest;

  @override
  Future<AppResult<OrderPricingSummary>> calculate({
    required String organizationId,
    required String companyId,
    required String customerSegment,
    required String priceListId,
    required String paymentTermId,
    required String idempotencyKey,
    required double shippingAmount,
    required List<OrderPricingItemRequest> items,
  }) async {
    lastRequest = _OrderPricingCalculateRequest(
      organizationId: organizationId,
      companyId: companyId,
      customerSegment: customerSegment,
      priceListId: priceListId,
      paymentTermId: paymentTermId,
      idempotencyKey: idempotencyKey,
      shippingAmount: shippingAmount,
      items: items,
    );
    return _result;
  }
}

final class _FakeCustomerRepository implements CustomerRepository {
  _FakeCustomerRepository(this._customer, {this.failure});

  final Customer? _customer;
  final Failure? failure;

  @override
  Future<AppResult<Customer>> getById({
    required String organizationId,
    required String id,
  }) async {
    final currentFailure = failure;
    if (currentFailure != null) return AppFailure<Customer>(currentFailure);
    return AppSuccess<Customer>(_customer!);
  }

  @override
  Future<AppResult<bool>> existsByDocument({
    required String organizationId,
    required CnpjCpf document,
    String? excludingCustomerId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Customer>> create({required Customer customer}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Customer>> update({
    required Customer customer,
    required Set<CustomerSensitiveField> sensitiveFieldsToAudit,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Customer>> deactivate({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<CustomerPortfolioPageResult>> listPortfolioPage({
    required CustomerVisibilityFilter visibility,
    required List<PortfolioAssignment> activeAssignments,
    required CustomerPortfolioFilters filters,
    required String searchQuery,
    required int limit,
    String? cursor,
    required DateTime now,
  }) {
    throw UnimplementedError();
  }
}
