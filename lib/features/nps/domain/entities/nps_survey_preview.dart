import '../value_objects/nps_survey_outcome.dart';

/// What the public, unauthenticated `NpsResponsePage` (TASK-202, EPIC-30)
/// renders after opening an NPS survey link — deliberately as minimal as
/// `CatalogSharePreview` (TASK-081): never exposes `organizationId`,
/// `customerId`, `sellerId` or any internal id, only what a customer
/// answering their own pesquisa needs to see.
final class NpsSurveyPreview {
  const NpsSurveyPreview({
    required this.outcome,
    this.organizationName,
    this.orderNumber,
    this.expiresAt,
  });

  final NpsSurveyOutcome outcome;
  final String? organizationName;
  final String? orderNumber;
  final DateTime? expiresAt;
}
