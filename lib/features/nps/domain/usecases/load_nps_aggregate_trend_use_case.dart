import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/nps_aggregate_snapshot.dart';
import '../repositories/nps_aggregate_repository.dart';
import '../value_objects/nps_aggregate_scope.dart';

/// The current period's `NpsAggregateSnapshot` alongside the previous
/// period's (or `null` when not yet computed) — enough for `NpsScoreCard`
/// (TASK-202) to show "evolução no tempo" as a single trend delta, the same
/// "vs. mês anterior" shape every other `AppKpiCard` in `dashboards/` already
/// renders (`ExecutiveDashboardPage`/`RepresentativeDashboardPage`), without
/// requiring a range query for a single comparison point.
final class NpsAggregateTrend {
  const NpsAggregateTrend({required this.current, required this.previous});

  final NpsAggregateSnapshot? current;
  final NpsAggregateSnapshot? previous;
}

@injectable
final class LoadNpsAggregateTrendUseCase {
  const LoadNpsAggregateTrendUseCase(this._repository);

  final NpsAggregateRepository _repository;

  Future<AppResult<NpsAggregateTrend>> call({
    required String organizationId,
    required String companyId,
    required NpsAggregateScope scope,
    required String scopeId,
    required String periodKey,
    required String previousPeriodKey,
  }) async {
    final currentResult = await _repository.getSnapshot(
      organizationId: organizationId,
      companyId: companyId,
      scope: scope,
      scopeId: scopeId,
      periodKey: periodKey,
    );
    if (currentResult case AppFailure<NpsAggregateSnapshot?>(
      failure: final failure,
    )) {
      return AppFailure<NpsAggregateTrend>(failure);
    }

    final previousResult = await _repository.getSnapshot(
      organizationId: organizationId,
      companyId: companyId,
      scope: scope,
      scopeId: scopeId,
      periodKey: previousPeriodKey,
    );

    final current = (currentResult as AppSuccess<NpsAggregateSnapshot?>).value;
    final previous = switch (previousResult) {
      AppSuccess<NpsAggregateSnapshot?>(value: final snapshot) => snapshot,
      // A failure loading the *previous* period never blocks the current
      // one from being shown — trend simply degrades to "no comparison
      // available", same tolerance `ExecutiveDashboardBloc`'s own
      // month-over-month/year-over-year metrics already apply.
      AppFailure<NpsAggregateSnapshot?>() => null,
    };

    return AppSuccess<NpsAggregateTrend>(
      NpsAggregateTrend(current: current, previous: previous),
    );
  }
}
