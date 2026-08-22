/// The 7 built-in roles every Organization is seeded with (`tasks.md`, seção
/// 3.3). Custom roles (future work, outside this task's scope) use any other
/// [Role.name] and have [Role.isSystemRole] set to `false`.
enum SystemRoleName {
  owner,
  admin,
  salesManager,
  salesRep,
  salesAssistant,
  finance,
  readOnly,
}

extension SystemRoleNameCode on SystemRoleName {
  /// The literal value stored in [Role.name]/Firestore for this system role,
  /// matching `tasks.md`, seção 3.3, exactly (`OWNER`, `ADMIN`, ...). Also
  /// used as the Firestore document id under
  /// `organizations/{organizationId}/roles/{id}`, so seeding stays
  /// idempotent without a separate lookup table.
  String get code {
    return switch (this) {
      SystemRoleName.owner => 'OWNER',
      SystemRoleName.admin => 'ADMIN',
      SystemRoleName.salesManager => 'SALES_MANAGER',
      SystemRoleName.salesRep => 'SALES_REP',
      SystemRoleName.salesAssistant => 'SALES_ASSISTANT',
      SystemRoleName.finance => 'FINANCE',
      SystemRoleName.readOnly => 'READ_ONLY',
    };
  }
}
