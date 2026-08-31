import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../database/database.dart';
import '../../../errors/errors.dart';
import '../../../utils/utils.dart';
import '../../domain/entities/outbox_entity_type.dart';
import '../../domain/entities/outbox_operation.dart';
import '../../domain/entities/outbox_operation_type.dart';
import '../../domain/entities/outbox_status.dart';
import '../../domain/entities/outbox_summary.dart';
import '../../domain/repositories/outbox_repository.dart';

/// Drift-backed implementation of [OutboxRepository] (TASK-108), mirroring
/// `DriftOfflinePackageStatusRepository`.
@LazySingleton(as: OutboxRepository)
final class DriftOutboxRepository implements OutboxRepository {
  const DriftOutboxRepository(this._database);

  final AppDatabase _database;

  @override
  Future<AppResult<OutboxOperation>> enqueue({
    required String id,
    required String organizationId,
    String? companyId,
    required OutboxEntityType entityType,
    required String entityId,
    required OutboxOperationType operationType,
    required Map<String, dynamic> payload,
    required DateTime createdAt,
    required String createdBy,
  }) async {
    try {
      final row = await _database.enqueueOutboxOperation(
        id: id,
        organizationId: organizationId,
        companyId: companyId,
        entityType: entityType.code,
        entityId: entityId,
        operationType: operationType.code,
        payload: jsonEncode(payload),
        createdAt: createdAt,
        createdBy: createdBy,
      );
      return AppSuccess<OutboxOperation>(_toEntity(row));
    } catch (exception) {
      return AppFailure<OutboxOperation>(
        UnexpectedFailure(
          'Unexpected error enqueuing Outbox operation.',
          code: 'outbox_enqueue_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> markSyncing({
    required String id,
    required DateTime attemptedAt,
  }) async {
    try {
      await _database.markOutboxSyncing(id: id, attemptedAt: attemptedAt);
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error marking Outbox operation as syncing.',
          code: 'outbox_mark_syncing_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> markSynced({required String id}) async {
    try {
      await _database.markOutboxSynced(id: id);
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error marking Outbox operation as synced.',
          code: 'outbox_mark_synced_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> markFailed({
    required String id,
    required String error,
    required DateTime attemptedAt,
  }) async {
    try {
      await _database.markOutboxFailed(
        id: id,
        error: error,
        attemptedAt: attemptedAt,
      );
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error marking Outbox operation as failed.',
          code: 'outbox_mark_failed_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> markConflict({
    required String id,
    required String error,
    required DateTime attemptedAt,
  }) async {
    try {
      await _database.markOutboxConflict(
        id: id,
        error: error,
        attemptedAt: attemptedAt,
      );
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error marking Outbox operation as conflict.',
          code: 'outbox_mark_conflict_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> requeue({
    required String id,
    required Map<String, dynamic> payload,
    required DateTime attemptedAt,
  }) async {
    try {
      await _database.requeueOutboxOperation(
        id: id,
        payload: jsonEncode(payload),
        attemptedAt: attemptedAt,
      );
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error requeuing Outbox operation.',
          code: 'outbox_requeue_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<OutboxOperation>>> listByStatus({
    required String organizationId,
    required List<OutboxStatus> statuses,
  }) async {
    try {
      final rows = await _database.getOutboxOperationsByStatus(
        organizationId: organizationId,
        statuses: statuses.map((status) => status.code).toList(growable: false),
      );
      return AppSuccess<List<OutboxOperation>>(
        rows.map(_toEntity).toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<OutboxOperation>>(
        UnexpectedFailure(
          'Unexpected error loading Outbox operations by status.',
          code: 'outbox_list_by_status_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<OutboxOperation>>> listByEntity({
    required String organizationId,
    required OutboxEntityType entityType,
    required String entityId,
  }) async {
    try {
      final rows = await _database.getOutboxOperationsByEntity(
        organizationId: organizationId,
        entityType: entityType.code,
        entityId: entityId,
      );
      return AppSuccess<List<OutboxOperation>>(
        rows.map(_toEntity).toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<OutboxOperation>>(
        UnexpectedFailure(
          'Unexpected error loading Outbox operations by entity.',
          code: 'outbox_list_by_entity_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Stream<OutboxSummary> watchSummary({required String organizationId}) {
    return _database
        .watchOutboxStatusCounts(organizationId: organizationId)
        .map(
          (counts) => OutboxSummary(
            pendingCount: counts.pending,
            syncingCount: counts.syncing,
            failedCount: counts.failed,
            conflictCount: counts.conflict,
          ),
        );
  }

  OutboxOperation _toEntity(OutboxTableData row) {
    final entityType = OutboxEntityTypeCode.fromCode(row.entityType);
    if (entityType == null) {
      throw StateError('Unknown Outbox entityType code: ${row.entityType}');
    }
    final operationType = OutboxOperationTypeCode.fromCode(row.operationType);
    if (operationType == null) {
      throw StateError(
        'Unknown Outbox operationType code: ${row.operationType}',
      );
    }
    final status = OutboxStatusCode.fromCode(row.status);
    if (status == null) {
      throw StateError('Unknown Outbox status code: ${row.status}');
    }

    return OutboxOperation(
      id: row.id,
      organizationId: row.organizationId,
      companyId: row.companyId,
      entityType: entityType,
      entityId: row.entityId,
      operationType: operationType,
      payload: jsonDecode(row.payload) as Map<String, dynamic>,
      status: status,
      attemptCount: row.attemptCount,
      lastAttemptAt: row.lastAttemptAt,
      lastError: row.lastError,
      createdAt: row.createdAt,
      createdBy: row.createdBy,
      sequenceNumber: row.sequenceNumber,
    );
  }
}
