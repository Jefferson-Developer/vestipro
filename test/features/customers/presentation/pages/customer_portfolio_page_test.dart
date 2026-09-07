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

    group('customer map (TASK-176)', () {
      testWidgets(
        'on mobile, shows only the list until the map toggle is tapped, and '
        'both views share the exact same filtered customers (parity)',
        (tester) async {
          _grantRole(membershipRepository, 'SALES_REP');
          final useCase = _FakeListCustomerPortfolioUseCase(
            AppSuccess<CustomerPortfolioPageResult>(
              CustomerPortfolioPageResult(
                customers: <Customer>[_customer, _customerWithoutLocation],
                hasMore: false,
              ),
            ),
          );

          await tester.binding.setSurfaceSize(const Size(390, 820));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await _pumpPage(tester, permissionService, useCase);
          await tester.pumpAndSettle();

          expect(find.text('Atacado Alfa'), findsOneWidget);
          expect(find.byType(CustomerPortfolioMapView), findsNothing);

          await tester.tap(find.byIcon(Icons.map_outlined));
          await tester.pumpAndSettle();

          expect(find.byType(CustomerPortfolioMapView), findsOneWidget);
          // Same carteira the list view showed: the customer without a
          // geocoded address does not become a pin, but still surfaces the
          // "sem localizacao" notice instead of silently disappearing.
          expect(
            find.text('1 cliente sem localizacao nao aparece no mapa.'),
            findsOneWidget,
          );
        },
      );

      testWidgets('on tablet, the list and the map render side by side without '
          'needing the toggle', (tester) async {
        _grantRole(membershipRepository, 'SALES_REP');
        final useCase = _FakeListCustomerPortfolioUseCase(
          AppSuccess<CustomerPortfolioPageResult>(
            CustomerPortfolioPageResult(
              customers: <Customer>[_customer],
              hasMore: false,
            ),
          ),
        );

        // Tablet width (< desktop's 1024, where `AppAdminPageLayout`
        // switches the filters entry point from a button to a permanent
        // side panel — unrelated to this test's scope).
        await tester.binding.setSurfaceSize(const Size(900, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await _pumpPage(tester, permissionService, useCase);
        await tester.pumpAndSettle();

        expect(find.text('Atacado Alfa'), findsOneWidget);
        expect(find.byType(CustomerPortfolioMapView), findsOneWidget);
        // No view-mode toggle to find at this breakpoint: both views are
        // always visible together.
        expect(find.byIcon(Icons.map_outlined), findsNothing);
        expect(find.byIcon(Icons.view_list_outlined), findsNothing);
      });
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
  // TASK-176: geocoded so this customer becomes a pin on the map instead of
  // being counted in the "sem localizacao" notice.
  addresses: <CustomerAddress>[
    CustomerAddress(
      id: 'address-a',
      type: CustomerAddressType.shipping,
      street: 'Rua das Colecoes',
      city: 'Blumenau',
      state: 'SC',
      zipCode: Cep.parse('89010-100'),
      isPrimary: true,
      coordinates: GeoCoordinates.validated(
        latitude: -26.9194,
        longitude: -49.0661,
      ),
      geocodingStatus: CustomerGeocodingStatus.geocoded,
      geocodedAt: DateTime.utc(2026, 1, 1),
    ),
  ],
  createdAt: DateTime.utc(2026, 1, 1),
  createdBy: 'rep-1',
  updatedAt: DateTime.utc(2026, 1, 1),
  updatedBy: 'rep-1',
  version: 1,
  syncStatus: CustomerSyncStatus.pending,
);

/// TASK-176: a second carteira customer with no geocodable/geocoded
/// address, so `CustomerPortfolioMapView` skips it as a pin while still
/// showing it in the list — used to assert the map/list parity notice.
final _customerWithoutLocation = Customer(
  id: 'customer-b',
  organizationId: 'org-1',
  companyId: 'company-1',
  type: CustomerType.individual,
  document: CnpjCpf.parse('529.982.247-25'),
  fullName: 'Atacado Beta',
  status: CustomerStatus.active,
  registeredAt: DateTime.utc(2026, 1, 1),
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
