import '../../offline/domain/entities/offline_package_entity_kind.dart';
import '../../utils/utils.dart';
import 'entities/sync_pull_record.dart';

/// One entity's pull side of the sync engine (TASK-109, EPIC-14): a feature
/// implements this to fetch only what changed remotely since a cursor and
/// upsert it into its own Drift table, so [SyncEngine] can keep every
/// registered entity's local cache fresh without ever re-downloading the
/// whole remote collection each cycle — the incremental counterpart to
/// `OfflinePackageEntityLoader`'s full-replace initial load (TASK-107),
/// reusing that same [OfflinePackageEntityKind] to identify which entity a
/// given cursor/source belongs to.
///
/// No concrete implementation is registered yet
/// (`SyncModule.syncPullSources` in `lib/app/` is still an empty list) —
/// each feature is expected to add one once it needs its offline cache to
/// stay fresh between full reloads, reusing the `upsertX`
/// `AppDatabase` primitives already documented as this exact extension
/// point (e.g. `AppDatabase.upsertPriceList`, `AppDatabase.upsertColor`).
///
/// Implementations must:
/// - scope [fetchChanges]'s own remote query to [organizationId]/
///   [companyId] — [SyncEngine] re-validates every returned record's
///   `organizationId` as a second, defense-in-depth guard, but this
///   source's own query remains the primary tenant boundary (never rely on
///   the engine's guard alone);
/// - return records oldest-changed-first, so a page that gets only
///   partially applied (e.g. the app is killed mid-page) can safely resume
///   from the last cursor without skipping anything newer;
/// - implement [apply] as a single-record upsert, never a full-table
///   replace — a pull source runs after the entity's own initial load has
///   already populated the table.
abstract interface class SyncPullSource {
  OfflinePackageEntityKind get kind;

  /// Fetches one page of remote records changed since [cursor] for
  /// [organizationId]/[companyId] — `cursor == null` means "since the
  /// beginning of time" and should only happen for a scope whose initial
  /// load (TASK-107) has already run, otherwise this would duplicate that
  /// load's own work.
  Future<AppResult<SyncPullPage>> fetchChanges({
    required String organizationId,
    required String companyId,
    String? cursor,
  });

  /// Upserts one already tenant-validated [record] into this entity's local
  /// Drift store. Called once per record, in the page's order, only for
  /// records [SyncEngine] did not skip (see `SyncEngine.runPull` docs for
  /// what gets skipped and why).
  Future<AppResult<void>> apply(SyncPullRecord record);
}
