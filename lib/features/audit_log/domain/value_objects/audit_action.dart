/// Standardized catalog of administrative actions VestiPro's audit log
/// (`tasks.md`, seções 13 e 20; TASK-033) accepts — kept as an enum so no
/// feature that records an [AuditLogEntry] ever hardcodes a magic string
/// (`role.changed`, `user.deactivated`, ...) of its own.
///
/// Every value here maps 1:1 to one of the sensitive administrative
/// operations already modeled by `lib/features/organizations/` (Organization
/// creation, role change, user/company/branch/team removal, organization
/// settings change) or, since TASK-065, by `lib/features/products/`
/// (publishing/editing a catalog Product). Adding a new auditable action
/// means adding a case here first, never inlining a string at the call
/// site.
///
/// [organizationCreated] is the one value never written by any Dart code in
/// this repository: it is recorded server-side by the `createOrganization`
/// Cloud Function (TASK-037,
/// `functions/src/organizations/create-organization.ts`), using the exact
/// same `organization.created` string as [AuditActionCode.code] below —
/// kept here so `AuditLogEntryMapper`/`ListAuditLogEntriesUseCase` can parse
/// those entries back into an [AuditAction] like any other.
enum AuditAction {
  userLogin,
  organizationCreated,
  roleChanged,
  userRoleUpdated,
  userInvited,

  /// Recorded server-side by the `resendInvite` Cloud Function (TASK-039,
  /// `functions/src/invites/resend-invite.ts`) — same "never written by
  /// Dart code, only parsed back" situation as [organizationCreated].
  userInviteResent,

  /// Recorded server-side by the `revokeInvite` Cloud Function (TASK-039,
  /// `functions/src/invites/revoke-invite.ts`) — same situation as
  /// [userInviteResent].
  userInviteRevoked,

  /// Recorded server-side by the `acceptInvite` Cloud Function (TASK-040,
  /// `functions/src/invites/accept-invite.ts`) — same "never written by
  /// Dart code, only parsed back" situation as [userInviteResent].
  userInviteAccepted,
  userDeactivated,
  userReactivated,
  userDeleted,
  companyDeleted,
  branchDeleted,
  teamDeleted,
  roleDeleted,
  organizationSettingsUpdated,

  /// A draft Product (TASK-064/065) transitioned to
  /// `ProductStatus.active` via `PublishProductUseCase`, after its
  /// completeness (name/SKU/reference/category) was validated.
  productPublished,

  /// A field of a Product that was already published (any status other
  /// than `ProductStatus.draft`) changed via `UpdateProductUseCase` — never
  /// recorded for an edit to a still-unpublished draft.
  productUpdated,
  inventoryBalanceAdjusted,
  paymentTermCreated,
  paymentTermUpdated,
  paymentTermDeactivated,
  discountPolicyCreated,
  discountPolicyUpdated,
  discountPolicyDeactivated,
  promotionalCampaignCreated,
  promotionalCampaignUpdated,
  promotionalCampaignEnded,
}

extension AuditActionCode on AuditAction {
  /// The stable `resource.action` identifier persisted in
  /// `AuditLogEntry.action`/Firestore, matching the examples in `tasks.md`
  /// (`role.changed`, `user.deactivated`, `company.deleted`,
  /// `settings.updated`) closely enough to stay grep-able across the app,
  /// docs and the Firestore Security Rules comment that lists them.
  String get code {
    return switch (this) {
      AuditAction.organizationCreated => 'organization.created',
      AuditAction.userLogin => 'auth.login',
      AuditAction.roleChanged => 'role.changed',
      AuditAction.userRoleUpdated => 'user.roleUpdated',
      AuditAction.userInvited => 'user.invited',
      AuditAction.userInviteResent => 'user.inviteResent',
      AuditAction.userInviteRevoked => 'user.inviteRevoked',
      AuditAction.userInviteAccepted => 'user.inviteAccepted',
      AuditAction.userDeactivated => 'user.deactivated',
      AuditAction.userReactivated => 'user.reactivated',
      AuditAction.userDeleted => 'user.deleted',
      AuditAction.companyDeleted => 'company.deleted',
      AuditAction.branchDeleted => 'branch.deleted',
      AuditAction.teamDeleted => 'team.deleted',
      AuditAction.roleDeleted => 'role.deleted',
      AuditAction.organizationSettingsUpdated => 'organization.settingsUpdated',
      AuditAction.productPublished => 'product.published',
      AuditAction.productUpdated => 'product.updated',
      AuditAction.inventoryBalanceAdjusted => 'inventory.balanceAdjusted',
      AuditAction.paymentTermCreated => 'paymentTerm.created',
      AuditAction.paymentTermUpdated => 'paymentTerm.updated',
      AuditAction.paymentTermDeactivated => 'paymentTerm.deactivated',
      AuditAction.discountPolicyCreated => 'discountPolicy.created',
      AuditAction.discountPolicyUpdated => 'discountPolicy.updated',
      AuditAction.discountPolicyDeactivated => 'discountPolicy.deactivated',
      AuditAction.promotionalCampaignCreated => 'promotionalCampaign.created',
      AuditAction.promotionalCampaignUpdated => 'promotionalCampaign.updated',
      AuditAction.promotionalCampaignEnded => 'promotionalCampaign.ended',
    };
  }
}
