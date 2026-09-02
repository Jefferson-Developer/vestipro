/// Public surface of `lib/features/dashboards/`.
///
/// TASK-133 only ships the read layer this barrel exports
/// (`AggregationRepository` + its Firestore-backed implementation) — no
/// `presentation/` yet. The first dashboard screen (TASK-134, dashboard
/// executivo) is what starts populating `presentation/`.
library;

export 'data/datasources/aggregation_remote_data_source.dart';
export 'data/datasources/firestore_aggregation_data_source.dart';
export 'data/dtos/aggregation_snapshot_dto.dart';
export 'data/mappers/aggregation_snapshot_mapper.dart';
export 'data/repositories/aggregation_repository_impl.dart';
export 'domain/entities/aggregation_snapshot.dart';
export 'domain/repositories/aggregation_repository.dart';
export 'domain/value_objects/aggregation_dimension.dart';
