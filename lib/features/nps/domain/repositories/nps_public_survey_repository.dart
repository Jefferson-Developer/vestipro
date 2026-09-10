import '../../../../core/utils/utils.dart';
import '../entities/nps_response_submission_result.dart';
import '../entities/nps_survey_preview.dart';

/// The only port `NpsResponsePage`'s public/anonymous flow (TASK-202,
/// EPIC-30) uses — both methods are backed exclusively by Cloud Functions
/// (`getNpsSurveyByToken`/`submitNpsResponse`); the anonymous customer never
/// talks to Firestore directly (same contract `CatalogShareLookupRepository`,
/// TASK-081, already establishes for its own public link).
abstract interface class NpsPublicSurveyRepository {
  Future<AppResult<NpsSurveyPreview>> preview({required String token});

  Future<AppResult<NpsResponseSubmissionResult>> submit({
    required String token,
    required int score,
    String? comment,
  });
}
