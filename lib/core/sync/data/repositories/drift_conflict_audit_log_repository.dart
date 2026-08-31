import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../database/database.dart';
import '../../../errors/errors.dart';
import '../../../utils/utils.dart';
import '../../domain/entities/conflict_audit_entry.dart';
import '../../domain/entities/conflict_audit_outcome.dart';
import '../../domain/entities/conflict_policy.dart';
import '../../domain/entities/outbox_entity_type.dart';
import '../../domain/repositories/conflict_audit_log_repository.dart';

/// Drift-backed implementation of [ConflictAuditLogRepository] (TASK-110),
/// mirroring `DriftOutboxRepository`.
@LazySingleton(as: ConflictAuditLogRepository)
final class DriftConflictAuditLogRepository
    implements ConflictAuditLogRepository {
  const DriftConflictAuditLogRepository(this._database);

  final AppDatabase _database;

  @override
  Future<AppResult<ConflictAuditEntry>> record(ConflictAuditEntry entry) async {
    try {
      final row = await _database.insertConflictAuditEntry(
        id: entry.id,
        organizationId: entry.organizationId,
        companyId: entry.companyId,
        entityType: entry.entityType.code,
        entityId: entry.entityId,
        policy: entry.policy.code,
        outcome: entry.outcome.code,
        actor: entry.actor,
        performedAt: entry.performedAt,
        discardedFields: jsonEncode(entry.discardedFields),
        conflictingFields: jsonEncode(entry.conflictingFields),
        conflictRecordId: entry.conflictRecordId,
      );
      return AppSuccess<ConflictAuditEntry>(_toEntity(row));
    } catch (exception) {
      return AppFailure<ConflictAuditEntry>(
        UnexpectedFailure(
          'Unexpected error persisting conflict audit entry.',
          code: 'conflict_audit_log_record_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<ConflictAuditEntry>>> listByOrganization({
    required String organizationId,
  }) async {
    try {
      final rows = await _database.getConflictAuditLog(
        organizationId: organizationId,
      );
      return AppSuccess<List<ConflictAuditEntry>>(
        rows.map(_toEntity).toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<ConflictAuditEntry>>(
        UnexpectedFailure(
          'Unexpected error loading conflict audit log.',
          code: 'conflict_audit_log_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  ConflictAuditEntry _toEntity(ConflictAuditLogTableData row) {
    final entityType = OutboxEntityTypeCode.fromCode(row.entityType);
    if (entityType == null) {
      throw StateError(
        'Unknown ConflictAuditEntry entityType code: ${row.entityType}',
      );
    }
    final policy = ConflictPolicyCode.fromCode(row.policy);
    if (policy == null) {
      throw StateError('Unknown ConflictAuditEntry policy code: ${row.policy}');
    }
    final outcome = ConflictAuditOutcomeCode.fromCode(row.outcome);
    if (outcome == null) {
      throw StateError(
        'Unknown ConflictAuditEntry outcome code: ${row.outcome}',
      );
    }

    return ConflictAuditEntry(
      id: row.id,
      organizationId: row.organizationId,
      companyId: row.companyId,
      entityType: entityType,
      entityId: row.entityId,
      policy: policy,
      outcome: outcome,
      actor: row.actor,
      performedAt: row.performedAt,
      discardedFields: (jsonDecode(row.discardedFields) as List<dynamic>)
          .cast<String>(),
      conflictingFields: (jsonDecode(row.conflictingFields) as List<dynamic>)
          .cast<String>(),
      conflictRecordId: row.conflictRecordId,
    );
  }
}
