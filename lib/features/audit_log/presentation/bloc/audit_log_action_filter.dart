import '../../domain/value_objects/audit_action.dart';

enum AuditLogActionFilter {
  login,
  roleChanged,
  organizationCreated,
  userDeactivated,
  userReactivated,
  userInvited,
  userInviteResent,
  userInviteRevoked,
  userInviteAccepted,
  userDeleted,
  companyDeleted,
  branchDeleted,
  teamDeleted,
  roleDeleted,
  organizationSettingsUpdated,
}

extension AuditLogActionFilterX on AuditLogActionFilter {
  Set<AuditAction> get actions {
    return switch (this) {
      AuditLogActionFilter.login => {AuditAction.userLogin},
      AuditLogActionFilter.roleChanged => {
        AuditAction.roleChanged,
        AuditAction.userRoleUpdated,
      },
      AuditLogActionFilter.organizationCreated => {
        AuditAction.organizationCreated,
      },
      AuditLogActionFilter.userDeactivated => {AuditAction.userDeactivated},
      AuditLogActionFilter.userReactivated => {AuditAction.userReactivated},
      AuditLogActionFilter.userInvited => {AuditAction.userInvited},
      AuditLogActionFilter.userInviteResent => {AuditAction.userInviteResent},
      AuditLogActionFilter.userInviteRevoked => {AuditAction.userInviteRevoked},
      AuditLogActionFilter.userInviteAccepted => {
        AuditAction.userInviteAccepted,
      },
      AuditLogActionFilter.userDeleted => {AuditAction.userDeleted},
      AuditLogActionFilter.companyDeleted => {AuditAction.companyDeleted},
      AuditLogActionFilter.branchDeleted => {AuditAction.branchDeleted},
      AuditLogActionFilter.teamDeleted => {AuditAction.teamDeleted},
      AuditLogActionFilter.roleDeleted => {AuditAction.roleDeleted},
      AuditLogActionFilter.organizationSettingsUpdated => {
        AuditAction.organizationSettingsUpdated,
      },
    };
  }

  String get label {
    return switch (this) {
      AuditLogActionFilter.login => 'Login',
      AuditLogActionFilter.roleChanged => 'Role',
      AuditLogActionFilter.organizationCreated => 'Org criada',
      AuditLogActionFilter.userDeactivated => 'Inativado',
      AuditLogActionFilter.userReactivated => 'Reativado',
      AuditLogActionFilter.userInvited => 'Convite',
      AuditLogActionFilter.userInviteResent => 'Reenvio',
      AuditLogActionFilter.userInviteRevoked => 'Revogação',
      AuditLogActionFilter.userInviteAccepted => 'Aceite',
      AuditLogActionFilter.userDeleted => 'Usuário excl.',
      AuditLogActionFilter.companyDeleted => 'Empresa excl.',
      AuditLogActionFilter.branchDeleted => 'Filial excl.',
      AuditLogActionFilter.teamDeleted => 'Equipe excl.',
      AuditLogActionFilter.roleDeleted => 'Role excl.',
      AuditLogActionFilter.organizationSettingsUpdated => 'Config.',
    };
  }
}
