import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/nps_response_submission_result.dart';
import '../../domain/entities/nps_survey_preview.dart';
import '../../domain/repositories/nps_public_survey_repository.dart';
import '../datasources/nps_public_survey_data_source.dart';
import '../mappers/nps_response_submission_result_mapper.dart';
import '../mappers/nps_survey_preview_mapper.dart';

@LazySingleton(as: NpsPublicSurveyRepository)
final class NpsPublicSurveyRepositoryImpl implements NpsPublicSurveyRepository {
  const NpsPublicSurveyRepositoryImpl({
    required this.dataSource,
    required this.previewMapper,
    required this.submissionResultMapper,
  });

  final NpsPublicSurveyDataSource dataSource;
  final NpsSurveyPreviewMapper previewMapper;
  final NpsResponseSubmissionResultMapper submissionResultMapper;

  @override
  Future<AppResult<NpsSurveyPreview>> preview({required String token}) async {
    try {
      final dto = await dataSource.preview(token: token);
      return AppSuccess<NpsSurveyPreview>(previewMapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<NpsSurveyPreview>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<NpsSurveyPreview>(
        UnexpectedFailure(
          'Unexpected error previewing NPS survey.',
          code: 'nps_survey_preview_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<NpsResponseSubmissionResult>> submit({
    required String token,
    required int score,
    String? comment,
  }) async {
    try {
      final dto = await dataSource.submit(
        token: token,
        score: score,
        comment: comment,
      );
      return AppSuccess<NpsResponseSubmissionResult>(
        submissionResultMapper.toEntity(dto),
      );
    } on AppException catch (exception) {
      return AppFailure<NpsResponseSubmissionResult>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<NpsResponseSubmissionResult>(
        UnexpectedFailure(
          'Unexpected error submitting NPS response.',
          code: 'nps_response_submit_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
