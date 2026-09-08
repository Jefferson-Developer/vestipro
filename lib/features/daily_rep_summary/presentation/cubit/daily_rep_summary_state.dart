import '../../../../core/errors/errors.dart';
import '../../domain/entities/daily_rep_summary.dart';

enum DailyRepSummaryCardStatus { loading, loaded, error }

/// State for [DailyRepSummaryCubit] (TASK-188, EPIC-28).
final class DailyRepSummaryState {
  const DailyRepSummaryState({
    this.status = DailyRepSummaryCardStatus.loading,
    this.summary,
    this.failure,
  });

  final DailyRepSummaryCardStatus status;

  /// Non-null once [status] is [DailyRepSummaryCardStatus.loaded] — its own
  /// [DailyRepSummary.status] then distinguishes ready/empty/error/
  /// not-generated-yet.
  final DailyRepSummary? summary;
  final Failure? failure;

  DailyRepSummaryState copyWith({
    DailyRepSummaryCardStatus? status,
    DailyRepSummary? summary,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return DailyRepSummaryState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
