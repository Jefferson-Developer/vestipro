import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/stock_turnover_metric_scope.dart';
import '../../domain/entities/stock_turnover_metric_snapshot.dart';
import '../../domain/repositories/stock_turnover_repository.dart';
import '../../domain/value_objects/stock_turnover_scope_type.dart';
import '../datasources/stock_turnover_data_source.dart';
import '../mappers/stock_turnover_metric_snapshot_mapper.dart';

@LazySingleton(as: StockTurnoverRepository)
final class StockTurnoverRepositoryImpl implements StockTurnoverRepository {
  const StockTurnoverRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final StockTurnoverDataSource dataSource;
  final StockTurnoverMetricSnapshotMapper mapper;

  @override
  Future<AppResult<StockTurnoverMetricSnapshot?>> getByScopeAndPeriod({
    required String organizationId,
    required StockTurnoverMetricScope scope,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    try {
      final dto = await dataSource.getByScopeAndPeriod(
        organizationId: organizationId,
        scopeType: scope.type.code,
        scopeId: scope.id,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      return AppSuccess<StockTurnoverMetricSnapshot?>(
        dto == null ? null : mapper.toEntity(dto),
      );
    } on AppException catch (exception) {
      return AppFailure<StockTurnoverMetricSnapshot?>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<StockTurnoverMetricSnapshot?>(
        UnexpectedFailure(
          'Unexpected error loading stock turnover metrics.',
          code: 'stock_turnover_metrics_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
