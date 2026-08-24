import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/customers/customers.dart';

void main() {
  group('Customer', () {
    final createdAt = DateTime.utc(2026, 1, 1);
    final updatedAt = DateTime.utc(2026, 1, 2);

    Customer buildCustomer({
      String id = 'customer-1',
      String organizationId = 'org-1',
    }) {
      return Customer(
        id: id,
        organizationId: organizationId,
        companyId: 'company-1',
        type: CustomerType.legalEntity,
        document: CnpjCpf.parse('04.252.011/0001-10'),
        legalName: 'Moda Sul Confeccoes Ltda',
        tradeName: 'Moda Sul',
        primaryEmail: 'compras@modasul.test',
        primaryPhone: '+55 47 99999-0000',
        status: CustomerStatus.active,
        classification: 'tier-a',
        potential: 'high',
        segment: 'multimarcas',
        originChannel: 'field_sales',
        responsibleSellerId: 'user-1',
        registeredAt: createdAt,
        tags: const <String>['vip', 'showroom'],
        customFields: const <String, Object?>{'regionalCode': 'SC-01'},
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-2',
        version: 2,
        syncStatus: CustomerSyncStatus.synced,
      );
    }

    test('two customers with the same field values are equal', () {
      expect(buildCustomer(), buildCustomer());
    });

    test('customers with different ids are not equal', () {
      expect(
        buildCustomer(id: 'customer-1'),
        isNot(buildCustomer(id: 'customer-2')),
      );
    });

    test('customers from different organizations are not equal', () {
      expect(
        buildCustomer(organizationId: 'org-1'),
        isNot(buildCustomer(organizationId: 'org-2')),
      );
    });

    test('displayName prefers trade name for legal entities', () {
      expect(buildCustomer().displayName, 'Moda Sul');
    });
  });
}
