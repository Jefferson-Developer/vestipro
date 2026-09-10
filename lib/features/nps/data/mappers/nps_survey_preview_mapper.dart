import 'package:injectable/injectable.dart';

import '../../domain/entities/nps_survey_preview.dart';
import '../../domain/value_objects/nps_survey_outcome.dart';
import '../dtos/nps_survey_preview_dto.dart';

@injectable
final class NpsSurveyPreviewMapper {
  const NpsSurveyPreviewMapper();

  NpsSurveyPreview toEntity(NpsSurveyPreviewDto dto) {
    return NpsSurveyPreview(
      outcome: NpsSurveyOutcomeCode.fromCode(dto.outcome),
      organizationName: dto.organizationName,
      orderNumber: dto.orderNumber,
      expiresAt: dto.expiresAt,
    );
  }
}
