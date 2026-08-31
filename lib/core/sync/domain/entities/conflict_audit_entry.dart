import 'conflict_audit_outcome.dart';
import 'conflict_policy.dart';
import 'outbox_entity_type.dart';

/// One immutable, local audit trail entry for a conflict resolution
/// decision (TASK-110, EPIC-14 — seção 5.5 de `tasks.md`: "toda resolução
/// deve ser auditável").
///
/// Written for *every* [ConflictResolutionService.resolve] call — automatic
/// ([ConflictAuditOutcome.noop]/[ConflictAuditOutcome.appliedRemote]/
/// [ConflictAuditOutcome.appliedLocal]/[ConflictAuditOutcome.merged]) as much
/// as blocked-for-manual-decision
/// ([ConflictAuditOutcome.blockedManual]/[ConflictAuditOutcome.resolvedManual]) —
/// so a discarded local edit (last-write-wins) or a discarded remote change
/// is never silent, even though it was never a [ConflictRecord] a human had
/// to look at.
///
/// Unlike the centralized `AuditLogEntry` (`lib/features/audit_log/`, backed
/// by Firestore, for administrative/RBAC actions), this trail is local-only
/// and Drift-backed: a sync cycle may run entirely offline-adjacent (it only
/// runs when there is connectivity to reach Firestore/Functions, but the
/// resolution decision itself must never depend on a second round trip
/// succeeding to be recorded), and it is scoped to conflict resolution only.
final class ConflictAuditEntry {
  const ConflictAuditEntry({
    required this.id,
    required this.organizationId,
    this.companyId,
    required this.entityType,
    required this.entityId,
    required this.policy,
    required this.outcome,
    required this.actor,
    required this.performedAt,
    this.discardedFields = const <String>[],
    this.conflictingFields = const <String>[],
    this.conflictRecordId,
  });

  final String id;
  final String organizationId;
  final String? companyId;
  final OutboxEntityType entityType;
  final String entityId;
  final ConflictPolicy policy;
  final ConflictAuditOutcome outcome;

  /// Who performed this resolution — `'system:sync-engine'` for every
  /// automatic outcome ([ConflictAuditOutcome.noop]/
  /// [ConflictAuditOutcome.appliedRemote]/[ConflictAuditOutcome.appliedLocal]/
  /// [ConflictAuditOutcome.merged]/[ConflictAuditOutcome.blockedManual]), or
  /// the resolving user's id for [ConflictAuditOutcome.resolvedManual]
  /// (TASK-111).
  final String actor;

  final DateTime performedAt;

  /// The business fields that diverged between the local and remote
  /// snapshots, and whose losing-side value was therefore discarded by
  /// [ConflictAuditOutcome.appliedRemote]/[ConflictAuditOutcome.appliedLocal]
  /// — empty for every other outcome.
  final List<String> discardedFields;

  /// The business fields that diverged and could not be merged — populated
  /// only for [ConflictAuditOutcome.blockedManual]/
  /// [ConflictAuditOutcome.resolvedManual], empty otherwise.
  final List<String> conflictingFields;

  /// The [ConflictRecord.id] this entry relates to, when [outcome] is
  /// [ConflictAuditOutcome.blockedManual] or [ConflictAuditOutcome.resolvedManual].
  final String? conflictRecordId;
}
