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
  customerCreate,
  customerUpdate,
  customerDelete,
  catalogManage,
  priceListManage,
  orderCreate,
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
}

extension CapabilityCode on Capability {
  /// The stable `resource.action` identifier used in docs, analytics and —
  /// once TASK-030 exists — as the exact capability name Cloud
  /// Functions/Firestore Security Rules must re-validate independently of
  /// whatever this client-side [PermissionService] resolved.
  String get code {
    return switch (this) {
      Capability.customerCreate => 'customer.create',
      Capability.customerUpdate => 'customer.update',
      Capability.customerDelete => 'customer.delete',
      Capability.catalogManage => 'catalog.manage',
      Capability.priceListManage => 'priceList.manage',
      Capability.orderCreate => 'order.create',
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
    };
  }
}
