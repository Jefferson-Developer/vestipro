import '../dtos/nps_aggregate_snapshot_dto.dart';

/// Read-only remote access to `organizations/{organizationId}
/// /npsMonthlyAggregates` (TASK-202's own Cloud Function,
/// `functions/src/nps/recompute-nps-monthly-aggregates.ts`). No `set`/
/// `update` method exists here on purpose — Firestore Security Rules deny
/// every client write on this collection (`allow create, update, delete: if
/// false`), same "read-only remote data source" shape
/// `AggregationRemoteDataSource` (TASK-133) already establishes.
abstract interface class NpsAggregateDataSource {
  Future<NpsAggregateSnapshotDto?> getById({
    required String organizationId,
    required String docId,
  });
}
