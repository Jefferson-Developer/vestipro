import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/invites/invites.dart';
import 'package:vestipro/features/organizations/organizations.dart';

void main() {
  group('assignableRolesFor', () {
    test('OWNER can assign every system role, including OWNER', () {
      expect(
        assignableRolesFor(SystemRoleName.owner),
        containsAll(SystemRoleName.values),
      );
    });

    test('ADMIN can assign every role except OWNER', () {
      final assignable = assignableRolesFor(SystemRoleName.admin);

      expect(assignable, isNot(contains(SystemRoleName.owner)));
      expect(assignable, contains(SystemRoleName.admin));
      expect(assignable, contains(SystemRoleName.readOnly));
    });

    test('READ_ONLY (the least powerful role) can only assign READ_ONLY', () {
      expect(assignableRolesFor(SystemRoleName.readOnly), <SystemRoleName>[
        SystemRoleName.readOnly,
      ]);
    });
  });

  group('systemRoleNameFromCode', () {
    test('parses every known system role code back', () {
      for (final role in SystemRoleName.values) {
        expect(systemRoleNameFromCode(role.code), role);
      }
    });

    test('returns null for an unknown/custom role code', () {
      expect(systemRoleNameFromCode('CUSTOM_ROLE'), isNull);
    });
  });
}
