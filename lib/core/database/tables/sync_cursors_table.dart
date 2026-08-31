import 'package:drift/drift.dart';

/// Per-entity incremental pull bookmark for the sync engine (TASK-109,
/// EPIC-14 — seção 5.4/14 de `tasks.md`).
///
/// `SyncEngine.runPull` writes/reads exactly one row per
/// `organizationId`/`companyId`/`entityKind` tuple: [cursorValue] is an
/// opaque string a given `SyncPullSource` interprets on its own (typically
/// an ISO-8601 `updatedAt` watermark, but a Firestore-specific pagination
/// token is also valid) — this table never stores the synced records
/// themselves, only where the next incremental pull should resume from, so
/// the engine never has to re-download an entity's full remote collection
/// on every cycle (only what changed since [cursorValue]).
///
/// [entityKind] reuses `OfflinePackageEntityKind.code` — the same entity
/// TASK-107's full initial load already downloads once — rather than a new
/// enum, since incremental pull is that same entity's ongoing "keep this
/// local copy fresh" continuation, not a distinct concept (see
/// `OfflinePackageEntityLoader` docs).
///
/// A missing row for a given tuple means "never pulled incrementally yet"
/// — callers are expected to only start incremental pulls for an entity
/// once TASK-107's initial load has completed for it, otherwise [null]
/// cursor semantics ("since the beginning of time") from a `SyncPullSource`
/// would duplicate that initial load's own work.
class SyncCursorsTable extends Table {
  @override
  String get tableName => 'sync_cursors';

  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();

  /// Stable identifier of an `OfflinePackageEntityKind` value (e.g.
  /// `'customers'`) — stored as text rather than an int index, same
  /// convention as every other sync/offline table in this schema.
  TextColumn get entityKind => text()();

  TextColumn get cursorValue => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {organizationId, companyId, entityKind};
}
