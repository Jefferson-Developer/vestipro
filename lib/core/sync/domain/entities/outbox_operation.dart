import 'outbox_entity_type.dart';
import 'outbox_operation_type.dart';
import 'outbox_status.dart';

/// One persisted Outbox row (TASK-108, EPIC-14) — the domain-level view of
/// `OutboxTable`, decoded back from its stored codes/JSON payload.
final class OutboxOperation {
  const OutboxOperation({
    required this.id,
    required this.organizationId,
    this.companyId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payload,
    required this.status,
    required this.attemptCount,
    this.lastAttemptAt,
    this.lastError,
    required this.createdAt,
    required this.createdBy,
    required this.sequenceNumber,
  });

  /// The operation's `clientOperationId` — generated client-side once, when
  /// the operation is first attempted, and reused on every retry of that
  /// same logical operation (see `OutboxRepository.enqueue` docs).
  final String id;

  final String organizationId;
  final String? companyId;
  final OutboxEntityType entityType;
  final String entityId;
  final OutboxOperationType operationType;

  /// The operation's DTO, decoded from `OutboxTable.payload` — re-executable
  /// against the backend on its own.
  final Map<String, dynamic> payload;

  final OutboxStatus status;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final String? lastError;
  final DateTime createdAt;
  final String createdBy;

  /// Local creation order — see `OutboxTable.sequenceNumber` docs for why
  /// this, not [createdAt], is what defines processing order.
  final int sequenceNumber;

  /// Alias documenting that [id] doubles as the `clientOperationId` the
  /// backend/Functions (TASK-109) use to deduplicate a replayed operation.
  String get clientOperationId => id;
}
