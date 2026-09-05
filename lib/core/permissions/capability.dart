/// A single grantable action VestiPro's RBAC understands (`tasks.md`,
/// seção 3.3). [RolePermissionMatrix] decides which
/// [SystemRoleName]/`Role` gets which [Capability] — this enum only names
/// the actions themselves.
///
/// [PermissionService] resolving a capability to `true` only ever means the
/// UI is allowed to show/enable the corresponding action
/// (`AuthorizationGuard`, `PermissionBuilder`). It NEVER authorizes the
/// action by itself: every capability below has (or, once TASK-030 exists,
/// will have) an independent Cloud Function/Firestore Security Rule that
/// re-validates the same decision server-side from the caller's real
/// Membership/role — a forged or stale client-side result must never be
/// trusted. [CapabilityCode.code] documents, capability by capability,
/// which backend rule/Function name TASK-030 is expected to enforce.
enum Capability {
  customerView,
  customerCreate,
  customerUpdate,
  customerDelete,
  leadView,
  leadCreate,
  leadQualify,
  opportunityView,
  opportunityManage,
  pipelineStageManage,
  catalogManage,
  priceListManage,
  orderCreate,
  orderView,
  orderApprove,
  discountApproveAboveLimit,
  inventoryAdjust,
  financeView,
  financeManage,
  userInvite,
  userChangeRole,
  userDeactivate,
  roleManage,
  teamManage,
  companyManage,
  branchManage,
  organizationSettingsManage,
  organizationTransferOwnership,
  reportExport,
  reportViewSensitive,
  auditLogView,

  /// Create/edit a `Target` (meta comercial, EPIC-15/TASK-115) for any
  /// dimension (vendedor, equipe, empresa, coleção, categoria). Deliberately
  /// the only gate `CreateTargetUseCase`/`UpdateTargetUseCase` check — a
  /// `SALES_REP` (who never has it, see `RolePermissionMatrix`) cannot
  /// create nor edit any Target yet, including their own, since the
  /// org-configurable "self-edit non-financial fields" carve-out
  /// `tasks.md`/TASK-115 describes has no `OrganizationSettings` toggle to
  /// read yet; revisit this capability's scope once that setting exists.
  targetManage,

  /// View the achievement dashboard (TASK-116, EPIC-15) for at least one
  /// dimension — never by itself which dimension: a `SALES_REP` holding
  /// this only ever sees their own `salesRep` dimension, a `SALES_MANAGER`
  /// their own plus their teams', resolved by `TargetVisibilityService`,
  /// never by this capability alone. Gates whether the dashboard page is
  /// reachable at all, the same two-layer shape `Capability.orderView` +
  /// `OrderVisibilityService` already use for Order.
  targetView,

  /// View the Central de Oportunidades (TASK-132, EPIC-16) — the screen
  /// aggregating every `Insight` (TASK-121 a TASK-131) the caller may see.
  /// Never by itself which insights: a `SALES_REP` holding this only ever
  /// sees insights addressed to their own carteira, a `SALES_MANAGER`
  /// their own plus their teams', resolved by `InsightVisibilityService`,
  /// never by this capability alone — same two-layer shape
  /// `Capability.targetView` + `TargetVisibilityService` already use for
  /// `Target`. Deliberately its own capability, not a reuse of
  /// `Capability.opportunityView` (the unrelated CRM lead/pipeline
  /// "Opportunity" entity under `features/opportunities/`), since the two
  /// screens gate entirely different domains and must be grantable
  /// independently.
  insightView,

  /// Set a `SavedReport.visibility` (TASK-145, EPIC-18) to `team` — sharing a
  /// saved report view built from TASK-144's `ReportDefinition` with the
  /// owner's own team(s). Deliberately weaker than
  /// [reportShareOrganization]: a `SALES_REP` holding only this one caps out
  /// at team-level sharing, never organization-wide, even though every role
  /// (including `SALES_REP`) may always save a `private` view without any
  /// capability at all.
  reportShareTeam,

  /// Set a `SavedReport.visibility` (TASK-145, EPIC-18) to `organization` —
  /// sharing a saved report view with every active member of the tenant.
  /// Strictly more privileged than [reportShareTeam]; a role missing this one
  /// can still hold [reportShareTeam] and cap out at team-level sharing.
  reportShareOrganization,
}

extension CapabilityCode on Capability {
  /// The stable `resource.action` identifier used in docs, analytics and —
  /// once TASK-030 exists — as the exact capability name Cloud
  /// Functions/Firestore Security Rules must re-validate independently of
  /// whatever this client-side [PermissionService] resolved.
  String get code {
    return switch (this) {
      Capability.customerView => 'customer.view',
      Capability.customerCreate => 'customer.create',
      Capability.customerUpdate => 'customer.update',
      Capability.customerDelete => 'customer.delete',
      Capability.leadView => 'lead.view',
      Capability.leadCreate => 'lead.create',
      Capability.leadQualify => 'lead.qualify',
      Capability.opportunityView => 'opportunity.view',
      Capability.opportunityManage => 'opportunity.manage',
      Capability.pipelineStageManage => 'pipelineStage.manage',
      Capability.catalogManage => 'catalog.manage',
      Capability.priceListManage => 'priceList.manage',
      Capability.orderCreate => 'order.create',
      Capability.orderView => 'order.view',
      Capability.orderApprove => 'order.approve',
      Capability.discountApproveAboveLimit => 'discount.approveAboveLimit',
      Capability.inventoryAdjust => 'inventory.adjust',
      Capability.financeView => 'finance.view',
      Capability.financeManage => 'finance.manage',
      Capability.userInvite => 'user.invite',
      Capability.userChangeRole => 'user.changeRole',
      Capability.userDeactivate => 'user.deactivate',
      Capability.roleManage => 'role.manage',
      Capability.teamManage => 'team.manage',
      Capability.companyManage => 'company.manage',
      Capability.branchManage => 'branch.manage',
      Capability.organizationSettingsManage => 'organization.settingsManage',
      Capability.organizationTransferOwnership =>
        'organization.transferOwnership',
      Capability.reportExport => 'report.export',
      Capability.reportViewSensitive => 'report.viewSensitive',
      Capability.auditLogView => 'audit.log.view',
      Capability.targetManage => 'target.manage',
      Capability.targetView => 'target.view',
      Capability.insightView => 'insight.view',
      Capability.reportShareTeam => 'report.share.team',
      Capability.reportShareOrganization => 'report.share.organization',
    };
  }
}
