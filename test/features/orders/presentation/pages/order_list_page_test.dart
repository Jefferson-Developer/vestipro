import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('OrderListPage', () {
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late _InMemoryOrderListRepository orderListRepository;
    late _InMemoryOrderDraftRepository orderDraftRepository;
    late PermissionService permissionService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      orderListRepository = _InMemoryOrderListRepository();
      orderDraftRepository = _InMemoryOrderDraftRepository();
      permissionService = PermissionService(membershipRepository);
    });

    OrderListBloc buildBloc() {
      return OrderListBloc(
        listOrders: ListOrdersUseCase(
          orderListRepository,
          OrderVisibilityService(
            PortfolioVisibilityService(membershipRepository, teamRepository),
            teamRepository,
          ),
          permissionService,
        ),
        listLocalPendingOrders: ListLocalPendingOrdersUseCase(
          orderDraftRepository,
        ),
      );
    }

    Widget buildPage() {
      return OrderListPage(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'owner-1',
        permissionService: permissionService,
        createBloc: buildBloc,
      );
    }

    testWidgets('renders forbidden for a role without order.view', (
      tester,
    ) async {
      _stubMembership(membershipRepository, roleName: 'SALES_ASSISTANT');

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(ForbiddenPage), findsOneWidget);
    });

    testWidgets(
      'differentiates a locally pending order from a server-confirmed one '
      'without relying on color alone (text label + icon on both)',
      (tester) async {
        _stubMembership(membershipRepository, roleName: 'OWNER');
        orderDraftRepository.seed(
          _order(
            'order-pending',
            status: OrderStatus.pendingSync,
            syncStatus: OrderSyncStatus.pending,
          ),
        );
        orderListRepository.seed(_order('order-confirmed'));

        await pumpApp(tester, buildPage());
        await tester.pumpAndSettle();

        // The locally pending order renders in its own dedicated section,
        // with a text label (not just a color) marking it as not yet synced.
        expect(find.text('Pendentes de sincronização (1)'), findsOneWidget);
        expect(find.text('Pendente de sincronização'), findsOneWidget);
        expect(find.text('Pendente de envio'), findsOneWidget);

        // The server-confirmed order renders in the main table with its own
        // business status — never mistaken for a pending one.
        expect(find.text('Enviado'), findsOneWidget);
      },
    );

    testWidgets('shows the empty state when no order matches', (tester) async {
      _stubMembership(membershipRepository, roleName: 'OWNER');

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Nenhum pedido encontrado'), findsOneWidget);
    });
  });
}

void _stubMembership(
  _MockMembershipRepository repository, {
  required String roleName,
}) {
  when(
    () => repository.getByUser(organizationId: 'org-1', userId: 'owner-1'),
  ).thenAnswer(
    (_) async => AppSuccess<Membership>(
      Membership(
        id: 'owner-1',
        organizationId: 'org-1',
        userId: 'owner-1',
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      ),
    ),
  );
}

Order _order(
  String id, {
  OrderStatus status = OrderStatus.submitted,
  OrderSyncStatus syncStatus = OrderSyncStatus.synced,
}) {
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
    status: status,
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
    version: 1,
    syncStatus: syncStatus,
  );
}

final class _InMemoryOrderListRepository implements OrderListRepository {
  final List<Order> orders = <Order>[];

  void seed(Order order) => orders.add(order);

  @override
  Future<AppResult<OrderListPageResult>> listPageByCompany({
    required String organizationId,
    required String companyId,
    int limit = 20,
    DateTime? before,
    OrderListFilters filters = OrderListFilters.empty,
  }) async {
    return AppSuccess<OrderListPageResult>(
      OrderListPageResult(orders: List<Order>.of(orders), hasMore: false),
    );
  }
}

final class _InMemoryOrderDraftRepository implements OrderDraftRepository {
  final List<Order> _localOrders = <Order>[];

  void seed(Order order) => _localOrders.add(order);

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
    return AppSuccess<List<Order>>(List<Order>.of(_localOrders));
  }
}
