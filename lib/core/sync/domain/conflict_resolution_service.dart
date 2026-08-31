import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import 'conflict_field_merge.dart';
import 'conflict_policy_catalog.dart';
import 'entities/conflict_audit_entry.dart';
import 'entities/conflict_audit_outcome.dart';
import 'entities/conflict_policy.dart';
import 'entities/conflict_record.dart';
import 'entities/conflict_record_status.dart';
import 'entities/conflict_resolution_outcome.dart';
import 'entities/conflict_snapshot.dart';
import 'entities/outbox_entity_type.dart';
import 'repositories/conflict_audit_log_repository.dart';
import 'repositories/conflict_record_repository.dart';
import 'repositories/outbox_repository.dart';

/// Applies the per-entity conflict resolution policy (TASK-110, EPIC-14 —
/// seção 5.5 de `tasks.md`) whenever a pull encounters a remote version that
/// diverges from a locally pending/applied Outbox operation.
///
/// This is the single entry point every caller (a future `SyncEngine`
/// integration, a manual "sincronizar agora" action, TASK-111's conflict
/// screen resolving a previously blocked [ConflictRecord]) must go through —
/// nothing else is allowed to decide a winner, merge fields or mark an
/// Outbox operation `conflict` on its own, so the policy stays centralized
/// (see [ConflictPolicyCatalog]) and every resolution is auditable (see
/// [ConflictAuditLogRepository]).
///
/// ## Why [base] is optional but required for a safe [ConflictPolicy.fieldMerge]
///
/// Detecting *which* fields actually changed on each side requires a common
/// reference point both sides are known to have started from. When [base]
/// is not supplied (e.g. the caller has no last-synced snapshot at hand),
/// this service never guesses: a [ConflictPolicy.fieldMerge] entity without
/// a [base] is treated exactly like [ConflictPolicy.manualResolution] for
/// that call — blocked for a human decision — rather than risk silently
/// dropping an edit.
@lazySingleton
final class ConflictResolutionService {
  ConflictResolutionService(
    this._conflictRecordRepository,
    this._conflictAuditLogRepository,
    this._outboxRepository, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final ConflictRecordRepository _conflictRecordRepository;
  final ConflictAuditLogRepository _conflictAuditLogRepository;
  final OutboxRepository _outboxRepository;
  final Uuid _uuid;

  /// System actor recorded for every automatic resolution (never a human
  /// decision) — see [ConflictAuditEntry.actor] docs.
  static const String systemActor = 'system:sync-engine';

  /// Resolves the conflict between [local] (the pending/applied Outbox
  /// operation's own view of the entity) and [remote] (the version a pull
  /// just fetched) for [entityId] of [entityType], scoped to
  /// [organizationId]/[companyId].
  ///
  /// [outboxOperationId] is the `OutboxOperation.clientOperationId` this
  /// call is resolving — required so a
  /// [ConflictResolutionOutcome.ConflictResolutionBlockedManual] outcome can
  /// mark that exact row `OutboxStatus.conflict` in the same call that
  /// persists its [ConflictRecord].
  ///
  /// Always writes exactly one [ConflictAuditEntry], regardless of outcome.
  Future<ConflictResolutionOutcome> resolve({
    required String organizationId,
    String? companyId,
    required OutboxEntityType entityType,
    required String entityId,
    required String outboxOperationId,
    required ConflictSnapshot local,
    required ConflictSnapshot remote,
    ConflictSnapshot? base,
    DateTime? now,
  }) async {
    final resolvedNow = now ?? DateTime.now().toUtc();
    final divergentFields = _divergentFields(local.data, remote.data);

    if (divergentFields.isEmpty) {
      await _audit(
        organizationId: organizationId,
        companyId: companyId,
        entityType: entityType,
        entityId: entityId,
        policy: ConflictPolicyCatalog.policyFor(entityType),
        outcome: ConflictAuditOutcome.noop,
        performedAt: resolvedNow,
      );
      return const ConflictResolutionNoop();
    }

    final policy = ConflictPolicyCatalog.policyFor(entityType);
    return switch (policy) {
      ConflictPolicy.lastWriteWins => _resolveLastWriteWins(
        organizationId: organizationId,
        companyId: companyId,
        entityType: entityType,
        entityId: entityId,
        local: local,
        remote: remote,
        divergentFields: divergentFields,
        now: resolvedNow,
      ),
      ConflictPolicy.fieldMerge => _resolveFieldMerge(
        organizationId: organizationId,
        companyId: companyId,
        entityType: entityType,
        entityId: entityId,
        outboxOperationId: outboxOperationId,
        local: local,
        remote: remote,
        base: base,
        now: resolvedNow,
      ),
      ConflictPolicy.manualResolution => _blockForManualResolution(
        organizationId: organizationId,
        companyId: companyId,
        entityType: entityType,
        entityId: entityId,
        outboxOperationId: outboxOperationId,
        policy: policy,
        local: local,
        remote: remote,
        conflictingFields: divergentFields,
        now: resolvedNow,
      ),
    };
  }

  Future<ConflictResolutionOutcome> _resolveLastWriteWins({
    required String organizationId,
    String? companyId,
    required OutboxEntityType entityType,
    required String entityId,
    required ConflictSnapshot local,
    required ConflictSnapshot remote,
    required Set<String> divergentFields,
    required DateTime now,
  }) async {
    final remoteWins = _remoteWinsLastWriteWins(local: local, remote: remote);

    await _audit(
      organizationId: organizationId,
      companyId: companyId,
      entityType: entityType,
      entityId: entityId,
      policy: ConflictPolicy.lastWriteWins,
      outcome: remoteWins
          ? ConflictAuditOutcome.appliedRemote
          : ConflictAuditOutcome.appliedLocal,
      performedAt: now,
      discardedFields: divergentFields,
    );

    return remoteWins
        ? ConflictResolutionAppliedRemote(remoteData: remote.data)
        : const ConflictResolutionAppliedLocal();
  }

  /// Determines the [ConflictPolicy.lastWriteWins] winner.
  ///
  /// [ConflictSnapshot.version] is preferred over [ConflictSnapshot.updatedAt]
  /// when both sides carry one and they differ — a monotonic counter can
  /// never collide/skew across devices the way a wall-clock timestamp can.
  /// The deterministic tie-break, when neither signal distinguishes a
  /// winner (equal version, or no version and equal `updatedAt`), is: the
  /// remote snapshot wins — it is the one the backend has already durably
  /// persisted and every other client will converge on, so favoring it
  /// keeps every device's local cache eventually consistent with the same
  /// value instead of each one keeping its own stale local edit forever.
  bool _remoteWinsLastWriteWins({
    required ConflictSnapshot local,
    required ConflictSnapshot remote,
  }) {
    final localVersion = local.version;
    final remoteVersion = remote.version;
    if (localVersion != null &&
        remoteVersion != null &&
        localVersion != remoteVersion) {
      return remoteVersion > localVersion;
    }

    if (remote.updatedAt.isAfter(local.updatedAt)) return true;
    if (local.updatedAt.isAfter(remote.updatedAt)) return false;
    return true; // Deterministic tie-break: remote wins.
  }

  Future<ConflictResolutionOutcome> _resolveFieldMerge({
    required String organizationId,
    String? companyId,
    required OutboxEntityType entityType,
    required String entityId,
    required String outboxOperationId,
    required ConflictSnapshot local,
    required ConflictSnapshot remote,
    required ConflictSnapshot? base,
    required DateTime now,
  }) async {
    if (base == null) {
      // No common reference point to compute a safe per-field diff from —
      // never guess, block for a human decision instead.
      return _blockForManualResolution(
        organizationId: organizationId,
        companyId: companyId,
        entityType: entityType,
        entityId: entityId,
        outboxOperationId: outboxOperationId,
        policy: ConflictPolicy.fieldMerge,
        local: local,
        remote: remote,
        conflictingFields: _divergentFields(local.data, remote.data),
        now: now,
      );
    }

    final mergeResult = ConflictFieldMerge.compute(
      base: base.data,
      local: local.data,
      remote: remote.data,
    );

    if (mergeResult.hasConflict) {
      return _blockForManualResolution(
        organizationId: organizationId,
        companyId: companyId,
        entityType: entityType,
        entityId: entityId,
        outboxOperationId: outboxOperationId,
        policy: ConflictPolicy.fieldMerge,
        local: local,
        remote: remote,
        conflictingFields: mergeResult.conflictingFields,
        now: now,
      );
    }

    await _audit(
      organizationId: organizationId,
      companyId: companyId,
      entityType: entityType,
      entityId: entityId,
      policy: ConflictPolicy.fieldMerge,
      outcome: ConflictAuditOutcome.merged,
      performedAt: now,
    );

    return ConflictResolutionMerged(
      mergedData: mergeResult.mergedData,
      mergedFields: mergeResult.mergedFields,
    );
  }

  Future<ConflictResolutionOutcome> _blockForManualResolution({
    required String organizationId,
    String? companyId,
    required OutboxEntityType entityType,
    required String entityId,
    required String outboxOperationId,
    required ConflictPolicy policy,
    required ConflictSnapshot local,
    required ConflictSnapshot remote,
    required Set<String> conflictingFields,
    required DateTime now,
  }) async {
    // Generated speculatively — [ConflictRecordRepository.create] is
    // idempotent per [outboxOperationId] (see `AppDatabase.insertConflictRecord`
    // docs) and returns the *already-persisted* record's own id instead when
    // this same conflict was already blocked by a previous resolution
    // attempt, so [persistedRecordId] below — never this local value — is
    // what every caller/audit entry must reference.
    final speculativeRecordId = _uuid.v4();

    final createResult = await _conflictRecordRepository.create(
      ConflictRecord(
        id: speculativeRecordId,
        organizationId: organizationId,
        companyId: companyId,
        entityType: entityType,
        entityId: entityId,
        outboxOperationId: outboxOperationId,
        policy: policy,
        localSnapshot: local.data,
        remoteSnapshot: remote.data,
        conflictingFields: conflictingFields.toList(growable: false),
        status: ConflictRecordStatus.conflict,
        detectedAt: now,
      ),
    );
    final persistedRecordId = createResult.fold(
      onSuccess: (record) => record.id,
      onFailure: (_) => speculativeRecordId,
    );

    await _outboxRepository.markConflict(
      id: outboxOperationId,
      error:
          'Conflito de sincronização: os campos '
          '${conflictingFields.join(', ')} divergem entre a versão local e a '
          'remota e exigem resolução manual.',
      attemptedAt: now,
    );

    await _audit(
      organizationId: organizationId,
      companyId: companyId,
      entityType: entityType,
      entityId: entityId,
      policy: policy,
      outcome: ConflictAuditOutcome.blockedManual,
      performedAt: now,
      conflictingFields: conflictingFields,
      conflictRecordId: persistedRecordId,
    );

    return ConflictResolutionBlockedManual(
      conflictRecordId: persistedRecordId,
      conflictingFields: conflictingFields,
    );
  }

  Future<void> _audit({
    required String organizationId,
    String? companyId,
    required OutboxEntityType entityType,
    required String entityId,
    required ConflictPolicy policy,
    required ConflictAuditOutcome outcome,
    required DateTime performedAt,
    Set<String> discardedFields = const <String>{},
    Set<String> conflictingFields = const <String>{},
    String? conflictRecordId,
  }) {
    return _conflictAuditLogRepository.record(
      ConflictAuditEntry(
        id: _uuid.v4(),
        organizationId: organizationId,
        companyId: companyId,
        entityType: entityType,
        entityId: entityId,
        policy: policy,
        outcome: outcome,
        actor: systemActor,
        performedAt: performedAt,
        discardedFields: discardedFields.toList(growable: false),
        conflictingFields: conflictingFields.toList(growable: false),
        conflictRecordId: conflictRecordId,
      ),
    );
  }

  /// Business fields present in either [local]/[remote] whose values differ
  /// — the "real divergence" check (`tasks.md`, seção 5.5): a difference in
  /// `updatedAt`/`version` alone, with every overlapping field equal, is
  /// never reported here.
  Set<String> _divergentFields(
    Map<String, Object?> local,
    Map<String, Object?> remote,
  ) {
    final allKeys = <String>{...local.keys, ...remote.keys};
    return {
      for (final key in allKeys)
        if (local[key] != remote[key]) key,
    };
  }
}
