import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('OrderDraftBloc', () {
    final now = DateTime.utc(2026, 6, 1);
    final customer = _customer();

    blocTest<OrderDraftBloc, OrderDraftState>(
      'awaits a customer pick when no draftId is given',
      build: () => OrderDraftBloc(
        getOrderDraft: _FakeGetOrderDraftUseCase(
          const AppSuccess<Order?>(null),
        ),
        startOrderDraftForCustomer: _FakeStartOrderDraftForCustomerUseCase(
          AppSuccess<Order>(_order(now)),
        ),
        saveOrderDraft: _FakeSaveOrderDraftUseCase(<AppResult<void>>[
          const AppSuccess<void>(null),
        ]),
        analyticsService: FakeAnalyticsService(),
      ),
      act: (bloc) => bloc.add(
        const OrderDraftStarted(
          organizationId: 'org-1',
          companyId: 'company-1',
          sellerId: 'seller-1',
        ),
      ),
      expect: () => <Object>[
        isA<OrderDraftState>().having(
          (state) => state.loadStatus,
          'loadStatus',
          OrderDraftLoadStatus.loading,
        ),
        isA<OrderDraftState>().having(
          (state) => state.loadStatus,
          'loadStatus',
          OrderDraftLoadStatus.awaitingCustomer,
        ),
      ],
    );

    blocTest<OrderDraftBloc, OrderDraftState>(
      'resumes a persisted draft after the app restarts',
      build: () => OrderDraftBloc(
        getOrderDraft: _FakeGetOrderDraftUseCase(
          AppSuccess<Order?>(_order(now)),
        ),
        startOrderDraftForCustomer: _FakeStartOrderDraftForCustomerUseCase(
          AppSuccess<Order>(_order(now)),
        ),
        saveOrderDraft: _FakeSaveOrderDraftUseCase(<AppResult<void>>[
          const AppSuccess<void>(null),
        ]),
        analyticsService: FakeAnalyticsService(),
      ),
      act: (bloc) => bloc.add(
        const OrderDraftStarted(
          organizationId: 'org-1',
          companyId: 'company-1',
          sellerId: 'seller-1',
          draftId: 'order-1',
        ),
      ),
      expect: () => <Object>[
        isA<OrderDraftState>().having(
          (state) => state.loadStatus,
          'loadStatus',
          OrderDraftLoadStatus.loading,
        ),
        isA<OrderDraftState>()
            .having(
              (state) => state.loadStatus,
              'loadStatus',
              OrderDraftLoadStatus.ready,
            )
            .having((state) => state.order?.id, 'order id', 'order-1'),
      ],
    );

    blocTest<OrderDraftBloc, OrderDraftState>(
      'falls back to awaiting a customer when the resumed draft belongs to a '
      'different seller',
      build: () => OrderDraftBloc(
        getOrderDraft: _FakeGetOrderDraftUseCase(
          AppSuccess<Order?>(_order(now)),
        ),
        startOrderDraftForCustomer: _FakeStartOrderDraftForCustomerUseCase(
          AppSuccess<Order>(_order(now)),
        ),
        saveOrderDraft: _FakeSaveOrderDraftUseCase(<AppResult<void>>[]),
        analyticsService: FakeAnalyticsService(),
      ),
      act: (bloc) => bloc.add(
        const OrderDraftStarted(
          organizationId: 'org-1',
          companyId: 'company-1',
          sellerId: 'someone-else',
          draftId: 'order-1',
        ),
      ),
      expect: () => <Object>[
        isA<OrderDraftState>().having(
          (state) => state.loadStatus,
          'loadStatus',
          OrderDraftLoadStatus.loading,
        ),
        isA<OrderDraftState>().having(
          (state) => state.loadStatus,
          'loadStatus',
          OrderDraftLoadStatus.awaitingCustomer,
        ),
      ],
    );

    late FakeAnalyticsService analytics;
    blocTest<OrderDraftBloc, OrderDraftState>(
      'starts and persists a draft, logging analytics, once a customer is '
      'selected',
      build: () {
        analytics = FakeAnalyticsService();
        return OrderDraftBloc(
          getOrderDraft: _FakeGetOrderDraftUseCase(
            const AppSuccess<Order?>(null),
          ),
          startOrderDraftForCustomer: _FakeStartOrderDraftForCustomerUseCase(
            AppSuccess<Order>(_order(now)),
          ),
          saveOrderDraft: _FakeSaveOrderDraftUseCase(<AppResult<void>>[]),
          analyticsService: analytics,
        );
      },
      seed: () => const OrderDraftState(
        loadStatus: OrderDraftLoadStatus.awaitingCustomer,
        organizationId: 'org-1',
        companyId: 'company-1',
        sellerId: 'seller-1',
      ),
      act: (bloc) => bloc.add(OrderDraftCustomerSelected(customer)),
      expect: () => <Object>[
        isA<OrderDraftState>().having(
          (state) => state.loadStatus,
          'loadStatus',
          OrderDraftLoadStatus.loading,
        ),
        isA<OrderDraftState>()
            .having(
              (state) => state.loadStatus,
              'loadStatus',
              OrderDraftLoadStatus.ready,
            )
            .having((state) => state.order?.id, 'order id', 'order-1')
            .having(
              (state) => state.saveStatus,
              'saveStatus',
              OrderDraftSaveStatus.saved,
            ),
      ],
      verify: (_) {
        expect(
          analytics.loggedEvents.map((event) => event.name),
          contains(AnalyticsEvents.orderCreated),
        );
      },
    );

    blocTest<OrderDraftBloc, OrderDraftState>(
      'surfaces a permission failure and never exposes an order when the '
      'customer is outside the seller\'s portfolio',
      build: () => OrderDraftBloc(
        getOrderDraft: _FakeGetOrderDraftUseCase(
          const AppSuccess<Order?>(null),
        ),
        startOrderDraftForCustomer: _FakeStartOrderDraftForCustomerUseCase(
          const AppFailure<Order>(
            PermissionFailure(
              'Customer is outside the seller\'s portfolio.',
              code: 'order_draft_customer_outside_portfolio',
            ),
          ),
        ),
        saveOrderDraft: _FakeSaveOrderDraftUseCase(<AppResult<void>>[]),
        analyticsService: FakeAnalyticsService(),
      ),
      seed: () => const OrderDraftState(
        loadStatus: OrderDraftLoadStatus.awaitingCustomer,
        organizationId: 'org-1',
        companyId: 'company-1',
        sellerId: 'seller-1',
      ),
      act: (bloc) => bloc.add(OrderDraftCustomerSelected(customer)),
      expect: () => <Object>[
        isA<OrderDraftState>().having(
          (state) => state.loadStatus,
          'loadStatus',
          OrderDraftLoadStatus.loading,
        ),
        isA<OrderDraftState>()
            .having(
              (state) => state.loadStatus,
              'loadStatus',
              OrderDraftLoadStatus.awaitingCustomer,
            )
            .having((state) => state.order, 'order', isNull)
            .having(
              (state) => state.failure?.code,
              'failure code',
              'order_draft_customer_outside_portfolio',
            ),
      ],
    );

    blocTest<OrderDraftBloc, OrderDraftState>(
      'debounces autosave of a notes edit',
      build: () => OrderDraftBloc(
        getOrderDraft: _FakeGetOrderDraftUseCase(
          const AppSuccess<Order?>(null),
        ),
        startOrderDraftForCustomer: _FakeStartOrderDraftForCustomerUseCase(
          AppSuccess<Order>(_order(now)),
        ),
        saveOrderDraft: _FakeSaveOrderDraftUseCase(<AppResult<void>>[
          const AppSuccess<void>(null),
        ]),
        analyticsService: FakeAnalyticsService(),
      ),
      seed: () => OrderDraftState(
        loadStatus: OrderDraftLoadStatus.ready,
        organizationId: 'org-1',
        companyId: 'company-1',
        sellerId: 'seller-1',
        order: _order(now),
        saveStatus: OrderDraftSaveStatus.saved,
      ),
      act: (bloc) =>
          bloc.add(const OrderDraftNotesChanged('Entregar pela manhã')),
      wait: OrderDraftBloc.autoSaveDebounce * 2,
      expect: () => <Object>[
        isA<OrderDraftState>()
            .having(
              (state) => state.order?.notes,
              'notes',
              'Entregar pela manhã',
            )
            .having(
              (state) => state.saveStatus,
              'saveStatus',
              OrderDraftSaveStatus.idle,
            ),
        isA<OrderDraftState>().having(
          (state) => state.saveStatus,
          'saveStatus',
          OrderDraftSaveStatus.saving,
        ),
        isA<OrderDraftState>()
            .having(
              (state) => state.saveStatus,
              'saveStatus',
              OrderDraftSaveStatus.saved,
            )
            .having((state) => state.order?.version, 'version', 2),
      ],
    );

    blocTest<OrderDraftBloc, OrderDraftState>(
      'surfaces a failed autosave as a recoverable error and recovers on retry',
      build: () => OrderDraftBloc(
        getOrderDraft: _FakeGetOrderDraftUseCase(
          const AppSuccess<Order?>(null),
        ),
        startOrderDraftForCustomer: _FakeStartOrderDraftForCustomerUseCase(
          AppSuccess<Order>(_order(now)),
        ),
        saveOrderDraft: _FakeSaveOrderDraftUseCase(<AppResult<void>>[
          const AppFailure<void>(UnexpectedFailure('disk full')),
          const AppSuccess<void>(null),
        ]),
        analyticsService: FakeAnalyticsService(),
      ),
      seed: () => OrderDraftState(
        loadStatus: OrderDraftLoadStatus.ready,
        organizationId: 'org-1',
        companyId: 'company-1',
        sellerId: 'seller-1',
        order: _order(now),
        saveStatus: OrderDraftSaveStatus.saved,
      ),
      act: (bloc) async {
        bloc.add(const OrderDraftNotesChanged('Entregar pela manhã'));
        await Future<void>.delayed(OrderDraftBloc.autoSaveDebounce * 2);
        bloc.add(const OrderDraftAutoSaveRetried());
      },
      wait: OrderDraftBloc.autoSaveDebounce * 2,
      expect: () => <Object>[
        isA<OrderDraftState>().having(
          (state) => state.saveStatus,
          'saveStatus',
          OrderDraftSaveStatus.idle,
        ),
        isA<OrderDraftState>().having(
          (state) => state.saveStatus,
          'saveStatus',
          OrderDraftSaveStatus.saving,
        ),
        isA<OrderDraftState>().having(
          (state) => state.saveStatus,
          'saveStatus',
          OrderDraftSaveStatus.failure,
        ),
        isA<OrderDraftState>().having(
          (state) => state.saveStatus,
          'saveStatus',
          OrderDraftSaveStatus.saving,
        ),
        isA<OrderDraftState>().having(
          (state) => state.saveStatus,
          'saveStatus',
          OrderDraftSaveStatus.saved,
        ),
      ],
    );
  });
}

