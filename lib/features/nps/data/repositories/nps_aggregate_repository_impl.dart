import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/nps_aggregate_snapshot.dart';
import '../../domain/repositories/nps_aggregate_repository.dart';
import '../../domain/value_objects/nps_aggregate_scope.dart';
import '../datasources/nps_aggregate_data_source.dart';
import '../mappers/nps_aggregate_snapshot_mapper.dart';

/// Reads from `npsMonthlyAggregates` (`recomputeNpsMonthlyAggregates`,
/// TASK-202) — never recomputed client-side (`tasks.md`: "nunca recalculado
/// ad hoc no cliente"). No local cache, unlike `AggregationRepositoryImpl`
/// (TASK-133): the NPS score card is a single, low-frequency read (one
/// document per dashboard load, not a chart re-queried across filters), so
/// the added cache/offline-fallback complexity is deferred until a concrete
/// need for it appears.
@LazySingleton(as: NpsAggregateRepository)
final class NpsAggregateRepositoryImpl implements NpsAggregateRepository {
  const NpsAggregateRepositoryImpl(this._dataSource, this._mapper);

  final NpsAggregateDataSource _dataSource;
  final NpsAggregateSnapshotMapper _mapper;

  @override
  Future<AppResult<NpsAggregateSnapshot?>> getSnapshot({
    required String organizationId,
    required String companyId,
    required NpsAggregateScope scope,
    required String scopeId,
    required String periodKey,
  }) async {
    final docId = buildNpsAggregateDocId(
      companyId: companyId,
      scope: scope,
      scopeId: scopeId,
      periodKey: periodKey,
    );
    try {
      final dto = await _dataSource.getById(
        organizationId: organizationId,
        docId: docId,
      );
      final snapshot = dto == null ? null : _mapper.toEntity(dto);
      return AppSuccess<NpsAggregateSnapshot?>(snapshot);
    } on AppException catch (exception) {
      return AppFailure<NpsAggregateSnapshot?>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<NpsAggregateSnapshot?>(
        UnexpectedFailure(
          'Unexpected error loading an NPS aggregate snapshot.',
          code: 'nps_aggregate_snapshot_get_unexpected',
          cause: exception,
        ),
      );
    }
  }
}

/// Composite Firestore doc id — must match `npsAggregateDocId` in
/// `functions/src/nps/nps-shared.ts` exactly, since it is how the client
/// looks up the very same snapshot `recomputeNpsMonthlyAggregates` wrote.
String buildNpsAggregateDocId({
  required String companyId,
  required NpsAggregateScope scope,
  required String scopeId,
  required String periodKey,
}) => '${companyId}_${scope.code}_${scopeId}_$periodKey';
