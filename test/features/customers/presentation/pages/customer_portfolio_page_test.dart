import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('CustomerPortfolioPage', () {
    late _MockMembershipRepository membershipRepository;
    late PermissionService permissionService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      permissionService = PermissionService(membershipRepository);
    });

    testWidgets('renders a local-cache portfolio list for a SALES_REP', (
      tester,
    ) async {
      _grantRole(membershipRepository, 'SALES_REP');
      final useCase = _FakeListCustomerPortfolioUseCase(
        AppSuccess<CustomerPortfolioPageResult>(
          CustomerPortfolioPageResult(
            customers: <Customer>[_customer],
            hasMore: false,
            isFromLocalCache: true,
          ),
        ),
      );

      await _pumpPage(tester, permissionService, useCase);
      await tester.pumpAndSettle();

      expect(find.text('Carteira de clientes'), findsOneWidget);
      expect(find.text('Atacado Alfa'), findsOneWidget);
      expect(find.text('04.252.011/0001-10'), findsOneWidget);
      expect(find.text('Exibindo dados locais da carteira.'), findsOneWidget);
      expect(useCase.calls.single.userId, 'rep-1');
    });

    testWidgets('shows the empty state when no customer is visible', (
      tester,
    ) async {
      _grantRole(membershipRepository, 'SALES_MANAGER');
      final useCase = _FakeListCustomerPortfolioUseCase(
        const AppSuccess<CustomerPortfolioPageResult>(
          CustomerPortfolioPageResult(customers: <Customer>[], hasMore: false),
        ),
      );

      await _pumpPage(tester, permissionService, useCase);
      await tester.pumpAndSettle();

      expect(find.text('Nenhum cliente na carteira'), findsOneWidget);
    });

    testWidgets('shows a clear load error', (tester) async {
      _grantRole(membershipRepository, 'OWNER');
      final useCase = _FakeListCustomerPortfolioUseCase(
        const AppFailure<CustomerPortfolioPageResult>(
          ConnectivityFailure('Offline.'),
        ),
      );

      await _pumpPage(tester, permissionService, useCase);
      await tester.pumpAndSettle();

      expect(find.text('Nao foi possivel carregar a carteira'), findsOneWidget);
      expect(find.text('Offline.'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('shows forbidden for users without customer.view', (
      tester,
    ) async {
      _grantRole(membershipRepository, 'SALES_ASSISTANT');
      final useCase = _FakeListCustomerPortfolioUseCase(
        const AppSuccess<CustomerPortfolioPageResult>(
          CustomerPortfolioPageResult(customers: <Customer>[], hasMore: false),
        ),
      );

      await _pumpPage(tester, permissionService, useCase);
      await tester.pumpAndSettle();

      expect(find.byType(ForbiddenPage), findsOneWidget);
      expect(useCase.calls, isEmpty);
    });
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  PermissionService permissionService,
  _FakeListCustomerPortfolioUseCase useCase,
) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: CustomerPortfolioPage(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        permissionService: permissionService,
        createBloc: () => CustomerPortfolioBloc(listCustomerPortfolio: useCase),
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
  potential: 'Alto',
  registeredAt: DateTime.utc(2026, 1, 1),
  lastPurchaseAt: DateTime.utc(2026, 8, 10),
  createdAt: DateTime.utc(2026, 1, 1),
  createdBy: 'rep-1',
  updatedAt: DateTime.utc(2026, 1, 1),
  updatedBy: 'rep-1',
  version: 1,
  syncStatus: CustomerSyncStatus.pending,
);

final class _FakeListCustomerPortfolioUseCase
    implements ListCustomerPortfolioUseCase {
  _FakeListCustomerPortfolioUseCase(this._result);

  final AppResult<CustomerPortfolioPageResult> _result;
  final List<_PortfolioCall> calls = <_PortfolioCall>[];

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
    calls.add(
      _PortfolioCall(
        organizationId: organizationId,
        companyId: companyId,
        userId: userId,
      ),
    );
    return _result;
  }
}

final class _PortfolioCall {
  const _PortfolioCall({
    required this.organizationId,
    required this.companyId,
    required this.userId,
  });

  final String organizationId;
  final String companyId;
  final String userId;
}
