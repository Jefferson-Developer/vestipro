import '../dtos/product_recommendation_dto.dart';

abstract interface class ProductRecommendationDataSource {
  /// Returns the current `ProductRecommendation` for one exact
  /// `{companyId}_{scopeType}_{scopeId}` scope, or `null` when none has ever
  /// been computed.
  Future<ProductRecommendationDto?> getRecommendation({
    required String organizationId,
    required String companyId,
    required String scopeType,
    required String scopeId,
  });
}

/// Builds the deterministic document id
/// (`organizations/{organizationId}/productRecommendations/
/// {companyId}_{scopeType}_{scopeId}`) — must stay in sync with
/// `functions/src/recommendations/recommendation-shared.ts`'s
/// `productRecommendationDocumentId`.
String productRecommendationDocumentId(
  String companyId,
  String scopeType,
  String scopeId,
) {
  return '${companyId}_${scopeType}_$scopeId';
}
