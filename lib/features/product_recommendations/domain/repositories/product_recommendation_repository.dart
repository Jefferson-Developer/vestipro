import '../../../../core/utils/utils.dart';
import '../entities/product_recommendation.dart';
import '../value_objects/product_recommendation_scope_type.dart';

/// Contract behind reading the current `ProductRecommendation` for one scope
/// (TASK-190, EPIC-28). Always read-only, direct-to-Firestore (already
/// scoped/RBAC'd by `firestore.rules`) — a `ProductRecommendation` is never
/// acted upon or recalculated by a client, only consumed.
abstract interface class ProductRecommendationRepository {
  /// Returns `null` (never a [Failure]) when no `ProductRecommendation` has
  /// ever been generated yet for this exact scope — distinct from
  /// [ProductRecommendation.insufficientData] being `true`, which means a
  /// calculation *did* run but the scope had no qualifying signal.
  Future<AppResult<ProductRecommendation?>> getRecommendation({
    required String organizationId,
    required String companyId,
    required ProductRecommendationScopeType scopeType,
    required String scopeId,
  });
}
