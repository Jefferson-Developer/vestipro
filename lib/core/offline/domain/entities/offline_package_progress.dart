import 'offline_package_entity_kind.dart';

/// A progress snapshot `DownloadOfflinePackageUseCase` reports while a
/// download is in flight — the "3.200 / 12.000 registros" example from
/// TASK-107.
final class OfflinePackageProgress {
  const OfflinePackageProgress({
    required this.currentEntity,
    required this.processedEntities,
    required this.totalEntities,
    required this.processedRecords,
    required this.estimatedTotalRecords,
  });

  /// The entity currently being downloaded, or `null` right after the
  /// estimate phase finishes and before the first entity starts.
  final OfflinePackageEntityKind? currentEntity;

  /// How many entities have already finished (successfully or not) this
  /// run, not counting [currentEntity] itself while it is still in flight.
  final int processedEntities;

  /// How many entities this run applies to in total (post-RBAC filtering).
  final int totalEntities;

  /// Records fetched so far across every entity this run, including the
  /// entity currently in flight — this only means "fetched from the remote
  /// source", not "already committed locally"; see
  /// `DownloadOfflinePackageUseCase` for why the local write for an entity
  /// only happens once, atomically, after all of that entity's records have
  /// been fetched.
  final int processedRecords;

  /// Best-effort total across every applicable entity, computed during the
  /// estimate phase. Never a hard guarantee — an entity can legitimately end
  /// up downloading more or fewer records than estimated.
  final int estimatedTotalRecords;
}
