import '../../../../core/errors/errors.dart';
import '../../domain/usecases/load_nps_aggregate_trend_use_case.dart';

enum NpsScoreCardStatus { loading, ready, error }

/// State for [NpsScoreCardCubit] (TASK-202, EPIC-30).
final class NpsScoreCardState {
  const NpsScoreCardState({
    this.status = NpsScoreCardStatus.loading,
    this.trend,
    this.failure,
  });

  final NpsScoreCardStatus status;

  /// Non-null once [status] is [NpsScoreCardStatus.ready] — its own
  /// `current`/`previous` snapshots may each still be `null` (no NPS
  /// response received yet this/last month), which the widget renders as
  /// "sem dados suficientes" rather than a score of zero.
  final NpsAggregateTrend? trend;

  final Failure? failure;

  NpsScoreCardState copyWith({
    NpsScoreCardStatus? status,
    NpsAggregateTrend? trend,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return NpsScoreCardState(
      status: status ?? this.status,
      trend: trend ?? this.trend,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
