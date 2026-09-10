import '../../../../core/errors/errors.dart';

/// Plain-JSON shape of `submitNpsResponse`'s callable response (TASK-202,
/// `functions/src/nps/submit-nps-response.ts`'s `SubmitNpsResponseResponse`).
final class NpsResponseSubmissionResultDto {
  const NpsResponseSubmissionResultDto({required this.outcome});

  factory NpsResponseSubmissionResultDto.fromJson(Map<String, dynamic> json) {
    final outcome = json['outcome'];
    if (outcome is! String) {
      throw const ServerException(
        'Unexpected submitNpsResponse callable response shape.',
        code: 'invalid_nps_response_submission_result',
      );
    }
    return NpsResponseSubmissionResultDto(outcome: outcome);
  }

  final String outcome;
}
