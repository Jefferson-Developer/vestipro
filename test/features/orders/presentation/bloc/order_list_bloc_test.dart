import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('OrderListBloc', () {
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'owner-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(_membership('owner-1', 'OWNER')),
      );
    });

    ListOrdersUseCase buildListOrders(OrderListRepository repository) {
      return ListOrdersUseCase(
        repository,
        OrderVisibilityService(
          PortfolioVisibilityService(membershipRepository, teamRepository),
          teamRepository,
        ),
        PermissionService(membershipRepository),
      );
    }

    OrderListBloc buildBloc({
      required OrderListRepository repository,
      OrderDraftRepository? draftRepository,
    }) {
      return OrderListBloc(
        listOrders: buildListOrders(repository),
        listLocalPendingOrders: ListLocalPendingOrdersUseCase(
          draftRepository ?? _FakeOrderDraftRepository(const <Order>[]),
        ),
      );
    }

    blocTest<OrderListBloc, OrderListState>(
      'loads local pending orders and the first server page on start',
      build: () => buildBloc(
        repository: _FakeOrderListRepository(<AppResult<OrderListPageResult>>[
          AppSuccess<OrderListPageResult>(
            OrderListPageResult(
              orders: <Order>[_order('order-a')],
              hasMore: true,
              nextCursor: DateTime.utc(2026, 1, 1),
            ),
          ),
        ]),
        draftRepository: _FakeOrderDraftRepository(<Order>[
          _order('pending-a', syncStatus: OrderSyncStatus.pending),
        ]),
      ),
      act: (bloc) => bloc.add(
        const OrderListStarted(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'owner-1',
        ),
      ),
      expect: () => <Object>[
        isA<OrderListState>().having(
          (state) => state.loadStatus,
          'loadStatus',
          OrderListLoadStatus.loading,
        ),
        isA<OrderListState>().having(
          (state) => state.localPendingOrders.map((order) => order.id),
          'localPendingOrders',
          <String>['pending-a'],
        ),
        isA<OrderListState>()
            .having(
              (state) => state.loadStatus,
              'loadStatus',
              OrderListLoadStatus.ready,
            )
            .having(
              (state) => state.orders.map((order) => order.id),
              'orders',
              <String>['order-a'],
            )
            .having((state) => state.hasMore, 'hasMore', isTrue),
      ],
    );

    blocTest<OrderListBloc, OrderListState>(
      'applies combined status/período/cliente/vendedor filters, resetting '
      'the current page',
      build: () => buildBloc(
        repository: _FakeOrderListRepository(<AppResult<OrderListPageResult>>[
          const AppSuccess<OrderListPageResult>(
            OrderListPageResult(orders: <Order>[], hasMore: false),
          ),
        ]),
      ),
      seed: () => OrderListState(
        loadStatus: OrderListLoadStatus.ready,
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'owner-1',
        orders: <Order>[_order('stale')],
      ),
      act: (bloc) => bloc.add(
        OrderListFiltersChanged(
          OrderListFilters(
            status: OrderStatus.submitted,
            customerId: 'customer-1',
            sellerIds: const <String>{'rep-1'},
            from: DateTime.utc(2026, 1, 1),
            to: DateTime.utc(2026, 1, 31),
          ),
        ),
      ),
      expect: () => <Object>[
        isA<OrderListState>()
            .having(
              (state) => state.loadStatus,
              'loadStatus',
              OrderListLoadStatus.loading,
            )
            .having((state) => state.orders, 'orders', isEmpty),
        isA<OrderListState>()
            .having(
              (state) => state.loadStatus,
              'loadStatus',
              OrderListLoadStatus.ready,
            )
            .having(
              (state) => state.filters.status,
              'filters.status',
              OrderStatus.submitted,
            )
            .having(
              (state) => state.filters.customerId,
              'filters.customerId',
              'customer-1',
            )
            .having(
              (state) => state.filters.sellerIds,
              'filters.sellerIds',
              <String>{'rep-1'},
            ),
      ],
    );

    blocTest<OrderListBloc, OrderListState>(
      'paginates without losing already loaded orders',
      build: () => buildBloc(
        repository: _FakeOrderListRepository(<AppResult<OrderListPageResult>>[
          AppSuccess<OrderListPageResult>(
            OrderListPageResult(
              orders: <Order>[_order('order-b')],
              hasMore: false,
            ),
          ),
        ]),
      ),
      seed: () => OrderListState(
        loadStatus: OrderListLoadStatus.ready,
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'owner-1',
        orders: <Order>[_order('order-a')],
        hasMore: true,
        nextCursor: DateTime.utc(2026, 1, 1),
      ),
      act: (bloc) => bloc.add(const OrderListNextPageRequested()),
      expect: () => <Object>[
        isA<OrderListState>().having(
          (state) => state.isLoadingMore,
          'isLoadingMore',
          isTrue,
        ),
        isA<OrderListState>()
            .having(
              (state) => state.orders.map((order) => order.id),
              'orders',
              <String>['order-a', 'order-b'],
            )
            .having((state) => state.hasMore, 'hasMore', isFalse),
      ],
    );

    blocTest<OrderListBloc, OrderListState>(
      'debounces the quick search and ignores a stale, superseded edit',
      build: () => buildBloc(
        repository: _FakeOrderListRepository(<AppResult<OrderListPageResult>>[
          AppSuccess<OrderListPageResult>(
            OrderListPageResult(
              orders: <Order>[_order('order-final')],
              hasMore: false,
            ),
          ),
        ]),
      ),
      seed: () => OrderListState(
        loadStatus: OrderListLoadStatus.ready,
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'owner-1',
        orders: <Order>[_order('order-stale')],
      ),
      act: (bloc) => bloc
        ..add(const OrderListSearchChanged('000123'))
        ..add(const OrderListSearchChanged('000456')),
      wait: OrderListBloc.searchDebounce * 2,
      expect: () => <Object>[
        isA<OrderListState>().having(
          (state) => state.searchQuery,
          'searchQuery',
          '000123',
        ),
        isA<OrderListState>().having(
          (state) => state.searchQuery,
          'searchQuery',
          '000456',
        ),
        isA<OrderListState>()
            .having(
              (state) => state.loadStatus,
              'loadStatus',
              OrderListLoadStatus.loading,
            )
            .having(
              (state) => state.filters.orderNumber,
              'filters.orderNumber',
              '000456',
            ),
        isA<OrderListState>()
            .having(
              (state) => state.loadStatus,
              'loadStatus',
              OrderListLoadStatus.ready,
            )
            .having(
              (state) => state.orders.map((order) => order.id),
              'orders',
              <String>['order-final'],
            ),
      ],
    );
  });
}

