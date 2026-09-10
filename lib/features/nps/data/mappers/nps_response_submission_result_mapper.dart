import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/nps_response_submission_result.dart';
import '../dtos/nps_response_submission_result_dto.dart';

@injectable
final class NpsResponseSubmissionResultMapper {
  const NpsResponseSubmissionResultMapper();

  NpsResponseSubmissionResult toEntity(NpsResponseSubmissionResultDto dto) {
    return NpsResponseSubmissionResult(outcome: _outcomeOf(dto.outcome));
  }

  NpsResponseSubmissionOutcome _outcomeOf(String code) => switch (code) {
    'accepted' => NpsResponseSubmissionOutcome.accepted,
    'alreadyAnswered' => NpsResponseSubmissionOutcome.alreadyAnswered,
    'expired' => NpsResponseSubmissionOutcome.expired,
    'notFound' => NpsResponseSubmissionOutcome.notFound,
    _ => throw ValidationException(
      'Unknown NPS response submission outcome "$code".',
      code: 'invalid_nps_response_submission_outcome',
    ),
  };
}
