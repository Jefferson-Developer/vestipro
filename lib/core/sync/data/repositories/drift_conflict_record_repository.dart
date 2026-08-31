import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../database/database.dart';
import '../../../errors/errors.dart';
import '../../../utils/utils.dart';
import '../../domain/entities/conflict_policy.dart';
import '../../domain/entities/conflict_record.dart';
import '../../domain/entities/conflict_record_status.dart';
import '../../domain/entities/outbox_entity_type.dart';
import '../../domain/repositories/conflict_record_repository.dart';

/// Drift-backed implementation of [ConflictRecordRepository] (TASK-110),
/// mirroring `DriftOutboxRepository`.
@LazySingleton(as: ConflictRecordRepository)
final class DriftConflictRecordRepository implements ConflictRecordRepository {
  const DriftConflictRecordRepository(this._database);

  final AppDatabase _database;

  @override
  Future<AppResult<ConflictRecord>> create(ConflictRecord record) async {
    try {
      final row = await _database.insertConflictRecord(
        id: record.id,
        organizationId: record.organizationId,
        companyId: record.companyId,
        entityType: record.entityType.code,
        entityId: record.entityId,
        outboxOperationId: record.outboxOperationId,
        policy: record.policy.code,
        localSnapshot: jsonEncode(record.localSnapshot),
        remoteSnapshot: jsonEncode(record.remoteSnapshot),
        conflictingFields: jsonEncode(record.conflictingFields),
        detectedAt: record.detectedAt,
      );
      return AppSuccess<ConflictRecord>(_toEntity(row));
    } catch (exception) {
      return AppFailure<ConflictRecord>(
        UnexpectedFailure(
          'Unexpected error persisting conflict record.',
          code: 'conflict_record_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<ConflictRecord>>> listOpen({
    required String organizationId,
  }) async {
    try {
      final rows = await _database.getOpenConflictRecords(
        organizationId: organizationId,
      );
      return AppSuccess<List<ConflictRecord>>(
        rows.map(_toEntity).toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<ConflictRecord>>(
        UnexpectedFailure(
          'Unexpected error loading open conflict records.',
          code: 'conflict_record_list_open_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<ConflictRecord?>> getById(String id) async {
    try {
      final row = await _database.getConflictRecordById(id);
      return AppSuccess<ConflictRecord?>(row == null ? null : _toEntity(row));
    } catch (exception) {
      return AppFailure<ConflictRecord?>(
        UnexpectedFailure(
          'Unexpected error loading conflict record by id.',
          code: 'conflict_record_get_by_id_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<ConflictRecord>> resolve({
    required String id,
    required String resolvedBy,
    required DateTime resolvedAt,
  }) async {
    try {
      final row = await _database.resolveConflictRecord(
        id: id,
        resolvedBy: resolvedBy,
        resolvedAt: resolvedAt,
      );
      return AppSuccess<ConflictRecord>(_toEntity(row));
    } catch (exception) {
      return AppFailure<ConflictRecord>(
        UnexpectedFailure(
          'Unexpected error resolving conflict record.',
          code: 'conflict_record_resolve_unexpected',
          cause: exception,
        ),
      );
    }
  }

  ConflictRecord _toEntity(ConflictRecordsTableData row) {
    final entityType = OutboxEntityTypeCode.fromCode(row.entityType);
    if (entityType == null) {
      throw StateError(
        'Unknown ConflictRecord entityType code: ${row.entityType}',
      );
    }
    final policy = ConflictPolicyCode.fromCode(row.policy);
    if (policy == null) {
      throw StateError('Unknown ConflictRecord policy code: ${row.policy}');
    }
    final status = ConflictRecordStatusCode.fromCode(row.status);
    if (status == null) {
      throw StateError('Unknown ConflictRecord status code: ${row.status}');
    }

    return ConflictRecord(
      id: row.id,
      organizationId: row.organizationId,
      companyId: row.companyId,
      entityType: entityType,
      entityId: row.entityId,
      outboxOperationId: row.outboxOperationId,
      policy: policy,
      localSnapshot: jsonDecode(row.localSnapshot) as Map<String, dynamic>,
      remoteSnapshot: jsonDecode(row.remoteSnapshot) as Map<String, dynamic>,
      conflictingFields: (jsonDecode(row.conflictingFields) as List<dynamic>)
          .cast<String>(),
      status: status,
      detectedAt: row.detectedAt,
      resolvedAt: row.resolvedAt,
      resolvedBy: row.resolvedBy,
    );
  }
}
