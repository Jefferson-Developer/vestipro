import '../../../../core/errors/errors.dart';
import '../../domain/entities/approach_suggestion.dart';

enum ApproachSuggestionStatus {
  /// Before the seller ever taps "Sugerir abordagem" — never auto-generates
  /// on screen load (TASK-187: "sob demanda"; also keeps LLM cost/frequency
  /// under the caller's control, never spent without an explicit request).
  idle,
  loading,
  ready,
  error,
}

/// State for [ApproachSuggestionCubit] (TASK-187, EPIC-28).
final class ApproachSuggestionState {
  const ApproachSuggestionState({
    this.status = ApproachSuggestionStatus.idle,
    this.suggestion,
    this.failure,
  });

  final ApproachSuggestionStatus status;
  final ApproachSuggestion? suggestion;
  final Failure? failure;

  ApproachSuggestionState copyWith({
    ApproachSuggestionStatus? status,
    ApproachSuggestion? suggestion,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ApproachSuggestionState(
      status: status ?? this.status,
      suggestion: suggestion ?? this.suggestion,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
