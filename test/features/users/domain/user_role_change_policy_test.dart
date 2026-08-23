import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

void main() {
  group('isSensitiveRoleChange', () {
    test('requires confirmation when demoting an OWNER', () {
      expect(
        isSensitiveRoleChange(
          currentRole: SystemRoleName.owner,
          nextRole: SystemRoleName.admin,
        ),
        isTrue,
      );
    });

    test('requires confirmation when promoting to ADMIN', () {
      expect(
        isSensitiveRoleChange(
          currentRole: SystemRoleName.salesRep,
          nextRole: SystemRoleName.admin,
        ),
        isTrue,
      );
    });

    test(
      'does not require confirmation for ordinary lateral/lower changes',
      () {
        expect(
          isSensitiveRoleChange(
            currentRole: SystemRoleName.salesRep,
            nextRole: SystemRoleName.readOnly,
          ),
          isFalse,
        );
      },
    );
  });
}
