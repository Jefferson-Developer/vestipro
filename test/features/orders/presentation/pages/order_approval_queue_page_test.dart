import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
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
  group('OrderApprovalQueuePage', () {
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late _InMemoryOrderListRepository orderListRepository;
    late _InMemoryOrderApprovalRepository orderApprovalRepository;
    late PermissionService permissionService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      orderListRepository = _InMemoryOrderListRepository();
      orderApprovalRepository = _InMemoryOrderApprovalRepository();
      permissionService = PermissionService(membershipRepository);
    });

    OrderApprovalQueueBloc buildBloc() {
      final visibilityService = OrderVisibilityService(
        PortfolioVisibilityService(membershipRepository, teamRepository),
        teamRepository,
      );
      return OrderApprovalQueueBloc(
        listOrders: ListOrdersUseCase(
          orderListRepository,
          visibilityService,
          permissionService,
        ),
        decideOrderApproval: DecideOrderApprovalUseCase(
          orderApprovalRepository,
          permissionService,
          FakeAnalyticsService(),
        ),
      );
    }

    Widget buildPage() {
      return OrderApprovalQueuePage(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'owner-1',
        permissionService: permissionService,
        createBloc: buildBloc,
      );
    }

    testWidgets('renders forbidden for a role without order.approve', (
      tester,
    ) async {
      _stubMembership(membershipRepository, roleName: 'SALES_REP');

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(ForbiddenPage), findsOneWidget);
    });

    testWidgets('renders every pedido awaiting approval with its motivo do '
        'encaminhamento', (tester) async {
      _stubMembership(membershipRepository, roleName: 'OWNER');
      orderListRepository.seed(
        _order('order-1', reason: 'Desconto manual de 12.00% excede o limite.'),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('customer-1'), findsOneWidget);
      expect(
        find.text('Desconto manual de 12.00% excede o limite.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'approving a pedido calls the use case and removes it from the queue',
      (tester) async {
        _stubMembership(membershipRepository, roleName: 'OWNER');
        orderListRepository.seed(_order('order-1'));

        await pumpApp(tester, buildPage());
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Aprovar pedido'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(AppButton, 'Aprovar').last);
        await tester.pumpAndSettle();

        expect(orderApprovalRepository.lastDecision, 'approved');
        expect(orderApprovalRepository.lastOrderId, 'order-1');
        expect(find.text('customer-1'), findsNothing);
      },
    );

    testWidgets(
      'rejecting blocks an empty justification then applies a valid one',
      (tester) async {
        _stubMembership(membershipRepository, roleName: 'OWNER');
        orderListRepository.seed(_order('order-1'));

        await pumpApp(tester, buildPage());
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Rejeitar pedido'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(AppButton, 'Rejeitar').last);
        await tester.pumpAndSettle();

        expect(find.text('Informe o motivo da rejeição.'), findsOneWidget);
        expect(orderApprovalRepository.lastDecision, isNull);

        final reasonField = find
            .byWidgetPredicate(
              (widget) => widget is AppTextField && widget.label == 'Motivo',
            )
            .last;
        await tester.enterText(
          find.descendant(of: reasonField, matching: find.byType(EditableText)),
          'Desconto fora da política',
        );
        await tester.tap(find.widgetWithText(AppButton, 'Rejeitar').last);
        await tester.pumpAndSettle();

        expect(orderApprovalRepository.lastDecision, 'rejected');
        expect(orderApprovalRepository.lastReason, 'Desconto fora da política');
        expect(find.text('customer-1'), findsNothing);
      },
    );
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

Order _order(String id, {String? reason}) {
  final now = DateTime.utc(2026, 1, 1);
  return Order(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'rep-1',
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
    status: OrderStatus.underReview,
    statusHistory: <OrderStatusHistoryEntry>[
      OrderStatusHistoryEntry(
        newStatus: OrderStatus.underReview,
        changedAt: now,
        actorId: 'rep-1',
        reason: reason,
      ),
    ],
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: OrderSyncStatus.synced,
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

  @override
  Future<AppResult<Order?>> getById({
    required String organizationId,
    required String companyId,
    required String id,
  }) async {
    for (final order in orders) {
      if (order.id == id) return AppSuccess<Order?>(order);
    }
    return const AppSuccess<Order?>(null);
  }
}

final class _InMemoryOrderApprovalRepository
    implements OrderApprovalRepository {
  String? lastOrderId;
  String? lastDecision;
  String? lastReason;

  @override
  Future<AppResult<OrderApprovalDecisionResult>> decide({
    required String organizationId,
    required String companyId,
    required String orderId,
    required OrderApprovalDecisionValue decision,
    String? reason,
  }) async {
    lastOrderId = orderId;
    lastDecision = decision == OrderApprovalDecisionValue.approved
        ? 'approved'
        : 'rejected';
    lastReason = reason;
    return AppSuccess<OrderApprovalDecisionResult>(
      OrderApprovalDecisionResult(
        orderId: orderId,
        status: decision == OrderApprovalDecisionValue.approved
            ? OrderStatus.approved
            : OrderStatus.rejected,
        approverId: 'owner-1',
        decidedAt: DateTime.utc(2026, 1, 1, 12),
        reason: reason,
      ),
    );
  }
}
