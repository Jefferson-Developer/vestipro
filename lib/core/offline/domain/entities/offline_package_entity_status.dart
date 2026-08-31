import 'offline_package_entity_kind.dart';

/// The persisted "carga completa"/"carga incompleta" marker for one
/// [kind] within one `organizationId`/`companyId` scope (TASK-107).
///
/// [isComplete] is the only field the app should ever trust to decide
/// whether the corresponding local table currently holds a full, reliable
/// offline snapshot — never inferred from whether the table happens to be
/// non-empty, since a cancelled/failed load can legitimately leave stale
/// rows from a previous successful load behind.
final class OfflinePackageEntityStatus {
  const OfflinePackageEntityStatus({
    required this.kind,
    required this.isComplete,
    required this.lastCompletedAt,
    required this.recordCount,
  });

  final OfflinePackageEntityKind kind;
  final bool isComplete;

  /// When the last *successful* full load of [kind] finished, or `null` if
  /// [kind] has never completed a full load for this scope.
  final DateTime? lastCompletedAt;

  /// How many records were written during the last successful full load of
  /// [kind] — `0` (not necessarily stale) while [isComplete] is `false`.
  final int recordCount;
}
