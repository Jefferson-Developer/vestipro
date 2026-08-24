import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('CustomerFormBloc', () {
    late _InMemoryCustomerRepository customerRepository;
    late _InMemoryCustomerFormDraftRepository draftRepository;
    late _MockOrganizationRepository organizationRepository;
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late FakeAnalyticsService analyticsService;

    setUp(() {
      customerRepository = _InMemoryCustomerRepository();
      draftRepository = _InMemoryCustomerFormDraftRepository();
      organizationRepository = _MockOrganizationRepository();
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      analyticsService = FakeAnalyticsService();

      when(
        () => organizationRepository.getById('org-1'),
      ).thenAnswer((_) async => AppSuccess<Organization>(_organization()));
      when(() => membershipRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => AppSuccess<List<Membership>>([
          _membership(
            userId: 'rep-2',
            roleName: SystemRoleName.salesRep.code,
            name: 'Bruno Lima',
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

    Future<CustomerFormBloc> startedBloc({
      bool canChooseResponsibleSeller = false,
    }) async {
      final bloc = buildBloc()
        ..add(
          CustomerFormStarted(
            organizationId: 'org-1',
            companyId: 'company-1',
            userId: 'user-1',
            canChooseResponsibleSeller: canChooseResponsibleSeller,
          ),
        );
      await _drainBloc();
      return bloc;
    }

    test('submits a valid legal entity as pending sync', () async {
      final bloc = await startedBloc();

      bloc
        ..add(const CustomerFormDocumentChanged('04.252.011/0001-10'))
        ..add(const CustomerFormLegalNameChanged('Moda Sul Confeccoes Ltda'))
        ..add(const CustomerFormPrimaryPhoneChanged('+55 47 99999-0000'))
        ..add(const CustomerFormPrimaryEmailChanged('compras@modasul.test'))
        ..add(const CustomerFormSubmitted());
      await _drainBloc();

      expect(bloc.state.submissionStatus, CustomerFormSubmissionStatus.success);
      expect(bloc.state.savedCustomer?.syncStatus, CustomerSyncStatus.pending);
      expect(bloc.state.savedCustomer?.responsibleSellerId, 'user-1');
      expect(
        customerRepository.customers.single.document.digits,
        '04252011000110',
      );
      expect(
        analyticsService.loggedEvents.single.name,
        AnalyticsEvents.customerCreated,
      );

      await bloc.close();
    });

    test('keeps document validation immediate for invalid CPF/CNPJ', () async {
      final bloc = await startedBloc();

      bloc.add(const CustomerFormDocumentChanged('11.111.111/1111-11'));
      await _drainBloc();

      expect(bloc.state.fieldErrors['document'], 'Informe um CNPJ válido.');

      bloc.add(const CustomerFormSubmitted());
      await _drainBloc();

      expect(bloc.state.submissionStatus, CustomerFormSubmissionStatus.failure);
      expect(customerRepository.customers, isEmpty);

      await bloc.close();
    });

    test(
      'blocks duplicate documents before creating a local customer',
      () async {
        customerRepository.seed(
          _customer(document: CnpjCpf.parse('04.252.011/0001-10')),
        );
        final bloc = await startedBloc();

        bloc
          ..add(const CustomerFormDocumentChanged('04.252.011/0001-10'))
          ..add(const CustomerFormLegalNameChanged('Moda Sul Confeccoes Ltda'))
          ..add(const CustomerFormSubmitted());
        await _drainBloc();

        expect(
          bloc.state.submissionStatus,
          CustomerFormSubmissionStatus.failure,
        );
        expect(
          bloc.state.fieldErrors['document'],
          'Já existe um cliente com este documento.',
        );
        expect(customerRepository.customers, hasLength(1));

        await bloc.close();
      },
    );

    test('saves and resumes an incomplete draft', () async {
      final firstBloc = await startedBloc();

      firstBloc
        ..add(const CustomerFormDocumentChanged('04.252.011/0001-10'))
        ..add(const CustomerFormLegalNameChanged('Moda Sul Confeccoes Ltda'))
        ..add(const CustomerFormPrimaryPhoneChanged('+55 47 99999-0000'))
        ..add(
          const CustomerFormAddressAdded(
            type: CustomerAddressType.shipping,
            street: 'Rua das Colecoes',
            number: '120',
            city: 'Blumenau',
            state: 'SC',
            zipCode: '89010-100',
          ),
        )
        ..add(
          const CustomerFormContactAdded(
            type: CustomerContactType.buyer,
            name: 'Ana Compras',
            phone: '+55 47 99999-0000',
          ),
        )
        ..add(const CustomerFormDraftSaved());
      await _drainBloc();

      expect(firstBloc.state.draftStatus, CustomerFormDraftStatus.saved);
      await firstBloc.close();

      final secondBloc = await startedBloc();

      expect(secondBloc.state.hasRestoredDraft, isTrue);
      expect(secondBloc.state.document, '04.252.011/0001-10');
      expect(secondBloc.state.primaryPhone, '+55 47 99999-0000');
      expect(secondBloc.state.addresses.single.zipCode, Cep.parse('89010-100'));
      expect(secondBloc.state.contacts.single.name, 'Ana Compras');

      await secondBloc.close();
    });

    test('rejects malformed CEP before adding an address', () async {
      final bloc = await startedBloc();

      bloc.add(
        const CustomerFormAddressAdded(
          type: CustomerAddressType.shipping,
          street: 'Rua das Colecoes',
          number: '120',
          city: 'Blumenau',
          state: 'SC',
          zipCode: '123',
        ),
      );
      await _drainBloc();

      expect(bloc.state.addresses, isEmpty);
      expect(
        bloc.state.fieldErrors['address.zipCode'],
        'Informe um CEP válido.',
      );

      await bloc.close();
    });

    test(
      'requires configured fields and responsible seller when visible',
      () async {
        when(() => organizationRepository.getById('org-1')).thenAnswer(
          (_) async => AppSuccess<Organization>(
            _organization(
              requiredCustomerFields: const <String>[
                'primaryPhone',
                'responsibleSellerId',
              ],
            ),
          ),
        );
        final bloc = await startedBloc(canChooseResponsibleSeller: true);

        bloc
          ..add(const CustomerFormDocumentChanged('04.252.011/0001-10'))
          ..add(const CustomerFormLegalNameChanged('Moda Sul Confeccoes Ltda'))
          ..add(const CustomerFormSubmitted());
        await _drainBloc();

        expect(
          bloc.state.submissionStatus,
          CustomerFormSubmissionStatus.failure,
        );
        expect(
          bloc.state.fieldErrors['primaryPhone'],
          'Informe o telefone principal.',
        );
        expect(
          bloc.state.fieldErrors['responsibleSellerId'],
          'Selecione o vendedor responsável.',
        );

        await bloc.close();
      },
    );
  });
}

Future<void> _drainBloc() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Organization _organization({
  List<String> requiredCustomerFields = const <String>[],
}) {
  return Organization(
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

Customer _customer({
  String id = 'customer-existing',
  required CnpjCpf document,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.legalEntity,
    document: document,
    legalName: 'Moda Sul Confeccoes Ltda',
    status: CustomerStatus.prospect,
    registeredAt: now,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.pending,
  );
}

final class _InMemoryCustomerRepository implements CustomerRepository {
  final List<Customer> customers = <Customer>[];

  void seed(Customer customer) {
    customers.add(customer);
  }

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
    final index = customers.indexWhere((item) => item.id == customer.id);
    if (index == -1) {
      return const AppFailure<Customer>(
        NotFoundFailure('Customer not found.', code: 'customer_not_found'),
      );
    }
    customers[index] = customer;
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
    for (final customer in customers) {
      if (customer.organizationId == organizationId && customer.id == id) {
        return AppSuccess<Customer>(customer);
      }
    }
    return const AppFailure<Customer>(
      NotFoundFailure('Customer not found.', code: 'customer_not_found'),
    );
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
  }) async {
    return const AppFailure<CustomerPortfolioPageResult>(
      UnexpectedFailure(
        'Not used by CustomerFormBloc tests.',
        code: 'customer_portfolio_not_used',
      ),
    );
  }
}

final class _InMemoryCustomerFormDraftRepository
    implements CustomerFormDraftRepository {
  CustomerFormDraft? draft;

  @override
  Future<AppResult<CustomerFormDraft?>> get({
    required String organizationId,
    required String userId,
  }) async {
    final current = draft;
    if (current == null ||
        current.organizationId != organizationId ||
        current.userId != userId) {
      return const AppSuccess<CustomerFormDraft?>(null);
    }
    return AppSuccess<CustomerFormDraft?>(current);
  }

  @override
  Future<AppResult<void>> save(CustomerFormDraft draft) async {
    this.draft = draft;
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<void>> clear({
    required String organizationId,
    required String userId,
  }) async {
    draft = null;
    return const AppSuccess<void>(null);
  }
}
