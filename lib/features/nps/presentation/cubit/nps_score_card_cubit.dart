import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/usecases/load_nps_aggregate_trend_use_case.dart';
import '../../domain/value_objects/nps_aggregate_scope.dart';
import 'nps_score_card_state.dart';

/// Drives the "NPS" indicator card on a dashboard (TASK-202, EPIC-30,
/// `tasks.md`: "alimentar dashboards existentes... com o indicador de NPS
/// agregado e sua evolução no tempo"). Loads automatically when created —
/// same "no explicit action needed" contract as `DailyRepSummaryCubit`, the
/// underlying snapshot is already produced by
/// `recomputeNpsMonthlyAggregates` ahead of time, reading it costs nothing
/// more than any other dashboard widget's own load.
@injectable
final class NpsScoreCardCubit extends Cubit<NpsScoreCardState> {
  NpsScoreCardCubit(this._loadNpsAggregateTrend, this._analyticsService)
    : super(const NpsScoreCardState());

  final LoadNpsAggregateTrendUseCase _loadNpsAggregateTrend;
  final AnalyticsService _analyticsService;

  Future<void> load({
    required String organizationId,
    required String companyId,
    required NpsAggregateScope scope,
    required String scopeId,
    DateTime Function() now = DateTime.now,
  }) async {
    emit(
      state.copyWith(status: NpsScoreCardStatus.loading, clearFailure: true),
    );

    final reference = now();
    final periodKey = _monthKey(reference.year, reference.month);
    final (previousYear, previousMonth) = reference.month == 1
        ? (reference.year - 1, 12)
        : (reference.year, reference.month - 1);
    final previousPeriodKey = _monthKey(previousYear, previousMonth);

    final result = await _loadNpsAggregateTrend(
      organizationId: organizationId,
      companyId: companyId,
      scope: scope,
      scopeId: scopeId,
      periodKey: periodKey,
      previousPeriodKey: previousPeriodKey,
    );
    if (isClosed) return;

    switch (result) {
      case AppSuccess<NpsAggregateTrend>(value: final trend):
        emit(state.copyWith(status: NpsScoreCardStatus.ready, trend: trend));
        await _analyticsService.logEvent(
          AnalyticsEvents.npsScoreCardViewed,
          parameters: <String, Object?>{
            'scope': scope.code,
            'has_score': trend.current?.npsScore != null,
          },
        );
      case AppFailure<NpsAggregateTrend>(failure: final failure):
        emit(
          state.copyWith(status: NpsScoreCardStatus.error, failure: failure),
        );
    }
  }

  String _monthKey(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';
}
