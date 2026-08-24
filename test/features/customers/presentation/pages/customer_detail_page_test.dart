import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/crm/crm.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('CustomerDetailPage', () {
    late _MockMembershipRepository membershipRepository;
    late PermissionService permissionService;
    late _InMemoryCustomerRepository customerRepository;
    late _InMemoryCrmActivityRepository activityRepository;
    late FakeAnalyticsService analyticsService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      permissionService = PermissionService(membershipRepository);
      customerRepository = _InMemoryCustomerRepository()..seed(_fullCustomer);
      activityRepository = _InMemoryCrmActivityRepository();
      analyticsService = FakeAnalyticsService();
    });

    testWidgets('renders complete customer 360 data and quick actions', (
      tester,
    ) async {
      _grantRole(membershipRepository, 'SALES_MANAGER');

      await _pumpPage(
        tester,
        permissionService,
        customerRepository,
        activityRepository,
        analyticsService,
      );
      await tester.pumpAndSettle();

      expect(find.text('Atacado Alfa'), findsWidgets);
      expect(find.text('04.252.011/0001-10'), findsOneWidget);
      expect(find.text('Dados cadastrais'), findsOneWidget);
      expect(find.text('Alfa Confeccoes Ltda'), findsOneWidget);
      expect(find.text('compras@alfa.com.br'), findsWidgets);
      expect(find.text('Rua Augusta, 1000 - Sao Paulo/SP'), findsOneWidget);
      expect(find.text('Marina Souza'), findsOneWidget);
      expect(find.text('Ligar'), findsOneWidget);
      expect(find.text('Mensagem'), findsOneWidget);
      expect(find.bySemanticsLabel('Registrar atividade'), findsOneWidget);
      expect(find.text('Nenhuma atividade registrada ainda.'), findsOneWidget);
      expect(customerRepository.calls.single, ('org-1', 'customer-a'));
    });

    testWidgets('registers quick CRM activity from customer detail', (
      tester,
    ) async {
      _grantRole(membershipRepository, 'SALES_MANAGER');

      await _pumpPage(
        tester,
        permissionService,
        customerRepository,
        activityRepository,
        analyticsService,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Registrar atividade'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('register-crm-activity-sheet')),
        findsOneWidget,
      );

      await tester.enterText(
        find.bySemanticsLabel('Descricao da atividade CRM'),
        'Ligacao sobre reposicao',
      );
      await tester.tap(find.text('Registrar atividade').last);
      await tester.pumpAndSettle();

      expect(activityRepository.activities.single.customerId, 'customer-a');
      expect(activityRepository.activities.single.userId, 'rep-1');
      expect(find.text('Ligacao sobre reposicao'), findsOneWidget);
      expect(
        analyticsService.loggedEvents.where(
          (event) => event.name == AnalyticsEvents.crmActivityCreated,
        ),
        hasLength(1),
      );
    });

    testWidgets('renders partial data with explicit placeholders', (
      tester,
    ) async {
      _grantRole(membershipRepository, 'SALES_REP');
      customerRepository
        ..clear()
        ..seed(_partialCustomer);

      await _pumpPage(
        tester,
        permissionService,
        customerRepository,
        activityRepository,
        analyticsService,
        customerId: 'customer-partial',
      );
      await tester.pumpAndSettle();

      expect(find.text('Cliente Parcial'), findsWidgets);
      expect(find.text('Sem telefone'), findsOneWidget);
      expect(find.text('Sem e-mail'), findsOneWidget);
      expect(
        find.text('Nenhum endereco cadastrado para este cliente.'),
        findsOneWidget,
      );
      expect(
        find.text('Nenhum contato cadastrado para este cliente.'),
        findsOneWidget,
      );
      expect(find.text('Score do cliente em breve'), findsOneWidget);
      expect(find.text('Nenhuma atividade registrada ainda.'), findsOneWidget);
      expect(find.text('Oportunidades em breve'), findsOneWidget);
      expect(find.text('Pedidos em breve'), findsOneWidget);
      expect(find.text('Recomendacao em breve'), findsOneWidget);
    });

    testWidgets('uses mobile, tablet and desktop responsive compositions', (
      tester,
    ) async {
      _grantRole(membershipRepository, 'SALES_MANAGER');

      await tester.binding.setSurfaceSize(const Size(390, 820));
      await _pumpPage(
        tester,
        permissionService,
        customerRepository,
        activityRepository,
        analyticsService,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('customer-detail-mobile')), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(800, 900));
      await tester.pumpWidget(Container());
      await _pumpPage(
        tester,
        permissionService,
        customerRepository,
        activityRepository,
        analyticsService,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('customer-detail-tablet')), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(Container());
      await _pumpPage(
        tester,
        permissionService,
        customerRepository,
        activityRepository,
        analyticsService,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('customer-detail-desktop')), findsOneWidget);

      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets(
      'gates sensitive commercial indicators by reportViewSensitive',
      (tester) async {
        _grantRole(membershipRepository, 'SALES_REP');
        await _pumpPage(
          tester,
          permissionService,
          customerRepository,
          activityRepository,
          analyticsService,
        );
        await tester.pumpAndSettle();

        expect(find.text('Indicadores comerciais sensiveis'), findsOneWidget);
        expect(
          find.text(
            'Sem permissao para ver margem, credito ou dados financeiros.',
          ),
          findsOneWidget,
        );
        expect(find.text('Margem e credito em breve'), findsNothing);

        _grantRole(membershipRepository, 'SALES_MANAGER');
        await tester.pumpWidget(Container());
        await _pumpPage(
          tester,
          permissionService,
          customerRepository,
          activityRepository,
          analyticsService,
        );
        await tester.pumpAndSettle();

        expect(find.text('Margem e credito em breve'), findsOneWidget);
        expect(
          find.text(
            'Sem permissao para ver margem, credito ou dados financeiros.',
          ),
          findsNothing,
        );
      },
    );
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  PermissionService permissionService,
  _InMemoryCustomerRepository customerRepository,
  _InMemoryCrmActivityRepository activityRepository,
  FakeAnalyticsService analyticsService, {
  String customerId = 'customer-a',
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: CustomerDetailPage(
        organizationId: 'org-1',
        customerId: customerId,
        userId: 'rep-1',
        permissionService: permissionService,
        createBloc: () => CustomerDetailBloc(
          getCustomerById: GetCustomerByIdUseCase(customerRepository),
          listActivitiesForCustomer: ListCrmActivitiesForCustomerUseCase(
            activityRepository,
          ),
          registerActivity: RegisterCrmActivityUseCase(activityRepository),
          analyticsService: analyticsService,
        ),
      ),
    ),
  );
}

