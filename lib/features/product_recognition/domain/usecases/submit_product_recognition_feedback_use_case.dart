import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../repositories/product_recognition_repository.dart';
import '../value_objects/product_recognition_feedback_outcome.dart';

/// Records the "era este"/"não era nenhum" feedback for a recognition
/// attempt (TASK-191, EPIC-28) — the quality-tracking signal
/// `tasks.md`/TASK-191 requires.
@injectable
final class SubmitProductRecognitionFeedbackUseCase {
  const SubmitProductRecognitionFeedbackUseCase(
    this._repository,
    this._analyticsService,
  );

  final ProductRecognitionRepository _repository;
  final AnalyticsService _analyticsService;

  Future<AppResult<void>> call({
    required String organizationId,
    required String attemptId,
    required ProductRecognitionFeedbackOutcome outcome,
    String? matchedProductId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedAttemptId = attemptId.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedAttemptId.isEmpty) {
      fieldErrors['attemptId'] = 'AttemptId is required.';
    }
    if (outcome == ProductRecognitionFeedbackOutcome.matched &&
        (matchedProductId == null || matchedProductId.trim().isEmpty)) {
      fieldErrors['matchedProductId'] =
          'MatchedProductId is required when outcome is matched.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<void>(
        ValidationFailure(
          'Invalid product recognition feedback request.',
          fieldErrors: fieldErrors,
          code: 'invalid_product_recognition_feedback_request',
        ),
      );
    }

    final result = await _repository.submitFeedback(
      organizationId: trimmedOrganizationId,
      attemptId: trimmedAttemptId,
      outcome: outcome,
      matchedProductId: matchedProductId?.trim(),
    );
    switch (result) {
      case AppSuccess<void>():
        await _analyticsService.logEvent(
          AnalyticsEvents.productRecognitionFeedbackSubmitted,
          parameters: <String, Object?>{
            'organization_id': trimmedOrganizationId,
            'outcome': outcome.toWireValue(),
          },
        );
      case AppFailure<void>():
        break;
    }
    return result;
  }
}
