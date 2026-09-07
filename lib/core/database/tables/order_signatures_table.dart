import 'package:drift/drift.dart';

/// Local mirror of the `OrderSignature` aggregate (EPIC-13, TASK-180) — the
/// offline-first cache a signature capture is written to *before* (and
/// regardless of whether) `signOrder` has confirmed it, so a signature drawn
/// with no connectivity is never lost.
///
/// [imageBytes] is kept as a `BLOB` column even after a successful sync
/// (never purged once [remoteImageStoragePath] is set): the comprovante/PDF
/// flow always renders from this local copy, so it works fully offline on
/// this same device regardless of connectivity — same "local cache never
/// becomes stale/incomplete just because the remote copy also exists"
/// precedent `OrdersTable` itself already sets by keeping every synced order
/// cached locally too.
///
/// One row per [id] — `id` is the client-generated uuid also used as this
/// signature's own Firestore document id/idempotency key
/// (`OrderSignature.id`'s own docs). A given [orderId] should only ever have
/// one row with [status] `'valid'` (enforced by
/// `CaptureOrderSignatureUseCase`, never by a SQL constraint — the same
/// "business rule lives in the use case, not the schema" precedent every
/// other table in this codebase already follows).
@TableIndex(name: 'idx_order_signatures_order', columns: {#orderId})
@TableIndex(
  name: 'idx_order_signatures_org_company',
  columns: {#organizationId, #companyId},
)
class OrderSignaturesTable extends Table {
  @override
  String get tableName => 'order_signatures';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();
  TextColumn get orderId => text()();
  TextColumn get orderNumber => text().nullable()();
  TextColumn get signerRole => text()();
  TextColumn get signedByUserId => text()();
  TextColumn get signedByName => text()();
  TextColumn get method => text()();
  BlobColumn get imageBytes => blob()();
  TextColumn get contentHash => text()();
  IntColumn get orderVersionAtSignature => integer()();
  DateTimeColumn get signedAt => dateTime()();
  TextColumn get deviceInfo => text().nullable()();
  TextColumn get ipAddress => text().nullable()();
  DateTimeColumn get serverReceivedAt => dateTime().nullable()();
  TextColumn get remoteImageStoragePath => text().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get invalidatedAt => dateTime().nullable()();
  TextColumn get invalidatedReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();
  IntColumn get version => integer()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
