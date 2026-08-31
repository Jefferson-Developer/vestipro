import '../../../offline/domain/entities/offline_package_entity_kind.dart';
import '../../../utils/utils.dart';
import '../entities/sync_cursor.dart';

/// Domain contract for the incremental pull bookmark per entity
/// (TASK-109, EPIC-14) — what `SyncEngine.runPull` reads before calling a
/// `SyncPullSource` and writes after successfully applying its records.
abstract interface class SyncCursorRepository {
  /// The current cursor for [organizationId]/[companyId]/[kind], or a
  /// success wrapping `null` if this entity has never been pulled
  /// incrementally yet for that scope.
  Future<AppResult<SyncCursor?>> getCursor({
    required String organizationId,
    required String companyId,
    required OfflinePackageEntityKind kind,
  });

  /// Persists [cursorValue] as the new bookmark for
  /// [organizationId]/[companyId]/[kind] — only called once every
  /// non-skipped record of a pull page has been applied, never
  /// speculatively before (see `SyncEngine.runPull` docs).
  Future<AppResult<void>> saveCursor({
    required String organizationId,
    required String companyId,
    required OfflinePackageEntityKind kind,
    required String? cursorValue,
    required DateTime updatedAt,
  });
}
