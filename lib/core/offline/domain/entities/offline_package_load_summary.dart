import 'offline_package_entity_kind.dart';

/// Outcome of one run of `DownloadOfflinePackageUseCase` that did not fail
/// outright — either it finished every applicable entity ([cancelled] is
/// `false`) or the caller cancelled it partway through ([cancelled] is
/// `true`, and [entityRecordCounts] only lists the entities that had
/// already committed before the cancellation was observed).
final class OfflinePackageLoadSummary {
  const OfflinePackageLoadSummary({
    required this.entityRecordCounts,
    required this.cancelled,
    required this.completedAt,
  });

  /// How many records were written locally per entity that finished this
  /// run — an entity cancelled/failed mid-load is absent from this map, not
  /// present with a partial count, because nothing was committed for it.
  final Map<OfflinePackageEntityKind, int> entityRecordCounts;

  final bool cancelled;
  final DateTime completedAt;

  int get totalRecords =>
      entityRecordCounts.values.fold(0, (sum, count) => sum + count);
}
