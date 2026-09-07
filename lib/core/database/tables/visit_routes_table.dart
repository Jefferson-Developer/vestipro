import 'package:drift/drift.dart';

/// Local-only store for a seller's daily visit route (TASK-177, EPIC-24).
///
/// One row per organization/sales rep/day: [id] is a deterministic key
/// (`'${organizationId}_${salesRepId}_${dateKey}'`, see
/// `BuildVisitRouteUseCase._routeId`), so building/rebuilding "today's route"
/// always upserts the same row instead of accumulating duplicates —
/// `AppDatabase.upsertVisitRoute` uses `insertOnConflictUpdate` on this
/// primary key, same precedent as `FavoritesTable`/`upsertFavorite`.
///
/// [stopsJson] holds the ordered list of stops (customer id, display name,
/// coordinates, sequence, status, distance/eta estimates) as a JSON array —
/// same "no native list/map column type" precedent as
/// `CustomersTable.tagsJson`/`customFieldsJson`. A route is always read and
/// written as a whole (there is no need to query an individual stop across
/// routes), so a second child table/join would add complexity without a
/// real benefit here.
///
/// There is no remote/Firestore counterpart or `syncStatus` column: a visit
/// route is a personal, device-local planning artifact (see TASK-177
/// conclusion doc "Regras Firebase implementadas"), not a synced business
/// record.
@TableIndex(
  name: 'idx_visit_routes_org_rep_date',
  columns: {#organizationId, #salesRepId, #date},
)
class VisitRoutesTable extends Table {
  @override
  String get tableName => 'visit_routes';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();
  TextColumn get salesRepId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get stopsJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
