import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('ResolveOrderDraftDefaultsUseCase', () {
    final now = DateTime.utc(2026, 6, 1);

    test('resolves the first active branch, the highest-priority applicable '
        'price list and a compatible payment term', () async {
      final useCase = _buildUseCase(
        branches: <Branch>[
          _branch(id: 'branch-b', name: 'Loja B'),
          _branch(id: 'branch-a', name: 'Loja A'),
        ],
        priceLists: <PriceList>[
          _priceList(id: 'price-list-company', priority: 0),
          _priceList(
            id: 'price-list-segment',
            priority: 10,
            scope: PriceListScopeType.segment,
            scopeValue: 'premium',
          ),
        ],
        paymentTerms: <PaymentTerm>[
          _paymentTerm(
            id: 'term-1',
            priceListIds: <String>['price-list-segment'],
          ),
        ],
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        customer: _customer(segment: 'premium'),
        now: now,
      );

      expect(result, isA<AppSuccess<OrderDraftDefaults>>());
      final defaults = (result as AppSuccess<OrderDraftDefaults>).value;
      expect(defaults.branch.id, 'branch-a');
      expect(defaults.priceList.id, 'price-list-segment');
      expect(defaults.paymentTerm.id, 'term-1');
    });

    test('fails when the company has no active branch', () async {
      final useCase = _buildUseCase(
        branches: <Branch>[
          _branch(id: 'branch-a', status: BranchStatus.suspended),
        ],
        priceLists: <PriceList>[_priceList(id: 'price-list-1')],
        paymentTerms: <PaymentTerm>[_paymentTerm(id: 'term-1')],
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        customer: _customer(),
        now: now,
      );

      expect(result, isA<AppFailure<OrderDraftDefaults>>());
      expect(
        (result as AppFailure<OrderDraftDefaults>).failure.code,
        'order_draft_no_active_branch',
      );
    });

    test(
      'fails when no price list is applicable for this customer now',
      () async {
        final useCase = _buildUseCase(
          branches: <Branch>[_branch(id: 'branch-a')],
          priceLists: <PriceList>[
            _priceList(
              id: 'price-list-segment',
              scope: PriceListScopeType.segment,
              scopeValue: 'atacado',
            ),
          ],
          paymentTerms: <PaymentTerm>[_paymentTerm(id: 'term-1')],
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          customer: _customer(segment: 'varejo'),
          now: now,
        );

        expect(result, isA<AppFailure<OrderDraftDefaults>>());
        expect(
          (result as AppFailure<OrderDraftDefaults>).failure.code,
          'order_draft_no_applicable_price_list',
        );
      },
    );

    test(
      'fails when no active payment term is compatible with the resolved price list',
      () async {
        final useCase = _buildUseCase(
          branches: <Branch>[_branch(id: 'branch-a')],
          priceLists: <PriceList>[_priceList(id: 'price-list-1')],
          paymentTerms: <PaymentTerm>[
            _paymentTerm(
              id: 'term-1',
              priceListIds: <String>['price-list-other'],
            ),
          ],
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          customer: _customer(),
          now: now,
        );

        expect(result, isA<AppFailure<OrderDraftDefaults>>());
        expect(
          (result as AppFailure<OrderDraftDefaults>).failure.code,
          'order_draft_no_compatible_payment_term',
        );
      },
    );

    test('propagates a branch listing failure', () async {
      final useCase = ResolveOrderDraftDefaultsUseCase(
        ListBranchesByCompanyUseCase(
          _FakeBranchRepository(failure: const ConnectivityFailure('offline')),
        ),
        ResolveApplicablePriceListsUseCase(
          _FakePriceListRepository(<PriceList>[_priceList(id: 'price-list-1')]),
        ),
        ListActivePaymentTermsUseCase(
          _FakePaymentTermRepository(<PaymentTerm>[_paymentTerm(id: 'term-1')]),
        ),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        customer: _customer(),
        now: now,
      );

      expect(result, isA<AppFailure<OrderDraftDefaults>>());
      expect(
        (result as AppFailure<OrderDraftDefaults>).failure,
        isA<ConnectivityFailure>(),
      );
    });
  });
}

ResolveOrderDraftDefaultsUseCase _buildUseCase({
  required List<Branch> branches,
  required List<PriceList> priceLists,
  required List<PaymentTerm> paymentTerms,
}) {
  return ResolveOrderDraftDefaultsUseCase(
    ListBranchesByCompanyUseCase(_FakeBranchRepository(branches: branches)),
    ResolveApplicablePriceListsUseCase(_FakePriceListRepository(priceLists)),
    ListActivePaymentTermsUseCase(_FakePaymentTermRepository(paymentTerms)),
  );
}

Customer _customer({String? segment, String? originChannel}) {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: 'customer-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.individual,
    document: CnpjCpf.parse('529.982.247-25'),
    fullName: 'Ciclano da Silva',
    status: CustomerStatus.active,
    segment: segment,
    originChannel: originChannel,
    registeredAt: now,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.pending,
  );
}

Branch _branch({
  required String id,
  String? name,
  BranchStatus status = BranchStatus.active,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Branch(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    name: name ?? id,
    type: BranchType.store,
    status: status,
    version: 1,
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
  );
}

PriceList _priceList({
  required String id,
  int priority = 0,
  PriceListScopeType scope = PriceListScopeType.company,
  String? scopeValue,
  PriceListStatus status = PriceListStatus.active,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return PriceList(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    name: id,
    currency: 'BRL',
    validFrom: now.subtract(const Duration(days: 30)),
    status: status,
    scope: scope,
    scopeValue: scopeValue,
    priority: priority,
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
    version: 1,
    syncStatus: PriceListSyncStatus.synced,
  );
}

PaymentTerm _paymentTerm({
  required String id,
  List<String> priceListIds = const <String>[],
}) {
  final now = DateTime.utc(2026, 1, 1);
  return PaymentTerm(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    name: id,
    installments: const <PaymentInstallment>[
      PaymentInstallment(percentage: 100, dueInDays: 30),
    ],
    averageTermDays: 30,
    status: PaymentTermStatus.active,
    priceListIds: priceListIds,
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
  );
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
