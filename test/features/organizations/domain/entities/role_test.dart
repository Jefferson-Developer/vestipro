import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/organizations/organizations.dart';

void main() {
  group('Role', () {
    final createdAt = DateTime.utc(2026, 1, 1);
    final updatedAt = DateTime.utc(2026, 1, 2);

    Role buildRole({
      String id = 'OWNER',
      String organizationId = 'org-1',
      bool isSystemRole = true,
    }) {
      return Role(
        id: id,
        organizationId: organizationId,
        name: id,
        isSystemRole: isSystemRole,
        version: 1,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-1',
      );
    }

    test('two roles with the same field values are equal', () {
      expect(buildRole(), buildRole());
    });

    test('roles with different ids are not equal', () {
      expect(buildRole(id: 'OWNER'), isNot(buildRole(id: 'ADMIN')));
    });

    test('roles from different organizations are not equal even with the '
        'same id', () {
      expect(
        buildRole(organizationId: 'org-1'),
        isNot(buildRole(organizationId: 'org-2')),
      );
    });

    test('copyWith produces a new instance without mutating the original '
        'organizationId', () {
      final original = buildRole();
      final copy = original.copyWith(name: 'OWNER_RENAMED');

      expect(original.organizationId, 'org-1');
      expect(original.name, 'OWNER');
      expect(copy.organizationId, 'org-1');
      expect(copy.name, 'OWNER_RENAMED');
      expect(original, isNot(copy));
    });

    test('deletedAt is null by default (role not soft-deleted)', () {
      expect(buildRole().deletedAt, isNull);
    });

    group('assertRoleIsMutable', () {
      test('throws a ForbiddenException for a system role', () {
        expect(
          () => assertRoleIsMutable(buildRole(isSystemRole: true)),
          throwsA(isA<ForbiddenException>()),
        );
      });

      test('does nothing for a custom (non-system) role', () {
        expect(
          () => assertRoleIsMutable(
            buildRole(id: 'custom-role', isSystemRole: false),
          ),
          returnsNormally,
        );
      });
    });
  });
}
