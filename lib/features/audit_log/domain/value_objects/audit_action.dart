/// Standardized catalog of administrative actions VestiPro's audit log
/// (`tasks.md`, seções 13 e 20; TASK-033) accepts — kept as an enum so no
/// feature that records an [AuditLogEntry] ever hardcodes a magic string
/// (`role.changed`, `user.deactivated`, ...) of its own.
///
/// Every value here maps 1:1 to one of the sensitive administrative
/// operations already modeled by `lib/features/organizations/` (role
/// change, user/company/branch/team removal, organization settings
/// change). Adding a new auditable action means adding a case here first,
/// never inlining a string at the call site.
enum AuditAction {
  roleChanged,
  userInvited,
  userDeactivated,
  userDeleted,
  companyDeleted,
  branchDeleted,
  teamDeleted,
  roleDeleted,
  organizationSettingsUpdated,
}

extension AuditActionCode on AuditAction {
  /// The stable `resource.action` identifier persisted in
  /// `AuditLogEntry.action`/Firestore, matching the examples in `tasks.md`
  /// (`role.changed`, `user.deactivated`, `company.deleted`,
  /// `settings.updated`) closely enough to stay grep-able across the app,
  /// docs and the Firestore Security Rules comment that lists them.
  String get code {
    return switch (this) {
      AuditAction.roleChanged => 'role.changed',
      AuditAction.userInvited => 'user.invited',
      AuditAction.userDeactivated => 'user.deactivated',
      AuditAction.userDeleted => 'user.deleted',
      AuditAction.companyDeleted => 'company.deleted',
      AuditAction.branchDeleted => 'branch.deleted',
      AuditAction.teamDeleted => 'team.deleted',
      AuditAction.roleDeleted => 'role.deleted',
      AuditAction.organizationSettingsUpdated => 'organization.settingsUpdated',
    };
  }
}
