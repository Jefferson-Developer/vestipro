/// Offline/sync lifecycle of a Target mutation, mirroring
/// `OpportunitySyncStatus`.
enum TargetSyncStatus { pending, syncing, synced, failed, conflict }