Membership _membership(
  String userId,
  String roleName, {
  List<String> teamIds = const <String>[],
}) {
  return Membership(
    id: userId,
    organizationId: 'org-1',
    userId: userId,
    roleId: roleName,
    roleName: roleName,
    teamIds: teamIds,
    status: MembershipStatus.active,
    version: 1,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: userId,
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: userId,
  );
}

Order _order(String id, {OrderSyncStatus syncStatus = OrderSyncStatus.synced}) {
  final now = DateTime.utc(2026, 1, 1);
  return Order(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'owner-1',
    deliveryAddress: const OrderAddress(
      street: 'Rua A',
      city: 'Jaraguá do Sul',
      state: 'SC',
      zipCode: '89250-000',
      country: 'BR',
    ),
    billingAddress: const OrderAddress(
      street: 'Rua A',
      city: 'Jaraguá do Sul',
      state: 'SC',
      zipCode: '89250-000',
      country: 'BR',
    ),
    priceListId: 'price-list-1',
    paymentTermId: 'payment-term-1',
    status: OrderStatus.submitted,
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
    version: 1,
    syncStatus: syncStatus,
  );
}

final class _FakeOrderListRepository implements OrderListRepository {
  _FakeOrderListRepository(this._responses);

  final List<AppResult<OrderListPageResult>> _responses;
  var _callIndex = 0;

  @override
  Future<AppResult<OrderListPageResult>> listPageByCompany({
    required String organizationId,
    required String companyId,
    int limit = 20,
    DateTime? before,
    OrderListFilters filters = OrderListFilters.empty,
  }) async {
    final response = _responses[_callIndex];
    _callIndex = (_callIndex + 1).clamp(0, _responses.length - 1);
    return response;
  }

  @override
  Future<AppResult<Order?>> getById({
    required String organizationId,
    required String companyId,
    required String id,
  }) async {
    return const AppSuccess<Order?>(null);
  }
}

final class _FakeOrderDraftRepository implements OrderDraftRepository {
  _FakeOrderDraftRepository(this._localOrders);

  final List<Order> _localOrders;

  @override
  Future<AppResult<void>> saveDraft({required Order order}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Order?>> getDraftById({
    required String organizationId,
    required String companyId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<Order>>> getLocalOrdersForCompany({
    required String organizationId,
    required String companyId,
  }) async {
    return AppSuccess<List<Order>>(_localOrders);
  }
}
