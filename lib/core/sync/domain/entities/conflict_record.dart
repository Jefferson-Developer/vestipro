import 'conflict_policy.dart';
import 'conflict_record_status.dart';
import 'outbox_entity_type.dart';

/// A conflict that [ConflictResolutionService] could not resolve
/// automatically — persisted locally so it survives an app restart until a
/// human resolves it (TASK-110, EPIC-14 — seção 5.5 de `tasks.md`; consumed
/// by TASK-111's conflict screen and TASK-112's Central de Sincronização).
///
/// Created only for [ConflictPolicy.manualResolution] entities (orders,
/// order items) or for a [ConflictPolicy.fieldMerge] entity whose divergent
/// fields actually overlap between local and remote — never for a
/// [ConflictPolicy.lastWriteWins] entity, which never blocks. Both
/// [localSnapshot] and [remoteSnapshot] are kept in full (not just the
/// divergent fields) so TASK-111's comparison screen can show the complete
/// picture on both sides, not only what changed.
final class ConflictRecord {
  const ConflictRecord({
    required this.id,
    required this.organizationId,
    this.companyId,
    required this.entityType,
    required this.entityId,
    required this.outboxOperationId,
    required this.policy,
    required this.localSnapshot,
    required this.remoteSnapshot,
    required this.conflictingFields,
    required this.status,
    required this.detectedAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  final String id;
  final String organizationId;
  final String? companyId;
  final OutboxEntityType entityType;
  final String entityId;

  /// The Outbox operation (`OutboxOperation.clientOperationId`) this
  /// conflict blocks — [ConflictResolutionService] moves that same row to
  /// `OutboxStatus.conflict` in the same resolution call that creates this
  /// record, so both are always consistent with each other.
  final String outboxOperationId;

  final ConflictPolicy policy;

  /// Full local snapshot at the moment the conflict was detected.
  final Map<String, Object?> localSnapshot;

  /// Full remote snapshot at the moment the conflict was detected.
  final Map<String, Object?> remoteSnapshot;

  /// The business fields that actually diverge between [localSnapshot] and
  /// [remoteSnapshot] — never empty for a persisted [ConflictRecord] (a
  /// record is only ever created when a real divergence was detected).
  final List<String> conflictingFields;

  final ConflictRecordStatus status;
  final DateTime detectedAt;
  final DateTime? resolvedAt;

  /// The user id who resolved this conflict (TASK-111) — `null` while
  /// [status] is [ConflictRecordStatus.conflict].
  final String? resolvedBy;
}
