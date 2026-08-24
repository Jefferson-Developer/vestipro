import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/customers/data/mappers/customer_local_mapper.dart';
import 'package:vestipro/features/customers/data/mappers/customer_mapper.dart';
import 'package:vestipro/features/customers/data/repositories/drift_customer_local_store_repository.dart';

void main() {
  group('DriftCustomerLocalStoreRepository', () {
    late AppDatabase database;
    late DriftCustomerLocalStoreRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftCustomerLocalStoreRepository(
        database,
        const CustomerLocalMapper(CustomerMapper()),
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('replaceInitialLoad stores every given customer', () async {
      final result = await repository.replaceInitialLoad(
        organizationId: 'org-1',
        companyId: 'company-1',
        customers: <Customer>[_customer('customer-1'), _customer('customer-2')],
      );

      expect(result, isA<AppSuccess<void>>());
      final countResult = await repository.count(
        organizationId: 'org-1',
        companyId: 'company-1',
      );
      expect((countResult as AppSuccess<int>).value, 2);
    });

    test(
      'replaceInitialLoad fully replaces the previous local set (no leftovers)',
      () async {
        await repository.replaceInitialLoad(
          organizationId: 'org-1',
          companyId: 'company-1',
          customers: <Customer>[
            _customer('customer-1'),
            _customer('customer-2'),
          ],
        );

        await repository.replaceInitialLoad(
          organizationId: 'org-1',
          companyId: 'company-1',
          customers: <Customer>[_customer('customer-3')],
        );

        final allResult = await repository.getAll(
          organizationId: 'org-1',
          companyId: 'company-1',
        );
        final all = (allResult as AppSuccess<List<Customer>>).value;
        expect(all.map((c) => c.id).toList(), <String>['customer-3']);
      },
    );

    test(
      'replaceInitialLoad never touches another organization/company scope',
      () async {
        await repository.replaceInitialLoad(
          organizationId: 'org-1',
          companyId: 'company-1',
          customers: <Customer>[_customer('customer-1')],
        );
        await repository.replaceInitialLoad(
          organizationId: 'org-2',
          companyId: 'company-2',
          customers: <Customer>[
            _customer(
              'customer-2',
              organizationId: 'org-2',
              companyId: 'company-2',
            ),
          ],
        );

        await repository.replaceInitialLoad(
          organizationId: 'org-1',
          companyId: 'company-1',
          customers: const <Customer>[],
        );

        final org2Result = await repository.getAll(
          organizationId: 'org-2',
          companyId: 'company-2',
        );
        expect((org2Result as AppSuccess<List<Customer>>).value, hasLength(1));
      },
    );

    test('getAll returns the addresses/contacts for each customer', () async {
      final customer = _customer('customer-1').copyWith(
        addresses: <CustomerAddress>[
          CustomerAddress(
            id: 'address-1',
            type: CustomerAddressType.shipping,
            street: 'Rua das Colecoes',
            city: 'Blumenau',
            state: 'SC',
            zipCode: Cep.parse('89010-100'),
            isPrimary: true,
          ),
        ],
      );

      await repository.replaceInitialLoad(
        organizationId: 'org-1',
        companyId: 'company-1',
        customers: <Customer>[customer],
      );

      final allResult = await repository.getAll(
        organizationId: 'org-1',
        companyId: 'company-1',
      );
      final all = (allResult as AppSuccess<List<Customer>>).value;
      expect(all.single.addresses, hasLength(1));
      expect(all.single.addresses.single.id, 'address-1');
    });
  });
}

Customer _customer(
  String id, {
  String organizationId = 'org-1',
  String companyId = 'company-1',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: id,
    organizationId: organizationId,
    companyId: companyId,
    type: CustomerType.legalEntity,
    document: CnpjCpf.parse('04.252.011/0001-10'),
    legalName: 'Customer $id',
    status: CustomerStatus.active,
    registeredAt: now,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.pending,
  );
}
