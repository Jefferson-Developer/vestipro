import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/organizations/organizations.dart';

void main() {
  group('Organization', () {
    final createdAt = DateTime.utc(2026, 1, 1);
    final updatedAt = DateTime.utc(2026, 1, 2);
    const settings = OrganizationSettings(
      currency: 'BRL',
      country: 'BR',
      defaultLanguage: 'pt-BR',
    );

    Organization buildOrganization({String id = 'org-1'}) {
      return Organization(
        id: id,
        name: 'Grupo Fashion XPTO',
        slug: 'grupo-fashion-xpto',
        settings: settings,
        status: OrganizationStatus.active,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-1',
      );
    }

    test('two organizations with the same field values are equal', () {
      expect(buildOrganization(), buildOrganization());
    });

    test('organizations with different ids are not equal', () {
      expect(
        buildOrganization(id: 'org-1'),
        isNot(buildOrganization(id: 'org-2')),
      );
    });

    test(
      'copyWith produces a new instance without mutating the original id',
      () {
        final original = buildOrganization();
        final copy = original.copyWith(name: 'Renamed');

        expect(original.id, 'org-1');
        expect(original.name, 'Grupo Fashion XPTO');
        expect(copy.id, 'org-1');
        expect(copy.name, 'Renamed');
        expect(original, isNot(copy));
      },
    );

    test('deletedAt is null by default (organization not soft-deleted)', () {
      expect(buildOrganization().deletedAt, isNull);
    });
  });
}
