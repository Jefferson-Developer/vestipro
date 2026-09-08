import '../../../../core/errors/errors.dart';
import '../../domain/entities/report_explanation.dart';

enum ReportExplanationStatus {
  /// Before the user ever taps "Explicar este relatório" — the panel shows
  /// only the call-to-action, never auto-generates on screen load (TASK-189:
  /// "sob demanda"; also keeps LLM cost/frequency under the caller's
  /// explicit control, never spent without a request).
  idle,
  loading,
  ready,
  error,
}

/// State for [ReportExplanationCubit] (TASK-189, EPIC-28).
final class ReportExplanationState {
  const ReportExplanationState({
    this.status = ReportExplanationStatus.idle,
    this.explanation,
    this.failure,
  });

  final ReportExplanationStatus status;
  final ReportExplanation? explanation;
  final Failure? failure;

  ReportExplanationState copyWith({
    ReportExplanationStatus? status,
    ReportExplanation? explanation,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ReportExplanationState(
      status: status ?? this.status,
      explanation: explanation ?? this.explanation,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
