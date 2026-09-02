import '../../domain/value_objects/aggregation_dimension.dart';
import '../dtos/aggregation_snapshot_dto.dart';

/// Read-only remote access to the five aggregate collections TASK-133's
/// Cloud Functions write (`functions/src/aggregations`). No `set`/`update`
/// method exists here on purpose — Firestore Security Rules deny every
/// client write on these collections (`allow create, update, delete: if
/// false`), so a write method would only ever throw.
abstract interface class AggregationRemoteDataSource {
  Future<AggregationSnapshotDto?> getById({
    required String organizationId,
    required AggregationDimension dimension,
    required String docId,
  });

  Future<List<AggregationSnapshotDto>> listByPeriod({
    required String organizationId,
    required AggregationDimension dimension,
    required String companyId,
    required String periodKey,
    required int limit,
  });

  Future<List<AggregationSnapshotDto>> listByPeriodRange({
    required String organizationId,
    required AggregationDimension dimension,
    required String companyId,
    required String scopeId,
    required String fromPeriodKey,
    required String toPeriodKey,
  });
}
