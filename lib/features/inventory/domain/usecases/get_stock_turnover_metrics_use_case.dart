import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/stock_turnover_metric_scope.dart';
import '../entities/stock_turnover_metric_snapshot.dart';
import '../repositories/stock_turnover_repository.dart';

@injectable
final class GetStockTurnoverMetricsUseCase {
  const GetStockTurnoverMetricsUseCase(this._repository);

  final StockTurnoverRepository _repository;

  Future<AppResult<StockTurnoverMetricSnapshot?>> call({
    required String organizationId,
    required StockTurnoverMetricScope scope,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final fieldErrors = <String, String>{};
    if (organizationId.trim().isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (scope.id.trim().isEmpty) {
      fieldErrors['scope.id'] = 'ScopeId is required.';
    }
    if (periodEnd.isBefore(periodStart)) {
      fieldErrors['period'] = 'PeriodEnd must be after PeriodStart.';
    }

    if (fieldErrors.isNotEmpty) {
      return Future<AppResult<StockTurnoverMetricSnapshot?>>.value(
        AppFailure<StockTurnoverMetricSnapshot?>(
          ValidationFailure(
            'Invalid stock turnover metrics request.',
            fieldErrors: fieldErrors,
            code: 'invalid_stock_turnover_metrics_request',
          ),
        ),
      );
    }

    return _repository.getByScopeAndPeriod(
      organizationId: organizationId.trim(),
      scope: StockTurnoverMetricScope(type: scope.type, id: scope.id.trim()),
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }
}
