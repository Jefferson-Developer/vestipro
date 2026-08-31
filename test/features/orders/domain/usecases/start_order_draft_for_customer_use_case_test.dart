import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/pricing/pricing.dart';
import 'package:vestipro/features/users/users.dart';

void main() {
  group('StartOrderDraftForCustomerUseCase', () {
    final now = DateTime.utc(2026, 6, 1);

    test(
      'starts and persists a draft pre-filled from the resolved customer/defaults',
      () async {
        final orderDraftRepository = _FakeOrderDraftRepository();
        final useCase = _buildUseCase(
          customerRepository: _FakeCustomerRepository(
            _customer(
              addresses: <CustomerAddress>[
                _address(
                  id: 'address-shipping',
                  type: CustomerAddressType.shipping,
                  isPrimary: true,
                ),
                _address(
                  id: 'address-billing',
                  type: CustomerAddressType.billing,
                  isPrimary: true,
                ),
              ],
            ),
          ),
          orderDraftRepository: orderDraftRepository,
        );

        final result = await useCase(
          id: 'order-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          sellerId: 'seller-1',
          customerId: 'customer-1',
          now: now,
        );

        expect(result, isA<AppSuccess<Order>>());
        final order = (result as AppSuccess<Order>).value;
        expect(order.id, 'order-1');
        expect(order.customerId, 'customer-1');
        expect(order.sellerId, 'seller-1');
        expect(order.branchId, 'branch-1');
        expect(order.priceListId, 'price-list-1');
        expect(order.paymentTermId, 'term-1');
        expect(order.status, OrderStatus.draft);
        expect(order.syncStatus, OrderSyncStatus.pending);
        expect(order.statusHistory, hasLength(1));
        expect(order.statusHistory.single.previousStatus, isNull);
        expect(order.statusHistory.single.newStatus, OrderStatus.draft);
        expect(order.deliveryAddress.street, 'Rua Shipping');
        expect(order.billingAddress.street, 'Rua Billing');
        expect(orderDraftRepository.savedOrders, hasLength(1));
        expect(orderDraftRepository.savedOrders.single.id, 'order-1');
      },
    );

    test(
      'falls back to an empty order address when the customer has none registered',
      () async {
        final useCase = _buildUseCase(
          customerRepository: _FakeCustomerRepository(
            _customer(addresses: const <CustomerAddress>[]),
          ),
        );

        final result = await useCase(
          id: 'order-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          sellerId: 'seller-1',
          customerId: 'customer-1',
          now: now,
        );

        expect(result, isA<AppSuccess<Order>>());
        final order = (result as AppSuccess<Order>).value;
        expect(order.deliveryAddress.street, isEmpty);
        expect(order.billingAddress.street, isEmpty);
      },
    );

    test(
      'denies starting a draft for a customer outside the seller\'s portfolio '
      'without ever loading the customer or persisting anything',
      () async {
        final customerRepository = _FakeCustomerRepository(_customer());
        final orderDraftRepository = _FakeOrderDraftRepository();
        final useCase = _buildUseCase(
          customerRepository: customerRepository,
          ensureCustomerInSellerPortfolio:
              _deniedEnsureCustomerInSellerPortfolio(),
          orderDraftRepository: orderDraftRepository,
        );

        final result = await useCase(
          id: 'order-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          sellerId: 'seller-1',
          customerId: 'customer-outside-portfolio',
          now: now,
        );

        expect(result, isA<AppFailure<Order>>());
        expect(
          (result as AppFailure<Order>).failure.code,
          'order_draft_customer_outside_portfolio',
        );
        expect(customerRepository.getByIdCalls, isEmpty);
        expect(orderDraftRepository.savedOrders, isEmpty);
      },
    );

    test(
      'denies a customer that does not belong to the active company',
      () async {
        final useCase = _buildUseCase(
          customerRepository: _FakeCustomerRepository(
            _customer(companyId: 'company-other'),
          ),
        );

        final result = await useCase(
          id: 'order-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          sellerId: 'seller-1',
          customerId: 'customer-1',
          now: now,
        );

        expect(result, isA<AppFailure<Order>>());
        expect(
          (result as AppFailure<Order>).failure.code,
          'order_draft_customer_outside_company',
        );
      },
    );

    test('propagates a defaults resolution failure', () async {
      final useCase = _buildUseCase(
        customerRepository: _FakeCustomerRepository(_customer()),
        resolveDefaults: _resolveDefaultsUseCase(
          failure: const ValidationFailure(
            'No applicable price list.',
            code: 'order_draft_no_applicable_price_list',
          ),
        ),
      );

      final result = await useCase(
        id: 'order-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        sellerId: 'seller-1',
        customerId: 'customer-1',
        now: now,
      );

      expect(result, isA<AppFailure<Order>>());
      expect(
        (result as AppFailure<Order>).failure.code,
        'order_draft_no_applicable_price_list',
      );
    });

    test('propagates a local persistence failure', () async {
      final useCase = _buildUseCase(
        customerRepository: _FakeCustomerRepository(_customer()),
        orderDraftRepository: _FakeOrderDraftRepository(
          saveFailure: const UnexpectedFailure('disk full'),
        ),
      );

      final result = await useCase(
        id: 'order-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        sellerId: 'seller-1',
        customerId: 'customer-1',
        now: now,
      );

      expect(result, isA<AppFailure<Order>>());
      expect((result as AppFailure<Order>).failure, isA<UnexpectedFailure>());
    });

    test('rejects blank required fields', () async {
      final useCase = _buildUseCase(
        customerRepository: _FakeCustomerRepository(_customer()),
      );

      final result = await useCase(
        id: '',
        organizationId: '',
        companyId: 'company-1',
        sellerId: 'seller-1',
        customerId: 'customer-1',
        now: now,
      );

      expect(result, isA<AppFailure<Order>>());
      final failure = (result as AppFailure<Order>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>['id', 'organizationId']),
      );
    });
  });
}

