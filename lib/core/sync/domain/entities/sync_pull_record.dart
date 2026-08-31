/// One remote record a `SyncPullSource` fetched as part of an incremental
/// pull page (TASK-109, EPIC-14).
///
/// [organizationId] is carried on every record — never assumed from the
/// scope the pull was requested for — so [SyncEngine] can independently
/// verify it before ever applying the record locally (its tenant-isolation
/// guard: "o motor nunca sincroniza ou aplica dado de outro tenant, mesmo em
/// caso de erro de cursor").
final class SyncPullRecord {
  const SyncPullRecord({
    required this.entityId,
    required this.organizationId,
    this.companyId,
    required this.updatedAt,
    required this.data,
  });

  final String entityId;
  final String organizationId;
  final String? companyId;

  /// Server-side last-write timestamp — what a `SyncPullSource`'s next
  /// [SyncPullPage.nextCursor] is typically derived from.
  final DateTime updatedAt;

  /// The record's raw remote payload — a `SyncPullSource` decodes this
  /// itself in [SyncPullSource.apply]; [SyncEngine] never interprets it.
  final Map<String, dynamic> data;
}

/// One page of remote changes a `SyncPullSource.fetchChanges` call returns
/// (TASK-109, EPIC-14).
final class SyncPullPage {
  const SyncPullPage({
    required this.records,
    this.nextCursor,
    this.hasMore = false,
  });

  /// Oldest-changed first — the order [SyncEngine] applies them in.
  final List<SyncPullRecord> records;

  /// The cursor value to resume from after this page, or `null` if nothing
  /// in this page should advance the persisted cursor (e.g. an empty page).
  ///
  /// [SyncEngine] only actually persists this as the new cursor when every
  /// record in this page was applied without being skipped (no cross-tenant
  /// rejection, no pending-Outbox exclusion, no local apply failure) — see
  /// `SyncEngine.runPull` docs for why advancing past a skipped record would
  /// risk permanently losing that record's remote change.
  final String? nextCursor;

  /// Whether this `SyncPullSource` has more changed records beyond this
  /// page (e.g. it hit its own query page-size limit) — when `true` and
  /// every record in this page was applied, [SyncEngine] immediately calls
  /// [SyncPullSource.fetchChanges] again with the advanced cursor, up to a
  /// bounded number of pages per cycle, rather than waiting for the next
  /// scheduled cycle to keep draining a large backlog.
  final bool hasMore;
}