Order _order(DateTime now) {
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
    status: OrderStatus.draft,
    statusHistory: <OrderStatusHistoryEntry>[
      OrderStatusHistoryEntry(
        newStatus: OrderStatus.draft,
        changedAt: now,
        actorId: 'seller-1',
      ),
    ],
    createdAt: now,
    createdBy: 'seller-1',
    updatedAt: now,
    updatedBy: 'seller-1',
    version: 1,
    syncStatus: OrderSyncStatus.pending,
  );
}

Customer _customer() {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: 'customer-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.individual,
    document: CnpjCpf.parse('529.982.247-25'),
    fullName: 'Ciclano da Silva',
    status: CustomerStatus.active,
    registeredAt: now,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.pending,
  );
}

final class _FakeGetOrderDraftUseCase implements GetOrderDraftUseCase {
  _FakeGetOrderDraftUseCase(this._result);

  final AppResult<Order?> _result;

  @override
  Future<AppResult<Order?>> call({
    required String organizationId,
    required String companyId,
    required String id,
  }) async {
    return _result;
  }
}

final class _FakeStartOrderDraftForCustomerUseCase
    implements StartOrderDraftForCustomerUseCase {
  _FakeStartOrderDraftForCustomerUseCase(this._result);

  final AppResult<Order> _result;

  @override
  Future<AppResult<Order>> call({
    required String id,
    required String organizationId,
    required String companyId,
    required String sellerId,
    required String customerId,
    DateTime? now,
  }) async {
    return _result;
  }
}

final class _FakeSaveOrderDraftUseCase implements SaveOrderDraftUseCase {
  _FakeSaveOrderDraftUseCase(this._results);

  final List<AppResult<void>> _results;
  int _callIndex = 0;
  final List<Order> savedOrders = <Order>[];

  @override
  Future<AppResult<void>> call({required Order order}) async {
    savedOrders.add(order);
    final result = _results[_callIndex.clamp(0, _results.length - 1)];
    _callIndex += 1;
    return result;
  }
}