StartOrderDraftForCustomerUseCase _buildUseCase({
  required _FakeCustomerRepository customerRepository,
  EnsureCustomerInSellerPortfolioUseCase? ensureCustomerInSellerPortfolio,
  ResolveOrderDraftDefaultsUseCase? resolveDefaults,
  _FakeOrderDraftRepository? orderDraftRepository,
}) {
  return StartOrderDraftForCustomerUseCase(
    ensureCustomerInSellerPortfolio ??
        _allowedEnsureCustomerInSellerPortfolio(),
    GetCustomerByIdUseCase(customerRepository),
    resolveDefaults ?? _resolveDefaultsUseCase(),
    orderDraftRepository ?? _FakeOrderDraftRepository(),
  );
}

Customer _customer({
  String companyId = 'company-1',
  List<CustomerAddress> addresses = const <CustomerAddress>[],
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: 'customer-1',
    organizationId: 'org-1',
    companyId: companyId,
    type: CustomerType.individual,
    document: CnpjCpf.parse('529.982.247-25'),
    fullName: 'Ciclano da Silva',
    status: CustomerStatus.active,
    addresses: addresses,
    registeredAt: now,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.pending,
  );
}

CustomerAddress _address({
  required String id,
  required CustomerAddressType type,
  bool isPrimary = false,
}) {
  return CustomerAddress(
    id: id,
    type: type,
    street: type == CustomerAddressType.shipping
        ? 'Rua Shipping'
        : 'Rua Billing',
    city: 'Blumenau',
    state: 'SC',
    zipCode: Cep.parse('89010-000'),
    isPrimary: isPrimary,
  );
}

