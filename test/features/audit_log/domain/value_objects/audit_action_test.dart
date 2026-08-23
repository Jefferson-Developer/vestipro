import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';

void main() {
  group('AuditAction', () {
    test('every action has a stable, unique code', () {
      final codes = AuditAction.values.map((action) => action.code).toList();

      expect(codes.toSet().length, codes.length);
    });

    test('code matches the documented catalog examples from tasks.md', () {
      expect(AuditAction.userLogin.code, 'auth.login');
      expect(AuditAction.roleChanged.code, 'role.changed');
      expect(AuditAction.userRoleUpdated.code, 'user.roleUpdated');
      expect(AuditAction.userInviteResent.code, 'user.inviteResent');
      expect(AuditAction.userInviteRevoked.code, 'user.inviteRevoked');
      expect(AuditAction.userInviteAccepted.code, 'user.inviteAccepted');
      expect(AuditAction.userDeactivated.code, 'user.deactivated');
      expect(AuditAction.userReactivated.code, 'user.reactivated');
      expect(AuditAction.companyDeleted.code, 'company.deleted');
      expect(
        AuditAction.organizationSettingsUpdated.code,
        'organization.settingsUpdated',
      );
    });
  });
}
