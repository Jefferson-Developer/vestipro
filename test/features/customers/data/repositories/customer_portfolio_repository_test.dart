import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/customers/data/mappers/customer_mapper.dart';
import 'package:vestipro/features/customers/data/repositories/shared_preferences_customer_repository.dart';
import 'package:vestipro/features/users/users.dart';

void main() {
  group('Customer portfolio repository', () {
    late SharedPreferencesCustomerRepository repository;
    final now = DateTime.utc(2026, 8, 24);

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = SharedPreferencesCustomerRepository(const CustomerMapper());
    });

    test(
      'scopes sales rep list by organization, company and assignment',
      () async {
        await repository.create(
          customer: _customer(
            id: 'customer-a',
            legalName: 'Atacado Alfa',
            responsibleSellerId: 'rep-1',
          ),
        );
        await repository.create(
          customer: _customer(
            id: 'customer-b',
            legalName: 'Boutique Beta',
            responsibleSellerId: 'rep-1',
          ),
        );
        await repository.create(
          customer: _customer(
            id: 'customer-c',
            legalName: 'Confeccoes Clara',
            responsibleSellerId: 'rep-2',
          ),
        );

        final result = await repository.listPortfolioPage(
          visibility: const CustomerVisibilityFilter(
            organizationId: 'org-1',
            companyId: 'company-1',
            userId: 'rep-1',
            mode: CustomerVisibilityMode.ownCustomers,
          ),
          activeAssignments: <PortfolioAssignment>[
            _assignment(customerId: 'customer-a', userId: 'rep-1'),
          ],
          filters: CustomerPortfolioFilters.empty,
          searchQuery: '',
          limit: 20,
          now: now,
        );

        expect(result, isA<AppSuccess<CustomerPortfolioPageResult>>());
        final page = (result as AppSuccess<CustomerPortfolioPageResult>).value;
        expect(page.customers.map((customer) => customer.id), ['customer-a']);
        expect(page.isFromLocalCache, isTrue);
      },
    );

    test(
      'combines search, status, UF, potential and last purchase filters',
      () async {
        await repository.create(
          customer: _customer(
            id: 'customer-a',
            legalName: 'Moda Sul',
            status: CustomerStatus.active,
            potential: 'Alto',
            state: 'SC',
            lastPurchaseAt: now.subtract(const Duration(days: 20)),
          ),
        );
        await repository.create(
          customer: _customer(
            id: 'customer-b',
            legalName: 'Moda Norte',
            status: CustomerStatus.active,
            potential: 'Baixo',
            state: 'SC',
            lastPurchaseAt: now.subtract(const Duration(days: 20)),
          ),
        );
        await repository.create(
          customer: _customer(
            id: 'customer-c',
            legalName: 'Moda Sul Filial',
            status: CustomerStatus.blocked,
            potential: 'Alto',
            state: 'PR',
            lastPurchaseAt: now.subtract(const Duration(days: 120)),
          ),
        );

        final result = await repository.listPortfolioPage(
          visibility: const CustomerVisibilityFilter(
            organizationId: 'org-1',
            companyId: 'company-1',
            userId: 'admin-1',
            mode: CustomerVisibilityMode.allOrganization,
          ),
          activeAssignments: const <PortfolioAssignment>[],
          filters: const CustomerPortfolioFilters(
            statuses: <CustomerStatus>{CustomerStatus.active},
            stateCodes: <String>{'SC'},
            potentials: <String>{'Alto'},
            lastPurchase: CustomerLastPurchaseFilter.last30Days,
          ),
          searchQuery: 'sul',
          limit: 20,
          now: now,
        );

        final page = (result as AppSuccess<CustomerPortfolioPageResult>).value;
        expect(page.customers.map((customer) => customer.id), ['customer-a']);
      },
    );

    test('paginates by cursor without losing the sorted window', () async {
      for (final item in <({String id, String name})>[
        (id: 'customer-a', name: 'Alfa'),
        (id: 'customer-b', name: 'Beta'),
        (id: 'customer-c', name: 'Clara'),
      ]) {
        await repository.create(
          customer: _customer(id: item.id, legalName: item.name),
        );
      }

      final first = await repository.listPortfolioPage(
        visibility: const CustomerVisibilityFilter(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'admin-1',
          mode: CustomerVisibilityMode.allOrganization,
        ),
        activeAssignments: const <PortfolioAssignment>[],
        filters: CustomerPortfolioFilters.empty,
        searchQuery: '',
        limit: 2,
        now: now,
      );
      final firstPage =
          (first as AppSuccess<CustomerPortfolioPageResult>).value;

      final second = await repository.listPortfolioPage(
        visibility: const CustomerVisibilityFilter(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'admin-1',
          mode: CustomerVisibilityMode.allOrganization,
        ),
        activeAssignments: const <PortfolioAssignment>[],
        filters: CustomerPortfolioFilters.empty,
        searchQuery: '',
        cursor: firstPage.nextCursor,
        limit: 2,
        now: now,
      );
      final secondPage =
          (second as AppSuccess<CustomerPortfolioPageResult>).value;

      expect(firstPage.customers.map((customer) => customer.id), [
        'customer-a',
        'customer-b',
      ]);
      expect(firstPage.hasMore, isTrue);
      expect(secondPage.customers.map((customer) => customer.id), [
        'customer-c',
      ]);
    });
  });
}

Customer _customer({
  required String id,
  required String legalName,
  String responsibleSellerId = 'rep-1',
  CustomerStatus status = CustomerStatus.active,
  String potential = 'Alto',
  String state = 'SC',
  DateTime? lastPurchaseAt,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.legalEntity,
    document: CnpjCpf.parse(_documentFor(id)),
    legalName: legalName,
    status: status,
    potential: potential,
    responsibleSellerId: responsibleSellerId,
    registeredAt: now,
    lastPurchaseAt: lastPurchaseAt,
    addresses: <CustomerAddress>[
      CustomerAddress(
        id: 'address-$id',
        type: CustomerAddressType.shipping,
        street: 'Rua das Colecoes',
        city: 'Blumenau',
        state: state,
        zipCode: Cep.parse('89010-100'),
        isPrimary: true,
      ),
    ],
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.pending,
  );
}

String _documentFor(String id) {
  return switch (id) {
    'customer-a' => '04.252.011/0001-10',
    'customer-b' => '11.222.333/0001-81',
    'customer-c' => '22.333.444/0001-81',
    _ => '33.444.555/0001-81',
  };
}

PortfolioAssignment _assignment({
  required String customerId,
  required String userId,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return PortfolioAssignment(
    id: 'assignment-$customerId',
    organizationId: 'org-1',
    companyId: 'company-1',
    userId: userId,
    teamId: 'team-1',
    scope: PortfolioAssignmentScope.customer(customerId),
    status: PortfolioAssignmentStatus.active,
    version: 1,
    createdAt: now,
    createdBy: 'manager-1',
    updatedAt: now,
    updatedBy: 'manager-1',
  );
}
