import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../dtos/nps_response_submission_result_dto.dart';
import '../dtos/nps_survey_preview_dto.dart';
import 'nps_public_survey_data_source.dart';

/// [NpsPublicSurveyDataSource] backed by [CloudFunctionsService] (TASK-202)
/// — never talks to `cloud_firestore` directly, same rationale as
/// `CloudFunctionsCatalogShareLookupDataSource`.
@LazySingleton(as: NpsPublicSurveyDataSource)
final class CloudFunctionsNpsPublicSurveyDataSource
    implements NpsPublicSurveyDataSource {
  const CloudFunctionsNpsPublicSurveyDataSource(this._cloudFunctionsService);

  final CloudFunctionsService _cloudFunctionsService;

  @override
  Future<NpsSurveyPreviewDto> preview({required String token}) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'getNpsSurveyByToken',
      data: <String, dynamic>{'token': token},
      // Deliberately `false`: an NPS survey link must work for the customer
      // who received it, who never signs in at all (`tasks.md`: "sem exigir
      // login complexo do cliente").
      requireAuth: false,
    );
    return NpsSurveyPreviewDto.fromJson(response);
  }

  @override
  Future<NpsResponseSubmissionResultDto> submit({
    required String token,
    required int score,
    String? comment,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'submitNpsResponse',
      data: <String, dynamic>{
        // Always sent (even `null`): `submitNpsResponse`'s own
        // `optionalComment` already treats any non-string value (including
        // `null`) as "no comment", so there is no behavioral difference
        // between omitting this key and sending it as `null` — sending it
        // unconditionally keeps this payload free of a null-check-via-`if`
        // map entry.
        'token': token,
        'score': score,
        'comment': comment,
      },
      requireAuth: false,
    );
    return NpsResponseSubmissionResultDto.fromJson(response);
  }
}
