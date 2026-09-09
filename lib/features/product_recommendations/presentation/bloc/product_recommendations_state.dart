import '../../../../core/errors/errors.dart';
import '../../domain/entities/product_recommendation.dart';
import '../../domain/value_objects/product_recommendation_scope_type.dart';

enum ProductRecommendationsLoadStatus { initial, loading, ready, failure }

final class ProductRecommendationsState {
  const ProductRecommendationsState({
    this.loadStatus = ProductRecommendationsLoadStatus.initial,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.scopeType = ProductRecommendationScopeType.product,
    this.scopeId = '',
    this.recommendation,
    this.failure,
  });

  final ProductRecommendationsLoadStatus loadStatus;
  final String organizationId;
  final String companyId;
  final String userId;
  final ProductRecommendationScopeType scopeType;
  final String scopeId;

  /// `null` while loading/on failure, or when the query succeeded but no
  /// `ProductRecommendation` has ever been generated for this scope yet —
  /// distinct from [failure], which means the request itself could not be
  /// completed.
  final ProductRecommendation? recommendation;
  final Failure? failure;

  bool get isLoading =>
      loadStatus == ProductRecommendationsLoadStatus.initial ||
      loadStatus == ProductRecommendationsLoadStatus.loading;

  ProductRecommendationsState copyWith({
    ProductRecommendationsLoadStatus? loadStatus,
    String? organizationId,
    String? companyId,
    String? userId,
    ProductRecommendationScopeType? scopeType,
    String? scopeId,
    ProductRecommendation? recommendation,
    bool clearRecommendation = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ProductRecommendationsState(
      loadStatus: loadStatus ?? this.loadStatus,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      scopeType: scopeType ?? this.scopeType,
      scopeId: scopeId ?? this.scopeId,
      recommendation: clearRecommendation
          ? null
          : recommendation ?? this.recommendation,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
