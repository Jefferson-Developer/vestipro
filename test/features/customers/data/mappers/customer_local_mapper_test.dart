import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/customers/data/mappers/customer_local_mapper.dart';
import 'package:vestipro/features/customers/data/mappers/customer_mapper.dart';

void main() {
  group('CustomerLocalMapper', () {
    late AppDatabase database;
    late CustomerLocalMapper mapper;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      mapper = const CustomerLocalMapper(CustomerMapper());
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'round-trips a customer with addresses, contacts, tags and custom fields '
      'through the local Drift schema',
      () async {
        final customer = _fullCustomer();

        await database.replaceCustomers(
          organizationId: customer.organizationId,
          companyId: customer.companyId,
          customerRows: <CustomersTableCompanion>[
            mapper.toCustomerRow(customer),
          ],
          addressRows: mapper.toAddressRows(customer),
          contactRows: mapper.toContactRows(customer),
        );

        final rows = await database.getCustomersForCompany(
          organizationId: customer.organizationId,
          companyId: customer.companyId,
        );
        expect(rows, hasLength(1));

        final roundTripped = mapper.fromRow(rows.single);
        expect(roundTripped, customer);
      },
    );

    test('round-trips a customer without addresses/contacts/tags', () async {
      final customer = _minimalCustomer();

      await database.replaceCustomers(
        organizationId: customer.organizationId,
        companyId: customer.companyId,
        customerRows: <CustomersTableCompanion>[mapper.toCustomerRow(customer)],
        addressRows: mapper.toAddressRows(customer),
        contactRows: mapper.toContactRows(customer),
      );

      final rows = await database.getCustomersForCompany(
        organizationId: customer.organizationId,
        companyId: customer.companyId,
      );
      final roundTripped = mapper.fromRow(rows.single);

      expect(roundTripped, customer);
      expect(roundTripped.addresses, isEmpty);
      expect(roundTripped.contacts, isEmpty);
      expect(roundTripped.tags, isEmpty);
      expect(roundTripped.customFields, isEmpty);
    });

    test('preserves address and contact list order via position', () async {
      final customer = _fullCustomer();

      await database.replaceCustomers(
        organizationId: customer.organizationId,
        companyId: customer.companyId,
        customerRows: <CustomersTableCompanion>[mapper.toCustomerRow(customer)],
        addressRows: mapper.toAddressRows(customer),
        contactRows: mapper.toContactRows(customer),
      );

      final rows = await database.getCustomersForCompany(
        organizationId: customer.organizationId,
        companyId: customer.companyId,
      );
      final roundTripped = mapper.fromRow(rows.single);

      expect(
        roundTripped.addresses.map((address) => address.id),
        customer.addresses.map((address) => address.id),
      );
      expect(
        roundTripped.contacts.map((contact) => contact.id),
        customer.contacts.map((contact) => contact.id),
      );
    });
  });
}

Customer _fullCustomer() {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: 'customer-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.legalEntity,
    document: CnpjCpf.parse('04.252.011/0001-10'),
    legalName: 'Malwee Confeccoes',
    tradeName: 'Malwee',
    stateRegistration: '123456789',
    primaryEmail: 'contato@malwee.com.br',
    primaryPhone: '47999990000',
    status: CustomerStatus.active,
    classification: 'ouro',
    potential: 'Alto',
    segment: 'moda',
    originChannel: 'indicacao',
    responsibleSellerId: 'rep-1',
    registeredAt: now,
    lastPurchaseAt: now.subtract(const Duration(days: 10)),
    commercialScore: 91,
    healthScore: 78,
    healthScoreBand: CustomerHealthScoreBand.healthy,
    scoreUpdatedAt: now.add(const Duration(hours: 3)),
    scoreFormulaVersion: customerScoringFormulaVersion,
    scoreDataCoverage: CustomerScoreDataCoverage.ordersAndCrm,
    addresses: <CustomerAddress>[
      CustomerAddress(
        id: 'address-1',
        type: CustomerAddressType.shipping,
        street: 'Rua das Colecoes',
        number: '100',
        complement: 'Sala 2',
        district: 'Centro',
        city: 'Blumenau',
        state: 'SC',
        zipCode: Cep.parse('89010-100'),
        isPrimary: true,
      ),
      CustomerAddress(
        id: 'address-2',
        type: CustomerAddressType.billing,
        street: 'Rua da Cobranca',
        city: 'Blumenau',
        state: 'SC',
        zipCode: Cep.parse('89010-200'),
      ),
    ],
    contacts: <CustomerContact>[
      CustomerContact(
        id: 'contact-1',
        type: CustomerContactType.buyer,
        name: 'Fulano de Tal',
        phone: '47988887777',
        isPrimary: true,
      ),
      CustomerContact(
        id: 'contact-2',
        type: CustomerContactType.financial,
        name: 'Fulana de Tal',
        email: 'financeiro@cliente.com.br',
      ),
    ],
    tags: const <String>['vip', 'atacado'],
    customFields: const <String, Object?>{
      'canal_preferido': 'whatsapp',
      'limite_credito': 15000,
    },
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 3,
    syncStatus: CustomerSyncStatus.synced,
  );
}

Customer _minimalCustomer() {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: 'customer-2',
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.individual,
    document: CnpjCpf.parse('529.982.247-25'),
    fullName: 'Ciclano da Silva',
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
