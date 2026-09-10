import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/nps_response_submission_result.dart';
import '../repositories/nps_public_survey_repository.dart';

/// Submits a customer's NPS response (TASK-202) — client-side validation is
/// deliberately shallow (score is an integer between 0 and 10, comment stays
/// under a sane length) purely for immediate form feedback; the Cloud
/// Function (`submitNpsResponse`) is always the authority that actually
/// decides whether a token is still answerable (`tasks.md`: "cálculo/decisão
/// nunca só no cliente").
@injectable
final class SubmitNpsResponseUseCase {
  const SubmitNpsResponseUseCase(this._repository);

  final NpsPublicSurveyRepository _repository;

  static const int maxCommentLength = 1000;

  Future<AppResult<NpsResponseSubmissionResult>> call({
    required String token,
    required int score,
    String? comment,
  }) {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      return Future<AppResult<NpsResponseSubmissionResult>>.value(
        AppFailure<NpsResponseSubmissionResult>(
          const ValidationFailure(
            'Token de pesquisa ausente.',
            code: 'nps_survey_token_required',
          ),
        ),
      );
    }
    if (score < 0 || score > 10) {
      return Future<AppResult<NpsResponseSubmissionResult>>.value(
        AppFailure<NpsResponseSubmissionResult>(
          const ValidationFailure(
            'A nota da pesquisa deve estar entre 0 e 10.',
            code: 'nps_score_out_of_range',
          ),
        ),
      );
    }

    final trimmedComment = comment?.trim();
    if (trimmedComment != null && trimmedComment.length > maxCommentLength) {
      return Future<AppResult<NpsResponseSubmissionResult>>.value(
        AppFailure<NpsResponseSubmissionResult>(
          ValidationFailure(
            'O comentário deve ter no máximo $maxCommentLength caracteres.',
            code: 'nps_comment_too_long',
          ),
        ),
      );
    }

    return _repository.submit(
      token: trimmedToken,
      score: score,
      comment: (trimmedComment == null || trimmedComment.isEmpty)
          ? null
          : trimmedComment,
    );
  }
}
