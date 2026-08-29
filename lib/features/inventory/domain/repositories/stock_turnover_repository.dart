import '../../../../core/utils/utils.dart';
import '../entities/stock_turnover_metric_scope.dart';
import '../entities/stock_turnover_metric_snapshot.dart';

abstract interface class StockTurnoverRepository {
  Future<AppResult<StockTurnoverMetricSnapshot?>> getByScopeAndPeriod({
    required String organizationId,
    required StockTurnoverMetricScope scope,
    required DateTime periodStart,
    required DateTime periodEnd,
  });
}
