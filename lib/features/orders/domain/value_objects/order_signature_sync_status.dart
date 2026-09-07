/// Offline/sync lifecycle of an `OrderSignature` capture (TASK-180), mirroring
/// the same `syncStatus` precedent every other sync-aware entity in this
/// codebase already carries (`OrderSyncStatus`, `CustomerSyncStatus`).
///
/// A signature captured offline is always [pendingSync] until `signOrder`
/// (the Cloud Function) confirms it — there is no [conflict] value here
/// unlike `OrderSyncStatus`: two devices can never legitimately capture two
/// different signatures for the same order (the server rejects a second one
/// outright, see `signOrder`'s own idempotency/"already signed" checks), so
/// nothing about this entity is ever merge-resolved.
enum OrderSignatureSyncStatus { pendingSync, syncing, synced, failed }
