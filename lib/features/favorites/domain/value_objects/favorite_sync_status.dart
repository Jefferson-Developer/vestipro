/// Offline/sync lifecycle of a [FavoriteProduct] mutation (TASK-079).
///
/// Mirrors the same shape every other sync-aware entity in this codebase
/// already uses (`CustomerSyncStatus`, `ProductSyncStatus`), minus
/// `conflict`: a favorite is a personal boolean toggle per user/product, so
/// there is no server-authored value it could ever conflict with — only
/// "this local write has/has not reached Firestore yet".
enum FavoriteSyncStatus { pending, syncing, synced, failed }
