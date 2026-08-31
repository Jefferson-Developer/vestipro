/// The result [ConflictResolutionService.resolve] recorded for one
/// [ConflictAuditEntry] (TASK-110, EPIC-14).
enum ConflictAuditOutcome {
  /// `updatedAt`/`version` differed between local and remote but every
  /// overlapping business field held the exact same value — not a real
  /// conflict (`tasks.md`, seção 5.5: detectar divergência real, "não
  /// apenas diferença de timestamp irrelevante"), nothing was discarded.
  noop,

  /// [ConflictPolicy.lastWriteWins]: the remote snapshot was more recent —
  /// the local pending change was discarded.
  appliedRemote,

  /// [ConflictPolicy.lastWriteWins]: the local pending snapshot was more
  /// recent (or won the documented tie-break) — the remote snapshot was
  /// discarded.
  appliedLocal,

  /// [ConflictPolicy.fieldMerge]: local and remote changed disjoint fields —
  /// combined automatically, nothing discarded.
  merged,

  /// Resolution blocked for manual decision — either the entity's policy is
  /// [ConflictPolicy.manualResolution], or it is [ConflictPolicy.fieldMerge]
  /// and the same field changed on both sides. A [ConflictRecord] was
  /// persisted for TASK-111.
  blockedManual,

  /// A human resolved a previously blocked [ConflictRecord] (TASK-111) —
  /// recorded by that task's flow, using the same audit trail this task
  /// creates for automatic outcomes.
  resolvedManual,
}

extension ConflictAuditOutcomeCode on ConflictAuditOutcome {
  /// Stable identifier persisted in the local `conflict_audit_log` table —
  /// never the enum index.
  String get code {
    return switch (this) {
      ConflictAuditOutcome.noop => 'noop',
      ConflictAuditOutcome.appliedRemote => 'applied_remote',
      ConflictAuditOutcome.appliedLocal => 'applied_local',
      ConflictAuditOutcome.merged => 'merged',
      ConflictAuditOutcome.blockedManual => 'blocked_manual',
      ConflictAuditOutcome.resolvedManual => 'resolved_manual',
    };
  }

  static ConflictAuditOutcome? fromCode(String code) {
    for (final outcome in ConflictAuditOutcome.values) {
      if (outcome.code == code) return outcome;
    }
    return null;
  }
}
