import '../../domain/value_objects/product_recommendation_scope_type.dart';

sealed class ProductRecommendationsEvent {
  const ProductRecommendationsEvent();
}

/// Fired once when the section/sheet showing recommendations opens.
final class ProductRecommendationsRequested
    extends ProductRecommendationsEvent {
  const ProductRecommendationsRequested({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.scopeType,
    required this.scopeId,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final ProductRecommendationScopeType scopeType;
  final String scopeId;
}

final class ProductRecommendationsRefreshRequested
    extends ProductRecommendationsEvent {
  const ProductRecommendationsRefreshRequested();
}
