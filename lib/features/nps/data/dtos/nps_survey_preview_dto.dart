import '../../../../core/errors/errors.dart';

/// Plain-JSON shape of `getNpsSurveyByToken`'s callable response (TASK-202,
/// `functions/src/nps/get-nps-survey-by-token.ts`'s
/// `GetNpsSurveyByTokenResponse`).
final class NpsSurveyPreviewDto {
  const NpsSurveyPreviewDto({
    required this.outcome,
    this.organizationName,
    this.orderNumber,
    this.expiresAt,
  });

  factory NpsSurveyPreviewDto.fromJson(Map<String, dynamic> json) {
    final outcome = json['outcome'];
    final organizationName = json['organizationName'];
    final orderNumber = json['orderNumber'];
    final expiresAt = json['expiresAt'];

    if (outcome is! String ||
        (organizationName != null && organizationName is! String) ||
        (orderNumber != null && orderNumber is! String) ||
        (expiresAt != null && expiresAt is! String)) {
      throw const ServerException(
        'Unexpected getNpsSurveyByToken callable response shape.',
        code: 'invalid_nps_survey_preview_response',
      );
    }

    return NpsSurveyPreviewDto(
      outcome: outcome,
      organizationName: organizationName as String?,
      orderNumber: orderNumber as String?,
      expiresAt: expiresAt == null ? null : DateTime.parse(expiresAt as String),
    );
  }

  final String outcome;
  final String? organizationName;
  final String? orderNumber;
  final DateTime? expiresAt;
}
