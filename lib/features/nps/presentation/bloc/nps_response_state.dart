import '../../../../core/errors/errors.dart';
import '../../domain/entities/nps_survey_preview.dart';
import '../../domain/value_objects/nps_survey_outcome.dart';

enum NpsResponsePageStatus {
  /// Nothing requested yet / preview in flight.
  loading,

  /// [NpsResponseState.preview] is safe to render as an answerable form (its
  /// own `outcome` is [NpsSurveyOutcome.pending]).
  answerable,

  /// An ordinary, expected "this link cannot be answered" outcome (already
  /// answered/expired/not found) — [NpsResponseState.preview]'s own
  /// `outcome` picks the exact message (`tasks.md`: "nunca erro técnico
  /// cru").
  unavailable,

  /// A genuine technical failure (network, server error) loading the
  /// preview — distinct from [unavailable] so the UI can offer a real retry.
  error,
}

/// Where a submission attempt currently stands — independent from
/// [NpsResponsePageStatus] so a failed submission never discards the
/// already-loaded [NpsResponseState.preview]/the customer's own draft
/// score/comment.
enum NpsResponseSubmissionStatus { idle, submitting, submitted, error }

final class NpsResponseState {
  const NpsResponseState({
    this.status = NpsResponsePageStatus.loading,
    this.token = '',
    this.preview,
    this.failure,
    this.score,
    this.comment = '',
    this.submissionStatus = NpsResponseSubmissionStatus.idle,
    this.submissionFailure,
  });

  final NpsResponsePageStatus status;
  final String token;
  final NpsSurveyPreview? preview;

  /// Set only when [status] is [NpsResponsePageStatus.error].
  final Failure? failure;

  /// The customer's current draft score (0-10), `null` until they pick one.
  final int? score;

  /// The customer's current draft comment — always a `String` (never
  /// `null`) so a `TextField`'s own controller never has to special-case a
  /// null value; an empty string is sent as "no comment" (mirrors
  /// `SubmitNpsResponseUseCase`'s own trim-to-null contract).
  final String comment;

  final NpsResponseSubmissionStatus submissionStatus;

  /// Set only when [submissionStatus] is
  /// [NpsResponseSubmissionStatus.error] — a genuine technical failure, not
  /// an ordinary "already answered/expired" outcome (that instead reloads
  /// the preview into [NpsResponsePageStatus.unavailable], see
  /// `NpsResponseBloc._onFormSubmitted`).
  final Failure? submissionFailure;

  bool get outcomeIsAnswerable =>
      status == NpsResponsePageStatus.answerable &&
      preview?.outcome == NpsSurveyOutcome.pending;

  NpsResponseState copyWith({
    NpsResponsePageStatus? status,
    String? token,
    NpsSurveyPreview? preview,
    Failure? failure,
    bool clearFailure = false,
    int? score,
    String? comment,
    NpsResponseSubmissionStatus? submissionStatus,
    Failure? submissionFailure,
    bool clearSubmissionFailure = false,
  }) {
    return NpsResponseState(
      status: status ?? this.status,
      token: token ?? this.token,
      preview: preview ?? this.preview,
      failure: clearFailure ? null : (failure ?? this.failure),
      score: score ?? this.score,
      comment: comment ?? this.comment,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      submissionFailure: clearSubmissionFailure
          ? null
          : (submissionFailure ?? this.submissionFailure),
    );
  }
}
