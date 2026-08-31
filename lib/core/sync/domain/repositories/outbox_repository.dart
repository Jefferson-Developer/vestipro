import '../../../utils/utils.dart';
import '../entities/outbox_entity_type.dart';
import '../entities/outbox_operation.dart';
import '../entities/outbox_operation_type.dart';
import '../entities/outbox_status.dart';
import '../entities/outbox_summary.dart';

/// Domain contract for the local Outbox queue (TASK-108, EPIC-14 — seção
/// 5.4 de `tasks.md`).
///
/// This task only models and implements the Outbox structure itself — the
/// engine that actually drains it against Firestore/Functions is TASK-109.
abstract interface class OutboxRepository {
  /// Enqueues a new `pending` operation, or returns the already-persisted
  /// one unchanged if [id] was already enqueued before.
  ///
  /// [id] is the operation's `clientOperationId`: callers must generate it
  /// once — when the operation is first attempted — and pass that exact
  /// same value on every retry of that same logical operation (e.g. the app
  /// crashing/restarting mid-write) for this method to stay idempotent,
  /// never creating a duplicate row for what is really one offline write.
  ///
  /// Callers whose local mutation (e.g. persisting an order draft) must
  /// never be persisted without its matching Outbox row, or vice versa, are
  /// expected to call this from within their own Drift transaction that
  /// also performs that local write.
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
  });

  /// Moves operation [id] to `syncing`, bumping its attempt count — called
  /// by the sync engine (TASK-109) right before it sends the operation to
  /// the backend.
  Future<AppResult<void>> markSyncing({
    required String id,
    required DateTime attemptedAt,
  });

  /// Moves operation [id] to `synced` — only after the backend has
  /// confirmed it.
  Future<AppResult<void>> markSynced({required String id});

  /// Moves operation [id] to `failed`, recording [error] — the row is kept
  /// for a future retry, never removed.
  Future<AppResult<void>> markFailed({
    required String id,
    required String error,
    required DateTime attemptedAt,
  });

  /// Moves operation [id] to `conflict`, recording [error] — reserved for a
  /// remote rejection that needs manual resolution rather than a plain
  /// retry.
  Future<AppResult<void>> markConflict({
    required String id,
    required String error,
    required DateTime attemptedAt,
  });

  /// Moves operation [id] from `conflict` back to `pending`, replacing its
  /// [payload] with the corrected data a human just chose (TASK-111's
  /// "Manter minha versão"/"Usar versão do servidor"/"Mesclar campo a campo"
  /// actions) and clearing its previous error/attempt count so it is
  /// retried by the sync engine (TASK-109) exactly like a brand-new
  /// operation — never counted against the original attempt/backoff that
  /// led to the conflict in the first place.
  ///
  /// Only [ConflictResolutionService.resolveManually] calls this — no
  /// repository/handler/UI may requeue an Outbox operation with data that
  /// was not the outcome of an explicit, audited conflict resolution.
  Future<AppResult<void>> requeue({
    required String id,
    required Map<String, dynamic> payload,
    required DateTime attemptedAt,
  });

  /// Moves operation [id] from `failed` back to `pending`, recording
  /// [requestedAt] as its last-attempt marker without touching its payload —
  /// the Central de Sincronização's (TASK-112) "Tentar novamente"/"Tentar
  /// novamente todos" actions, deliberately bypassing `SyncRetryPolicy`'s
  /// backoff window and exhausted-attempts gate (both only ever checked
  /// against a `failed` row) since a human just explicitly asked for another
  /// attempt right now. A no-op when [id] is currently `conflict` — those
  /// only ever leave that status through [ConflictResolutionService], never
  /// this method.
  Future<AppResult<void>> retryFailed({
    required String id,
    required DateTime requestedAt,
  });

  /// Every operation for [organizationId] whose status is one of [statuses],
  /// oldest-enqueued first.
  Future<AppResult<List<OutboxOperation>>> listByStatus({
    required String organizationId,
    required List<OutboxStatus> statuses,
  });

  /// Every operation ever enqueued for one specific
  /// [organizationId]/[entityType]/[entityId], oldest first — the exact
  /// order they must be replayed in.
  Future<AppResult<List<OutboxOperation>>> listByEntity({
    required String organizationId,
    required OutboxEntityType entityType,
    required String entityId,
  });

  /// Reactive count of pending/syncing/failed/conflict operations for
  /// [organizationId] — what [OutboxWatcherCubit] (TASK-112) observes.
  Stream<OutboxSummary> watchSummary({required String organizationId});
}
