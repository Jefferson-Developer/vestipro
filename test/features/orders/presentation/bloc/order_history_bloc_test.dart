import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('OrderHistoryBloc', () {
    late FakeAnalyticsService analyticsService;

    setUp(() {
      analyticsService = FakeAnalyticsService();
    });

    final order = Order(
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
      status: OrderStatus.draft,
      statusHistory: <OrderStatusHistoryEntry>[
        OrderStatusHistoryEntry(
          newStatus: OrderStatus.draft,
          changedAt: DateTime.utc(2026, 6, 1),
          actorId: 'rep-1',
        ),
      ],
      createdAt: DateTime.utc(2026, 6, 1),
      createdBy: 'rep-1',
      updatedAt: DateTime.utc(2026, 6, 1),
      updatedBy: 'rep-1',
      version: 1,
      syncStatus: OrderSyncStatus.pending,
    );

    blocTest<OrderHistoryBloc, OrderHistoryState>(
      'loads a pedido whose history is only the creation entry (no '
      'transition beyond it yet)',
      build: () => OrderHistoryBloc(
        getOrderById: _FakeGetOrderByIdUseCase(AppSuccess<Order>(order)),
        analyticsService: analyticsService,
      ),
      act: (bloc) => bloc.add(
        const OrderHistoryStarted(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
          orderId: 'order-1',
        ),
      ),
      expect: () => <Matcher>[
        isA<OrderHistoryState>().having(
          (state) => state.loadStatus,
          'loadStatus',
          OrderHistoryLoadStatus.loading,
        ),
        isA<OrderHistoryState>()
            .having(
              (state) => state.loadStatus,
              'loadStatus',
              OrderHistoryLoadStatus.ready,
            )
            .having((state) => state.order?.statusHistory.length, 'entries', 1),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, hasLength(1));
        expect(
          analyticsService.loggedEvents.single.name,
          AnalyticsEvents.orderHistoryViewed,
        );
      },
    );

    blocTest<OrderHistoryBloc, OrderHistoryState>(
      'surfaces a failure state when the order cannot be loaded, without '
      'logging analytics',
      build: () => OrderHistoryBloc(
        getOrderById: _FakeGetOrderByIdUseCase(
          const AppFailure<Order>(
            NotFoundFailure('Order not found.', code: 'order_not_found'),
          ),
        ),
        analyticsService: analyticsService,
      ),
      act: (bloc) => bloc.add(
        const OrderHistoryStarted(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
          orderId: 'missing-order',
        ),
      ),
      expect: () => <Matcher>[
        isA<OrderHistoryState>().having(
          (state) => state.loadStatus,
          'loadStatus',
          OrderHistoryLoadStatus.loading,
        ),
        isA<OrderHistoryState>()
            .having(
              (state) => state.loadStatus,
              'loadStatus',
              OrderHistoryLoadStatus.failure,
            )
            .having(
              (state) => state.failure,
              'failure',
              isA<NotFoundFailure>(),
            ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, isEmpty);
      },
    );
  });
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
