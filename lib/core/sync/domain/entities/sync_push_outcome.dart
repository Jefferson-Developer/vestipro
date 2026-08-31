/// Outcome of one [SyncPushHandler.push] call (TASK-109, EPIC-14).
///
/// This is deliberately not just a `bool`/`Failure`: [SyncEngine] needs to
/// react differently to a transient error (retry with backoff) than to a
/// remote rejection that needs a human/TASK-110 to resolve (`conflict`),
/// and needs to treat "the backend already saw this exact
/// `clientOperationId`" the same as a fresh success — that distinction is
/// what makes replaying an Outbox operation after a client-perceived
/// failure safe (idempotency), never creating a second remote record for
/// what is really one offline write.
sealed class SyncPushOutcome {
  const SyncPushOutcome();
}

/// The backend accepted and persisted this operation for the first time.
final class SyncPushSynced extends SyncPushOutcome {
  const SyncPushSynced();
}

/// The backend recognized this operation's `clientOperationId` as one it
/// already processed in a previous attempt (e.g. the client's own
/// connection dropped after the backend had already committed the write,
/// but before the response reached the device) — [SyncEngine] treats this
/// exactly like [SyncPushSynced], never re-enqueuing or duplicating
/// anything.
final class SyncPushAlreadyProcessed extends SyncPushOutcome {
  const SyncPushAlreadyProcessed();
}

/// A transient failure (network, timeout, backend unavailable, ...) —
/// eligible for another attempt once [SyncRetryPolicy]'s backoff window for
/// this operation's attempt count elapses, up to its configured attempt
/// limit.
final class SyncPushRetryableFailure extends SyncPushOutcome {
  const SyncPushRetryableFailure(this.message);

  final String message;
}

/// The backend rejected this operation because it conflicts with a newer
/// remote state (e.g. a stale `version`) — moves the Outbox operation to
/// `OutboxStatus.conflict`, outside the automatic retry path, for
/// TASK-110's resolution flow (and TASK-112's/TASK-111's UI) to handle.
final class SyncPushConflict extends SyncPushOutcome {
  const SyncPushConflict(this.message);

  final String message;
}
