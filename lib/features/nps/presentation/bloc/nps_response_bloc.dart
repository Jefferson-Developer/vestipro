import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/nps_response_submission_result.dart';
import '../../domain/entities/nps_survey_preview.dart';
import '../../domain/usecases/preview_nps_survey_use_case.dart';
import '../../domain/usecases/submit_nps_response_use_case.dart';
import '../../domain/value_objects/nps_survey_outcome.dart';
import 'nps_response_event.dart';
import 'nps_response_state.dart';

/// Orchestrates `NpsResponsePage` (TASK-202, EPIC-30): the public,
/// unauthenticated screen a customer opens from an NPS survey link — no
/// organization/session context exists yet, everything is resolved purely
/// from the token in the URL, same shape as `CatalogSharePublicBloc`
/// (TASK-081).
@injectable
final class NpsResponseBloc extends Bloc<NpsResponseEvent, NpsResponseState> {
  NpsResponseBloc({
    required this.previewNpsSurvey,
    required this.submitNpsResponse,
    required this.analyticsService,
  }) : super(const NpsResponseState()) {
    on<NpsResponseStarted>(_onStarted, transformer: restartable());
    on<NpsResponseScoreChanged>(_onScoreChanged);
    on<NpsResponseCommentChanged>(_onCommentChanged);
    on<NpsResponseFormSubmitted>(_onFormSubmitted, transformer: droppable());
  }

  final PreviewNpsSurveyUseCase previewNpsSurvey;
  final SubmitNpsResponseUseCase submitNpsResponse;
  final AnalyticsService analyticsService;

  Future<void> _onStarted(
    NpsResponseStarted event,
    Emitter<NpsResponseState> emit,
  ) async {
    emit(
      NpsResponseState(
        status: NpsResponsePageStatus.loading,
        token: event.token,
      ),
    );

    final result = await previewNpsSurvey(token: event.token);
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<NpsSurveyPreview>(value: final preview):
        emit(
          state.copyWith(
            status: preview.outcome == NpsSurveyOutcome.pending
                ? NpsResponsePageStatus.answerable
                : NpsResponsePageStatus.unavailable,
            preview: preview,
          ),
        );
      case AppFailure<NpsSurveyPreview>(failure: final failure):
        emit(
          state.copyWith(status: NpsResponsePageStatus.error, failure: failure),
        );
    }
  }

  void _onScoreChanged(
    NpsResponseScoreChanged event,
    Emitter<NpsResponseState> emit,
  ) {
    if (!state.outcomeIsAnswerable) return;
    emit(state.copyWith(score: event.score));
  }

  void _onCommentChanged(
    NpsResponseCommentChanged event,
    Emitter<NpsResponseState> emit,
  ) {
    if (!state.outcomeIsAnswerable) return;
    emit(state.copyWith(comment: event.comment));
  }

  Future<void> _onFormSubmitted(
    NpsResponseFormSubmitted event,
    Emitter<NpsResponseState> emit,
  ) async {
    final score = state.score;
    if (!state.outcomeIsAnswerable ||
        score == null ||
        state.submissionStatus == NpsResponseSubmissionStatus.submitting) {
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: NpsResponseSubmissionStatus.submitting,
        clearSubmissionFailure: true,
      ),
    );

    final result = await submitNpsResponse(
      token: state.token,
      score: score,
      comment: state.comment,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<NpsResponseSubmissionResult>(value: final submission):
        if (submission.outcome == NpsResponseSubmissionOutcome.accepted) {
          emit(
            state.copyWith(
              submissionStatus: NpsResponseSubmissionStatus.submitted,
            ),
          );
          await analyticsService.logEvent(
            AnalyticsEvents.npsResponseSubmitted,
            parameters: <String, Object?>{'score': score},
          );
        } else {
          // `alreadyAnswered`/`expired`/`notFound`: an ordinary outcome the
          // server itself decided (e.g. a double-submit race) — reflected
          // back into the same "unavailable" preview state the initial load
          // already uses to explain a dead link, never a raw technical
          // error (`tasks.md`: "nunca erro técnico cru").
          emit(
            state.copyWith(
              status: NpsResponsePageStatus.unavailable,
              submissionStatus: NpsResponseSubmissionStatus.idle,
              preview: NpsSurveyPreview(
                outcome: switch (submission.outcome) {
                  NpsResponseSubmissionOutcome.alreadyAnswered =>
                    NpsSurveyOutcome.answered,
                  NpsResponseSubmissionOutcome.expired =>
                    NpsSurveyOutcome.expired,
                  NpsResponseSubmissionOutcome.notFound ||
                  NpsResponseSubmissionOutcome.accepted =>
                    NpsSurveyOutcome.notFound,
                },
                organizationName: state.preview?.organizationName,
                orderNumber: state.preview?.orderNumber,
                expiresAt: state.preview?.expiresAt,
              ),
            ),
          );
        }
      case AppFailure<NpsResponseSubmissionResult>(failure: final failure):
        emit(
          state.copyWith(
            submissionStatus: NpsResponseSubmissionStatus.error,
            submissionFailure: failure,
          ),
        );
    }
  }
}