OrderDraftDefaults _defaults() {
  final now = DateTime.utc(2026, 1, 1);
  return OrderDraftDefaults(
    branch: Branch(
      id: 'branch-1',
      organizationId: 'org-1',
      companyId: 'company-1',
      name: 'Loja 1',
      type: BranchType.store,
      status: BranchStatus.active,
      version: 1,
      createdAt: now,
      createdBy: 'owner-1',
      updatedAt: now,
      updatedBy: 'owner-1',
    ),
    priceList: PriceList(
      id: 'price-list-1',
      organizationId: 'org-1',
      companyId: 'company-1',
      name: 'Tabela padrão',
      currency: 'BRL',
      validFrom: now,
      status: PriceListStatus.active,
      scope: PriceListScopeType.company,
      createdAt: now,
      createdBy: 'owner-1',
      updatedAt: now,
      updatedBy: 'owner-1',
      version: 1,
      syncStatus: PriceListSyncStatus.synced,
    ),
    paymentTerm: PaymentTerm(
      id: 'term-1',
      organizationId: 'org-1',
      companyId: 'company-1',
      name: 'À vista',
      installments: const <PaymentInstallment>[
        PaymentInstallment(percentage: 100, dueInDays: 0),
      ],
      averageTermDays: 0,
      status: PaymentTermStatus.active,
      createdAt: now,
      createdBy: 'owner-1',
      updatedAt: now,
      updatedBy: 'owner-1',
    ),
  );
}

/// `EnsureCustomerInSellerPortfolioUseCase`/`ResolveOrderDraftDefaultsUseCase`
/// are `final class`es (not interfaces), so they cannot be faked through
/// `implements` from outside their library — these tests instead compose the
/// real use case with fake underlying repositories, same approach
/// `ListCustomerPortfolioUseCase`'s own tests already use for
/// `PortfolioVisibilityService`.
EnsureCustomerInSellerPortfolioUseCase
_allowedEnsureCustomerInSellerPortfolio() {
  return EnsureCustomerInSellerPortfolioUseCase(
    PortfolioVisibilityService(
      _FakeMembershipRepository(_membership('ADMIN')),
      const _FakeTeamRepository(),
    ),
    _FakePortfolioAssignmentRepository(),
  );
}

EnsureCustomerInSellerPortfolioUseCase
_deniedEnsureCustomerInSellerPortfolio() {
  return EnsureCustomerInSellerPortfolioUseCase(
    PortfolioVisibilityService(
      _FakeMembershipRepository(_membership('SALES_ASSISTANT')),
      const _FakeTeamRepository(),
    ),
    _FakePortfolioAssignmentRepository(),
  );
}

ResolveOrderDraftDefaultsUseCase _resolveDefaultsUseCase({Failure? failure}) {
  return ResolveOrderDraftDefaultsUseCase(
    ListBranchesByCompanyUseCase(
      _FakeBranchRepository(
        failure: failure,
        branches: <Branch>[_defaults().branch],
      ),
    ),
    ResolveApplicablePriceListsUseCase(
      _FakePriceListRepository(<PriceList>[_defaults().priceList]),
    ),
    ListActivePaymentTermsUseCase(
      _FakePaymentTermRepository(<PaymentTerm>[_defaults().paymentTerm]),
    ),
  );
}

Membership _membership(String roleName) {
  final now = DateTime.utc(2026, 1, 1);
  return Membership(
    id: 'seller-1',
    organizationId: 'org-1',
    userId: 'seller-1',
    roleId: roleName,
    roleName: roleName,
    status: MembershipStatus.active,
    version: 1,
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
  );
}

final class _FakeMembershipRepository implements MembershipRepository {
  const _FakeMembershipRepository(this.membership);

  final Membership membership;

  @override
  Future<AppResult<Membership>> getByUser({
    required String organizationId,
    required String userId,
  }) async {
    return AppSuccess<Membership>(membership);
  }

