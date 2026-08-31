/// Per-entity conflict resolution strategy (TASK-110, EPIC-14 — seção 5.5 de
/// `tasks.md`).
///
/// [ConflictPolicyCatalog] is the single point that maps an
/// `OutboxEntityType` to one of these — no repository/handler is allowed to
/// decide this on its own, so the policy stays centralized, auditable and
/// testable in isolation (see that class' docs).
enum ConflictPolicy {
  /// The most recent `updatedAt`/`version` wins automatically — only for
  /// entities classified as safe (non-financial, non-critical), never for
  /// orders or anything with a pricing/financial implication.
  lastWriteWins,

  /// Local and remote changes are combined field by field when they touched
  /// disjoint fields — the moment the same field changed on both sides,
  /// [ConflictResolutionService] downgrades this to a manual conflict
  /// instead of guessing.
  fieldMerge,

  /// Never resolved automatically — always blocks with a persisted
  /// [ConflictRecord] for a human to resolve (TASK-111). Reserved for
  /// orders, order items and any other entity with a financial implication.
  manualResolution,
}

extension ConflictPolicyCode on ConflictPolicy {
  /// Stable identifier persisted/logged wherever a [ConflictPolicy] is
  /// recorded (e.g. [ConflictRecord.policy], [ConflictAuditEntry.policy]) —
  /// never the enum index, same convention as `OutboxStatus`/
  /// `OutboxEntityType`.
  String get code {
    return switch (this) {
      ConflictPolicy.lastWriteWins => 'last_write_wins',
      ConflictPolicy.fieldMerge => 'field_merge',
      ConflictPolicy.manualResolution => 'manual_resolution',
    };
  }

  static ConflictPolicy? fromCode(String code) {
    for (final policy in ConflictPolicy.values) {
      if (policy.code == code) return policy;
    }
    return null;
  }
}
