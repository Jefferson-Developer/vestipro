import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('CustomerFormPage', () {
    late _MockOrganizationRepository organizationRepository;
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late _InMemoryCustomerRepository customerRepository;
    late _InMemoryCustomerFormDraftRepository draftRepository;
    late PermissionService permissionService;
    late FakeAnalyticsService analyticsService;

    setUp(() {
      organizationRepository = _MockOrganizationRepository();
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      customerRepository = _InMemoryCustomerRepository();
      draftRepository = _InMemoryCustomerFormDraftRepository();
      permissionService = PermissionService(membershipRepository);
      analyticsService = FakeAnalyticsService();

      _stubOrganization(organizationRepository);
      _stubCurrentMembership(
        membershipRepository,
        roleName: SystemRoleName.owner.code,
      );
      when(() => membershipRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => AppSuccess<List<Membership>>([
          _membership(
            userId: 'rep-1',
            roleName: SystemRoleName.salesRep.code,
            name: 'Ana Souza',
          ),
        ]),
      );
      when(
        () => teamRepository.listByOrganization('org-1'),
      ).thenAnswer((_) async => const AppSuccess<List<Team>>([]));
    });

    CustomerFormBloc buildBloc() {
      return CustomerFormBloc(
        getConfig: GetCustomerFormConfigUseCase(organizationRepository),
        getDraft: GetCustomerFormDraftUseCase(draftRepository),
        saveDraft: SaveCustomerFormDraftUseCase(draftRepository),
        clearDraft: ClearCustomerFormDraftUseCase(draftRepository),
        createCustomer: CreateCustomerUseCase(customerRepository),
        updateCustomer: UpdateCustomerUseCase(customerRepository),
        listOrganizationUsers: ListOrganizationUsersUseCase(
          membershipRepository,
          teamRepository,
        ),
        analyticsService: analyticsService,
      );
    }

    Widget buildPage() {
      return CustomerFormPage(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'current-user',
        permissionService: permissionService,
        createBloc: buildBloc,
      );
    }

    testWidgets('renders legal entity fields by default', (tester) async {
      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Novo cliente'), findsOneWidget);
      expect(find.text('Pessoa jurídica'), findsOneWidget);
      expect(find.bySemanticsLabel('CNPJ'), findsWidgets);
      expect(find.bySemanticsLabel('Razão social'), findsWidgets);
      expect(find.bySemanticsLabel('Nome fantasia'), findsWidgets);
      expect(find.bySemanticsLabel('Inscrição estadual'), findsWidgets);
      expect(find.bySemanticsLabel('Nome completo'), findsNothing);
    });

    testWidgets('switches between PJ and PF fields', (tester) async {
      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pessoa física'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('CPF'), findsWidgets);
      expect(find.bySemanticsLabel('Nome completo'), findsWidgets);
      expect(find.bySemanticsLabel('Razão social'), findsNothing);
    });

    testWidgets('shows configured required field errors', (tester) async {
      _stubOrganization(
        organizationRepository,
        requiredCustomerFields: const <String>['primaryPhone'],
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();
      await _tapSaveCustomer(tester);
      await tester.pumpAndSettle();

      expect(find.text('Informe o telefone principal.'), findsOneWidget);
    });

    testWidgets('does not require optional organization fields', (
      tester,
    ) async {
      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();
      await _tapSaveCustomer(tester);
      await tester.pumpAndSettle();

      expect(find.text('Informe o telefone principal.'), findsNothing);
    });

    testWidgets('shows responsible seller when RBAC allows assignment', (
      tester,
    ) async {
      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Vendedor responsável'), findsWidgets);
    });

    testWidgets('hides responsible seller when RBAC denies assignment', (
      tester,
    ) async {
      reset(membershipRepository);
      _stubCurrentMembership(
        membershipRepository,
        roleName: SystemRoleName.salesRep.code,
      );
      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Vendedor responsável'), findsNothing);
    });

    testWidgets('exposes labels to semantics and focuses the first error', (
      tester,
    ) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        await pumpApp(tester, buildPage());
        await tester.pumpAndSettle();

        expect(
          tester
              .getSemantics(find.bySemanticsLabel('CNPJ').first)
              .flagsCollection
              .isTextField,
          isTrue,
        );

        await _tapSaveCustomer(tester);
        await tester.pumpAndSettle();

        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'customer.document',
        );
      } finally {
        semanticsHandle.dispose();
      }
    });
  });
}

Future<void> _tapSaveCustomer(WidgetTester tester) async {
  final button = find.widgetWithText(AppButton, 'Salvar cliente');
  await tester.ensureVisible(button);
  await tester.tap(button);
}

void _stubOrganization(
  _MockOrganizationRepository repository, {
  List<String> requiredCustomerFields = const <String>[],
}) {
  when(() => repository.getById('org-1')).thenAnswer(
    (_) async => AppSuccess<Organization>(
      Organization(
        id: 'org-1',
        name: 'VestiPro',
        slug: 'vestipro',
        settings: OrganizationSettings(
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
          requiredCustomerFields: requiredCustomerFields,
        ),
        status: OrganizationStatus.active,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      ),
    ),
  );
}

void _stubCurrentMembership(
  _MockMembershipRepository repository, {
  required String roleName,
}) {
  when(
    () => repository.getByUser(organizationId: 'org-1', userId: 'current-user'),
  ).thenAnswer(
    (_) async => AppSuccess<Membership>(
      _membership(userId: 'current-user', roleName: roleName),
    ),
  );
}

Membership _membership({
  required String userId,
  required String roleName,
  String name = 'Ana Souza',
}) {
  return Membership(
    id: userId,
    organizationId: 'org-1',
    userId: userId,
    roleId: roleName,
    roleName: roleName,
    status: MembershipStatus.active,
    version: 1,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'owner-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'owner-1',
    name: name,
    email: '$userId@vestipro.test',
  );
}

final class _InMemoryCustomerRepository implements CustomerRepository {
  final List<Customer> customers = <Customer>[];

  @override
  Future<AppResult<bool>> existsByDocument({
    required String organizationId,
    required CnpjCpf document,
    String? excludingCustomerId,
  }) async {
    return AppSuccess<bool>(
      customers.any(
        (customer) =>
            customer.organizationId == organizationId &&
            customer.document == document &&
            customer.id != excludingCustomerId,
      ),
    );
  }

  @override
  Future<AppResult<Customer>> create({required Customer customer}) async {
    customers.add(customer);
    return AppSuccess<Customer>(customer);
  }

  @override
  Future<AppResult<Customer>> update({
    required Customer customer,
    required Set<CustomerSensitiveField> sensitiveFieldsToAudit,
  }) async {
    return AppSuccess<Customer>(customer);
  }

  @override
  Future<AppResult<Customer>> deactivate({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) async {
    return const AppFailure<Customer>(
      NotFoundFailure('Customer not found.', code: 'customer_not_found'),
    );
  }

  @override
  Future<AppResult<Customer>> getById({
    required String organizationId,
    required String id,
  }) async {
    return const AppFailure<Customer>(
      NotFoundFailure('Customer not found.', code: 'customer_not_found'),
    );
  }
}

final class _InMemoryCustomerFormDraftRepository
    implements CustomerFormDraftRepository {
  @override
  Future<AppResult<CustomerFormDraft?>> get({
    required String organizationId,
    required String userId,
  }) async {
    return const AppSuccess<CustomerFormDraft?>(null);
  }

  @override
  Future<AppResult<void>> save(CustomerFormDraft draft) async {
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<void>> clear({
    required String organizationId,
    required String userId,
  }) async {
    return const AppSuccess<void>(null);
  }
}
