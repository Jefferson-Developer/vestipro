import 'dart:typed_data';

import '../../../../core/utils/utils.dart';
import '../entities/product_recognition_result.dart';
import '../value_objects/product_recognition_feedback_outcome.dart';

/// Contract for TASK-191's "reconhecimento de produto por imagem" feature
/// (EPIC-28). The only implementation is
/// `CloudFunctionsProductRecognitionRepository` — there is deliberately no
/// local/offline datasource: recognizing a product from a photo always
/// requires connectivity (both the Storage upload and the embedding-provider
/// call), same reasoning `ApproachSuggestionRepository`/
/// `ReportExplanationRepository` already document for their own always-online
/// features.
abstract interface class ProductRecognitionRepository {
  /// Uploads [imageBytes] (already compressed by the caller) and asks
  /// `recognizeProductImage` to identify a catalog product from it, scoped
  /// to [organizationId]. [companyId] is carried only for the attempt's own
  /// analytics/audit trail — the embedding index itself is scoped by
  /// [organizationId] alone (a `Product.companyId` is optional, TASK-064).
  Future<AppResult<ProductRecognitionResult>> recognize({
    required String organizationId,
    required String companyId,
    required Uint8List imageBytes,
  });

  /// Records whether [attemptId]'s candidates actually matched what the
  /// seller was looking for. Never called more than once for the same
  /// [attemptId] — the server itself rejects a second answer
  /// (`submitProductRecognitionFeedback`'s own idempotency rule).
  Future<AppResult<void>> submitFeedback({
    required String organizationId,
    required String attemptId,
    required ProductRecognitionFeedbackOutcome outcome,
    String? matchedProductId,
  });
}
