import '../dtos/nps_response_submission_result_dto.dart';
import '../dtos/nps_survey_preview_dto.dart';

/// Contract for the two public, unauthenticated NPS Cloud Functions
/// (TASK-202, EPIC-30): `getNpsSurveyByToken` and `submitNpsResponse`. Always
/// Cloud Function calls — no Firestore read/write of `npsSurveyRequests`/
/// `npsResponses` ever happens directly here (`firestore.rules`: both are
/// `allow create, update, delete: if false`, exclusively written by the
/// Admin SDK), same rationale as `CatalogShareLookupDataSource` (TASK-081).
abstract interface class NpsPublicSurveyDataSource {
  Future<NpsSurveyPreviewDto> preview({required String token});

  Future<NpsResponseSubmissionResultDto> submit({
    required String token,
    required int score,
    String? comment,
  });
}
