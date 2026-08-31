import 'entities/outbox_entity_type.dart';
import 'entities/outbox_operation.dart';
import 'entities/sync_push_outcome.dart';

/// One `OutboxEntityType`'s push side of the sync engine (TASK-109, EPIC-14):
/// a feature implements this to send its Outbox operations' payload to
/// Firestore/Cloud Functions, adapting its own domain repositories/data
/// sources to this uniform contract so [SyncEngine] can drain the whole
/// Outbox without knowing anything feature-specific — same "adapter per
/// entity, orchestrator stays generic" shape as `OfflinePackageEntityLoader`
/// (TASK-107).
///
/// No concrete implementation is registered yet (`SyncModule.syncPushHandlers`
/// in `lib/app/` is still an empty list) — every feature that wants its
/// offline writes to actually reach the backend must first start calling
/// `OutboxRepository.enqueue` from its own repository (not yet done for
/// `order`/`orderItem`/`crmActivity`/`customer` either — those entities
/// today still write to Firestore/Functions directly, online-only) and then
/// register a [SyncPushHandler] for it here.
///
/// Implementations must:
/// - never assume [OutboxOperation.payload] on its own is authorization —
///   the backend call this makes must still independently validate the
///   caller's RBAC/tenant scope, exactly like every other write path
///   (`operation.organizationId`/`operation.companyId` are for routing the
///   call, not for granting it);
/// - treat [OutboxOperation.clientOperationId] as the idempotency key of
///   the backend call (e.g. the Cloud Function's own `idempotencyKey`
///   parameter, the same contract `submitOrder` already uses) so a replayed
///   operation is recognized server-side and answered with
///   [SyncPushAlreadyProcessed] rather than creating a duplicate;
/// - never throw for an expected failure (network, validation, conflict) —
///   return the matching [SyncPushOutcome] instead. An uncaught exception
///   is still handled safely by [SyncEngine] (treated as a retryable
///   failure), but bypasses this contract's richer signal.
abstract interface class SyncPushHandler {
  OutboxEntityType get entityType;

  Future<SyncPushOutcome> push(OutboxOperation operation);
}
