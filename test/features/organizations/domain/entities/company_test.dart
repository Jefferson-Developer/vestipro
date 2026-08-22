import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/organizations/organizations.dart';

void main() {
  group('Company', () {
    final createdAt = DateTime.utc(2026, 1, 1);
    final updatedAt = DateTime.utc(2026, 1, 2);

    Company buildCompany({
      String id = 'company-1',
      String organizationId = 'org-1',
    }) {
      return Company(
        id: id,
        organizationId: organizationId,
        name: 'Marca A',
        legalName: 'Marca A Confecções Ltda',
        taxId: '12.345.678/0001-90',
        status: CompanyStatus.active,
        version: 1,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-1',
      );
    }

    test('two companies with the same field values are equal', () {
      expect(buildCompany(), buildCompany());
    });

    test('companies with different ids are not equal', () {
      expect(
        buildCompany(id: 'company-1'),
        isNot(buildCompany(id: 'company-2')),
      );
    });

    test('companies from different organizations are not equal even with the '
        'same id', () {
      expect(
        buildCompany(organizationId: 'org-1'),
        isNot(buildCompany(organizationId: 'org-2')),
      );
    });

    test('copyWith produces a new instance without mutating the original '
        'organizationId', () {
      final original = buildCompany();
      final copy = original.copyWith(name: 'Marca A Renomeada');

      expect(original.organizationId, 'org-1');
      expect(original.name, 'Marca A');
      expect(copy.organizationId, 'org-1');
      expect(copy.name, 'Marca A Renomeada');
      expect(original, isNot(copy));
    });

    test('legalName and taxId default to null', () {
      final company = Company(
        id: 'company-2',
        organizationId: 'org-1',
        name: 'Marca B',
        status: CompanyStatus.active,
        version: 1,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: createdAt,
        updatedBy: 'user-1',
      );

      expect(company.legalName, isNull);
      expect(company.taxId, isNull);
    });

    test('deletedAt is null by default (company not soft-deleted)', () {
      expect(buildCompany().deletedAt, isNull);
    });

    test('supports multiple companies under the same organization', () {
      final companyA = buildCompany(id: 'company-a');
      final companyB = buildCompany(id: 'company-b');

      expect(companyA.organizationId, companyB.organizationId);
      expect(companyA, isNot(companyB));
    });
  });
}