final class _InMemoryCrmActivityRepository implements CrmActivityRepository {
  final List<CrmActivity> activities = <CrmActivity>[];

  @override
  Future<AppResult<CrmActivity>> create({required CrmActivity activity}) async {
    activities.add(activity);
    return AppSuccess<CrmActivity>(activity);
  }

  @override
  Future<AppResult<CrmActivityPageResult>> listForCustomer({
    required String organizationId,
    required String customerId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  }) async {
    final visible =
        activities
            .where(
              (activity) =>
                  activity.organizationId == organizationId &&
                  activity.customerId == customerId,
            )
            .toList(growable: false)
          ..sort(
            (first, second) => second.occurredAt.compareTo(first.occurredAt),
          );
    return AppSuccess<CrmActivityPageResult>(
      CrmActivityPageResult(
        activities: visible.take(limit).toList(growable: false),
        hasMore: visible.length > limit,
        nextCursor: visible.isEmpty ? null : visible.last.id,
        isFromLocalCache: true,
      ),
    );
  }

  @override
  Future<AppResult<CrmActivityPageResult>> listForLead({
    required String organizationId,
    required String leadId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<CrmActivityPageResult>> listForOpportunity({
    required String organizationId,
    required String opportunityId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  }) {
    throw UnimplementedError();
  }
}

void _grantRole(_MockMembershipRepository repository, String roleName) {
  when(
    () => repository.getByUser(organizationId: 'org-1', userId: 'rep-1'),
  ).thenAnswer(
    (_) async => AppSuccess<Membership>(
      Membership(
        id: 'membership-1',
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

final _fullCustomer = Customer(
  id: 'customer-a',
  organizationId: 'org-1',
  companyId: 'company-1',
  type: CustomerType.legalEntity,
  document: CnpjCpf.parse('04.252.011/0001-10'),
  legalName: 'Alfa Confeccoes Ltda',
  tradeName: 'Atacado Alfa',
  stateRegistration: '110042490114',
  primaryEmail: 'compras@alfa.com.br',
  primaryPhone: '+55 11 99999-0000',
  status: CustomerStatus.active,
  classification: 'A',
  potential: 'Alto',
  segment: 'Moda feminina',
  originChannel: 'Carteira',
  responsibleSellerId: 'rep-1',
  registeredAt: DateTime.utc(2026, 1, 1),
  lastPurchaseAt: DateTime.utc(2026, 8, 10),
  addresses: <CustomerAddress>[
    CustomerAddress(
      id: 'address-1',
      type: CustomerAddressType.shipping,
      street: 'Rua Augusta',
      number: '1000',
      city: 'Sao Paulo',
      state: 'SP',
      zipCode: Cep.parse('01310-200'),
      isPrimary: true,
    ),
  ],
  contacts: <CustomerContact>[
    CustomerContact(
      id: 'contact-1',
      type: CustomerContactType.buyer,
      name: 'Marina Souza',
      role: 'Compradora',
      phone: '+55 11 98888-1111',
      email: 'compras@alfa.com.br',
      isPrimary: true,
    ),
  ],
  tags: const <String>['premium'],
  createdAt: DateTime.utc(2026, 1, 1),
  createdBy: 'rep-1',
  updatedAt: DateTime.utc(2026, 8, 1),
  updatedBy: 'rep-1',
  version: 2,
  syncStatus: CustomerSyncStatus.synced,
);

final _partialCustomer = Customer(
  id: 'customer-partial',
  organizationId: 'org-1',
  companyId: 'company-1',
  type: CustomerType.individual,
  document: CnpjCpf.parse('529.982.247-25'),
  fullName: 'Cliente Parcial',
  status: CustomerStatus.prospect,
  registeredAt: DateTime.utc(2026, 2, 1),
  createdAt: DateTime.utc(2026, 2, 1),
  createdBy: 'rep-1',
  updatedAt: DateTime.utc(2026, 2, 1),
  updatedBy: 'rep-1',
  version: 1,
  syncStatus: CustomerSyncStatus.pending,
);

final class _InMemoryCustomerRepository implements CustomerRepository {
  final Map<String, Customer> _customers = <String, Customer>{};
  final List<(String organizationId, String customerId)> calls =
      <(String, String)>[];

  void seed(Customer customer) {
    _customers[customer.id] = customer;
  }

  void clear() {
    _customers.clear();
    calls.clear();
  }

  @override
  Future<AppResult<Customer>> getById({
    required String organizationId,
    required String id,
  }) async {
    calls.add((organizationId, id));
    final customer = _customers[id];
    if (customer == null || customer.organizationId != organizationId) {
      return const AppFailure<Customer>(
        NotFoundFailure('Customer not found.', code: 'customer_not_found'),
      );
    }
    return AppSuccess<Customer>(customer);
  }

  @override
  Future<AppResult<Customer>> create({required Customer customer}) {
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
  Future<AppResult<bool>> existsByDocument({
    required String organizationId,
    required CnpjCpf document,
    String? excludingCustomerId,
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

  @override
  Future<AppResult<Customer>> update({
    required Customer customer,
    required Set<CustomerSensitiveField> sensitiveFieldsToAudit,
  }) {
    throw UnimplementedError();
  }
}
