/// Offline/sync lifecycle of an Order mutation (TASK-095), mirroring the same
/// `syncStatus` precedent every other sync-aware entity in this codebase
/// already carries (`CustomerSyncStatus`, `PriceListSyncStatus`).
///
/// See `OrderStatus` for the separate, business-level workflow status.
enum OrderSyncStatus { pending, syncing, synced, failed, conflict }
