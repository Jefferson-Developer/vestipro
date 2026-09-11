/// Offline/sync lifecycle of a [CommercialPack] mutation (TASK-207),
/// mirroring the same `syncStatus` precedent every other sync-aware entity
/// in this codebase already carries (`PriceListSyncStatus`,
/// `ProductSyncStatus`).
enum CommercialPackSyncStatus { pending, syncing, synced, failed, conflict }
