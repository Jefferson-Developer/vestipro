/// Result of one [ConflictResolutionService.resolve] call (TASK-110,
/// EPIC-14).
///
/// A sealed class rather than a single "resolved data" map because each
/// variant implies a different follow-up action for the caller ([SyncEngine]
/// or a future manual-resolution flow, TASK-111): apply the remote data
/// locally, keep retrying the local pending write, apply a merged map, or do
/// nothing until a human decides.
sealed class ConflictResolutionOutcome {
  const ConflictResolutionOutcome();
}

/// `updatedAt`/`version` differed between local and remote but no business
/// field actually diverged — not a real conflict, nothing was discarded, no
/// [ConflictRecord] created.
final class ConflictResolutionNoop extends ConflictResolutionOutcome {
  const ConflictResolutionNoop();
}

/// [ConflictPolicy.lastWriteWins]: the remote snapshot won — the caller
/// should apply [remoteData] locally and let the losing local Outbox
/// operation be treated as superseded (never retried as-is).
final class ConflictResolutionAppliedRemote extends ConflictResolutionOutcome {
  const ConflictResolutionAppliedRemote({required this.remoteData});

  final Map<String, Object?> remoteData;
}

/// [ConflictPolicy.lastWriteWins]: the local pending snapshot won (or won
/// the documented tie-break) — the caller should keep the local pending
/// Outbox operation as the source of truth and skip applying the remote
/// pull for this entity, same as before a policy existed.
final class ConflictResolutionAppliedLocal extends ConflictResolutionOutcome {
  const ConflictResolutionAppliedLocal();
}

/// [ConflictPolicy.fieldMerge]: local and remote changed disjoint fields —
/// [mergedData] combines both without loss, [mergedFields] lists exactly
/// which fields came from the local side (every other field came from
/// remote/base).
final class ConflictResolutionMerged extends ConflictResolutionOutcome {
  const ConflictResolutionMerged({
    required this.mergedData,
    required this.mergedFields,
  });

  final Map<String, Object?> mergedData;
  final Set<String> mergedFields;
}

/// Resolution blocked for a human decision — a [ConflictRecord] was
/// persisted with id [conflictRecordId] and the Outbox operation was moved
/// to `OutboxStatus.conflict`. Neither snapshot was applied automatically.
final class ConflictResolutionBlockedManual extends ConflictResolutionOutcome {
  const ConflictResolutionBlockedManual({
    required this.conflictRecordId,
    required this.conflictingFields,
  });

  final String conflictRecordId;
  final Set<String> conflictingFields;
}
