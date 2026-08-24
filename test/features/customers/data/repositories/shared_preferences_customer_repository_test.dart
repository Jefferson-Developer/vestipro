import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/customers/data/mappers/customer_mapper.dart';
import 'package:vestipro/features/customers/data/repositories/shared_preferences_customer_repository.dart';

void main() {
  group('SharedPreferencesCustomerRepository', () {
    late SharedPreferencesCustomerRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = SharedPreferencesCustomerRepository(const CustomerMapper());
    });

    test('persists a locally created customer as pending sync', () async {
      final customer = _customer();

      final createResult = await repository.create(customer: customer);
      final lookupResult = await repository.getById(
        organizationId: 'org-1',
        id: 'customer-1',
      );
      final existsResult = await repository.existsByDocument(
        organizationId: 'org-1',
        document: CnpjCpf.parse('04.252.011/0001-10'),
      );

      expect(createResult, isA<AppSuccess<Customer>>());
      expect(lookupResult, isA<AppSuccess<Customer>>());
      expect(
        (lookupResult as AppSuccess<Customer>).value.syncStatus,
        CustomerSyncStatus.pending,
      );
      expect((existsResult as AppSuccess<bool>).value, isTrue);
    });

    test('blocks duplicate documents in the same organization cache', () async {
      await repository.create(customer: _customer());

      final duplicateResult = await repository.create(
        customer: _customer(id: 'customer-2'),
      );

      expect(duplicateResult, isA<AppFailure<Customer>>());
      expect(
        (duplicateResult as AppFailure<Customer>).failure,
        isA<ConflictFailure>(),
      );
    });
  });
}

Customer _customer({String id = 'customer-1'}) {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.legalEntity,
    document: CnpjCpf.parse('04.252.011/0001-10'),
    legalName: 'Moda Sul Confeccoes Ltda',
    primaryEmail: 'compras@modasul.test',
    primaryPhone: '+55 47 99999-0000',
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
