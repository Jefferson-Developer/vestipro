import '../dtos/stock_turnover_metric_snapshot_dto.dart';

abstract interface class StockTurnoverDataSource {
  Future<StockTurnoverMetricSnapshotDto?> getByScopeAndPeriod({
    required String organizationId,
    required String scopeType,
    required String scopeId,
    required DateTime periodStart,
    required DateTime periodEnd,
  });
}
