import 'package:drift/drift.dart';

/// Local-first store for personal per-user product favorites (TASK-079).
///
/// Every favorite/unfavorite action writes here first — this table, not
/// Firestore, is the source of truth the favorite button reads from, which
/// is what makes favoriting work identically online or offline. [syncStatus]
/// tracks whether the write has been mirrored to
/// `organizations/{organizationId}/favorites/{userId}_{productId}` yet,
/// mirroring the `syncStatus` precedent every other sync-aware entity in
/// this codebase already carries (`CustomersTable`,
/// `ProductSearchIndexTable`), ahead of the generic Outbox engine (EPIC-14).
///
/// [deletedAt] is a tombstone, not a physical row delete: unfavoriting while
/// offline marks the row instead of removing it outright, so the pending
/// remote deletion is never lost before it actually syncs. Once the remote
/// delete is confirmed, `DriftFavoriteRepository` removes the row for good.
@TableIndex(name: 'idx_favorites_org_user', columns: {#organizationId, #userId})
class FavoritesTable extends Table {
  @override
  String get tableName => 'favorites';

  TextColumn get organizationId => text()();
  TextColumn get userId => text()();
  TextColumn get productId => text()();
  TextColumn get companyId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncStatus => text()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {organizationId, userId, productId};
}
