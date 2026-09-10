import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/nps_survey_preview.dart';
import '../repositories/nps_public_survey_repository.dart';

/// Previews an NPS survey [token] (TASK-202) — the only client-side check is
/// that a token was actually provided; every other decision (not found/
/// expired/answered/pending) is the repository's (ultimately
/// `getNpsSurveyByToken`'s), same contract as
/// `catalog_share/domain/usecases/preview_catalog_share_use_case.dart`.
@injectable
final class PreviewNpsSurveyUseCase {
  const PreviewNpsSurveyUseCase(this._repository);

  final NpsPublicSurveyRepository _repository;

  Future<AppResult<NpsSurveyPreview>> call({required String token}) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return Future<AppResult<NpsSurveyPreview>>.value(
        AppFailure<NpsSurveyPreview>(
          const ValidationFailure(
            'Token de pesquisa ausente.',
            code: 'nps_survey_token_required',
          ),
        ),
      );
    }
    return _repository.preview(token: trimmed);
  }
}