  @override
  Future<AppResult<Membership>> create({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    List<String> teamIds = const <String>[],
    required String createdBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<Membership>>> listByOrganization(
    String organizationId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<Membership>>> listActiveByUser(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Membership>> update({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    required List<String> teamIds,
    required MembershipStatus status,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }
}

final class _FakeTeamRepository implements TeamRepository {
  const _FakeTeamRepository();

  @override
  Future<AppResult<List<Team>>> listByOrganization(
    String organizationId,
  ) async {
    return const AppSuccess<List<Team>>(<Team>[]);
  }

  @override
  Future<AppResult<Team>> addMember({
    required String organizationId,
    required String id,
    required String userId,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<bool>> hasCommercialLinks({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Team>> create({
    required String id,
    required String organizationId,
    required String name,
    required String managerUserId,
    List<String> memberIds = const <String>[],
    String? companyId,
    String? branchId,
    required String createdBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Team>> delete({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Team>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Team>> removeMember({
    required String organizationId,
    required String id,
    required String userId,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Team>> update({
    required String organizationId,
    required String id,
    required String name,
    required String managerUserId,
    required List<String> memberIds,
    String? companyId,
    String? branchId,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }
}

final class _FakePortfolioAssignmentRepository
    implements PortfolioAssignmentRepository {
  @override
  Future<AppResult<PortfolioAssignment?>> findActiveCustomerAssignment({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) async {
    return const AppSuccess<PortfolioAssignment?>(null);
  }

  @override
  Future<AppResult<List<PortfolioAssignment>>> listActiveByOrganization({
    required String organizationId,
    required String companyId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<PortfolioAssignment>>> listActiveByUser({
    required String organizationId,
    required String companyId,
    required String userId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PortfolioAssignment>> create(
    PortfolioAssignment assignment,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PortfolioAssignment>> endAssignment({
    required String organizationId,
    required String id,
    required PortfolioAssignmentStatus status,
    required DateTime endedAt,
    required String endedBy,
  }) {
    throw UnimplementedError();
  }
}

final class _FakeBranchRepository implements BranchRepository {
  _FakeBranchRepository({this.branches = const <Branch>[], this.failure});

  final List<Branch> branches;
  final Failure? failure;

  @override
  Future<AppResult<List<Branch>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    final currentFailure = failure;
    if (currentFailure != null) return AppFailure<List<Branch>>(currentFailure);
    return AppSuccess<List<Branch>>(branches);
  }

  @override
  Future<AppResult<Branch>> create({
    required String id,
    required String organizationId,
    required String companyId,
    required String name,
    required BranchType type,
    BranchAddress? address,
    required String createdBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Branch>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Branch>> update({
    required String organizationId,
    required String id,
    required String name,
    required BranchType type,
    BranchAddress? address,
    required BranchStatus status,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }
}

final class _FakePriceListRepository implements PriceListRepository {
  const _FakePriceListRepository(this.priceLists);

  final List<PriceList> priceLists;

  @override
  Future<AppResult<List<PriceList>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    return AppSuccess<List<PriceList>>(priceLists);
  }

  @override
  Future<AppResult<PriceList>> create({required PriceList priceList}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PriceList>> update({required PriceList priceList}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PriceList?>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }
}

final class _FakePaymentTermRepository implements PaymentTermRepository {
  const _FakePaymentTermRepository(this.paymentTerms);

  final List<PaymentTerm> paymentTerms;

  @override
  Future<AppResult<List<PaymentTerm>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    return AppSuccess<List<PaymentTerm>>(paymentTerms);
  }

  @override
  Future<AppResult<PaymentTerm>> create({required PaymentTerm paymentTerm}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PaymentTerm>> update({required PaymentTerm paymentTerm}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PaymentTerm?>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }
}

final class _FakeOrderDraftRepository implements OrderDraftRepository {
  _FakeOrderDraftRepository({this.saveFailure});

  final Failure? saveFailure;
  final List<Order> savedOrders = <Order>[];

  @override
  Future<AppResult<void>> saveDraft({required Order order}) async {
    final failure = saveFailure;
    if (failure != null) return AppFailure<void>(failure);
    savedOrders.add(order);
    return const AppSuccess<void>(null);
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
  }) {
    throw UnimplementedError();
  }
}

final class _FakeCustomerRepository implements CustomerRepository {
  _FakeCustomerRepository(this.customer);

  final Customer customer;
  final List<String> getByIdCalls = <String>[];

  @override
  Future<AppResult<Customer>> getById({
    required String organizationId,
    required String id,
  }) async {
    getByIdCalls.add(id);
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
  Future<AppResult<Customer>> update({
    required Customer customer,
    required Set<CustomerSensitiveField> sensitiveFieldsToAudit,
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
}
