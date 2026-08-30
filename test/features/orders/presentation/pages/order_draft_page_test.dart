import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/orders/orders.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('OrderDraftPage', () {
    late _MockMembershipRepository membershipRepository;
    late PermissionService permissionService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      permissionService = PermissionService(membershipRepository);
    });

    testWidgets(
      'shows the carteira picker and starts a draft once a customer is '
      'selected',
      (tester) async {
        _grantRole(membershipRepository, 'SALES_REP');
        final portfolioUseCase = _FakeListCustomerPortfolioUseCase(
          AppSuccess<CustomerPortfolioPageResult>(
            CustomerPortfolioPageResult(
              customers: <Customer>[_customer],
              hasMore: false,
            ),
          ),
        );

        await _pumpPage(
          tester,
          permissionService: permissionService,
          portfolioUseCase: portfolioUseCase,
          startOrderDraftForCustomer: _FakeStartOrderDraftForCustomerUseCase(
            AppSuccess<Order>(_order()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Carteira de clientes'), findsOneWidget);
        expect(find.text('Atacado Alfa'), findsOneWidget);

        await tester.tap(find.text('Atacado Alfa'));
        await tester.pumpAndSettle();

        expect(find.text('Resumo do pedido'), findsOneWidget);
        expect(find.text('Adicionar produtos'), findsOneWidget);
      },
    );

    testWidgets('shows the carteira empty state when no customer is visible', (
      tester,
    ) async {
      _grantRole(membershipRepository, 'SALES_MANAGER');
      final portfolioUseCase = _FakeListCustomerPortfolioUseCase(
        const AppSuccess<CustomerPortfolioPageResult>(
          CustomerPortfolioPageResult(customers: <Customer>[], hasMore: false),
        ),
      );

      await _pumpPage(
        tester,
        permissionService: permissionService,
        portfolioUseCase: portfolioUseCase,
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhum cliente na carteira'), findsOneWidget);
    });

    testWidgets('shows a clear carteira load error', (tester) async {
      _grantRole(membershipRepository, 'OWNER');
      final portfolioUseCase = _FakeListCustomerPortfolioUseCase(
        const AppFailure<CustomerPortfolioPageResult>(
          ConnectivityFailure('Offline.'),
        ),
      );

      await _pumpPage(
        tester,
        permissionService: permissionService,
        portfolioUseCase: portfolioUseCase,
      );
      await tester.pumpAndSettle();

      expect(find.text('Nao foi possivel carregar a carteira'), findsOneWidget);
    });

    testWidgets(
      'surfaces a clear error (never silent) when starting the draft fails',
      (tester) async {
        _grantRole(membershipRepository, 'SALES_REP');
        final portfolioUseCase = _FakeListCustomerPortfolioUseCase(
          AppSuccess<CustomerPortfolioPageResult>(
            CustomerPortfolioPageResult(
              customers: <Customer>[_customer],
              hasMore: false,
            ),
          ),
        );

        await _pumpPage(
          tester,
          permissionService: permissionService,
          portfolioUseCase: portfolioUseCase,
          startOrderDraftForCustomer: _FakeStartOrderDraftForCustomerUseCase(
            const AppFailure<Order>(
              PermissionFailure(
                'Customer is outside the seller\'s portfolio.',
                code: 'order_draft_customer_outside_portfolio',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Atacado Alfa'));
        await tester.pump();
        await tester.pump();

        expect(
          find.text('Customer is outside the seller\'s portfolio.'),
          findsOneWidget,
        );
        // Never silent, but also never blocks trying another customer.
        expect(find.text('Carteira de clientes'), findsOneWidget);
      },
    );

    testWidgets('shows forbidden for a seller without order.create', (
      tester,
    ) async {
      _grantRole(membershipRepository, 'SALES_ASSISTANT');
      final portfolioUseCase = _FakeListCustomerPortfolioUseCase(
        const AppSuccess<CustomerPortfolioPageResult>(
          CustomerPortfolioPageResult(customers: <Customer>[], hasMore: false),
        ),
      );

      await _pumpPage(
        tester,
        permissionService: permissionService,
        portfolioUseCase: portfolioUseCase,
      );
      await tester.pumpAndSettle();

      expect(find.byType(ForbiddenPage), findsOneWidget);
    });
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required PermissionService permissionService,
  required _FakeListCustomerPortfolioUseCase portfolioUseCase,
  _FakeStartOrderDraftForCustomerUseCase? startOrderDraftForCustomer,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: OrderDraftPage(
        organizationId: 'org-1',
        companyId: 'company-1',
        sellerId: 'rep-1',
        permissionService: permissionService,
        createBloc: () => OrderDraftBloc(
          getOrderDraft: _FakeGetOrderDraftUseCase(
            const AppSuccess<Order?>(null),
          ),
          startOrderDraftForCustomer:
              startOrderDraftForCustomer ??
              _FakeStartOrderDraftForCustomerUseCase(
                AppSuccess<Order>(_order()),
              ),
          saveOrderDraft: _FakeSaveOrderDraftUseCase(),
          analyticsService: FakeAnalyticsService(),
        ),
        createCustomerPortfolioBloc: () =>
            CustomerPortfolioBloc(listCustomerPortfolio: portfolioUseCase),
      ),
    ),
  );
}

void _grantRole(_MockMembershipRepository repository, String roleName) {
  when(
    () => repository.getByUser(organizationId: 'org-1', userId: 'rep-1'),
  ).thenAnswer(
    (_) async => AppSuccess<Membership>(
      Membership(
        id: 'rep-1',
        organizationId: 'org-1',
        userId: 'rep-1',
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

final _customer = Customer(
  id: 'customer-a',
  organizationId: 'org-1',
  companyId: 'company-1',
  type: CustomerType.legalEntity,
  document: CnpjCpf.parse('04.252.011/0001-10'),
  legalName: 'Atacado Alfa',
  status: CustomerStatus.active,
  registeredAt: DateTime.utc(2026, 1, 1),
  createdAt: DateTime.utc(2026, 1, 1),
  createdBy: 'rep-1',
  updatedAt: DateTime.utc(2026, 1, 1),
  updatedBy: 'rep-1',
  version: 1,
  syncStatus: CustomerSyncStatus.pending,
);

Order _order() {
  final now = DateTime.utc(2026, 6, 1);
  return Order(
    id: 'order-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-a',
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

final class _FakeListCustomerPortfolioUseCase
    implements ListCustomerPortfolioUseCase {
  _FakeListCustomerPortfolioUseCase(this._result);

  final AppResult<CustomerPortfolioPageResult> _result;

  @override
  Future<AppResult<CustomerPortfolioPageResult>> call({
    required String organizationId,
    required String companyId,
    required String userId,
    CustomerPortfolioFilters filters = CustomerPortfolioFilters.empty,
    String searchQuery = '',
    String? cursor,
    int limit = 20,
    DateTime? now,
  }) async {
    return _result;
  }
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
  @override
  Future<AppResult<void>> call({required Order order}) async {
    return const AppSuccess<void>(null);
  }
}
