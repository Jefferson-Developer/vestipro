/// Offline/sync lifecycle of a Price List mutation (TASK-083), mirroring the
/// same `syncStatus` precedent every other sync-aware entity in this
/// codebase already carries (`CustomerSyncStatus`, `ProductSyncStatus`).
enum PriceListSyncStatus { pending, syncing, synced, failed, conflict }
