import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product_recommendation.dart';
import '../repositories/product_recommendation_repository.dart';
import '../value_objects/product_recommendation_scope_type.dart';

/// Reads the current `ProductRecommendation` for one scope (TASK-190,
/// EPIC-28).
///
/// `product`/`segment` scope carry no customer data — same open-to-any-
/// active-member model already applied to catalog browsing itself (no
/// dedicated capability gates `ProductDetailPage`'s own use cases today,
/// enforced instead by `firestore.rules`' `isActiveMember`). `customer`
/// scope exposes one specific customer's purchase-derived data, so it is
/// gated by [Capability.customerView] — the same capability
/// `CustomerDetailPage` itself requires — re-validated server-side by the
/// exact same carteira-visibility rule already applied to the `customers`
/// collection (`firestore.rules`' `canReadProductRecommendation`).
@injectable
final class GetProductRecommendationsUseCase {
  const GetProductRecommendationsUseCase(
    this._repository,
    this._permissionService,
    this._analyticsService,
  );

  final ProductRecommendationRepository _repository;
  final PermissionService _permissionService;
  final AnalyticsService _analyticsService;

  Future<AppResult<ProductRecommendation?>> call({
    required String organizationId,
    required String companyId,
    required String requestedByUserId,
    required ProductRecommendationScopeType scopeType,
    required String scopeId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedRequestedByUserId = requestedByUserId.trim();
    final trimmedScopeId = scopeId.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (trimmedRequestedByUserId.isEmpty) {
      fieldErrors['requestedByUserId'] = 'RequestedByUserId is required.';
    }
    if (trimmedScopeId.isEmpty) {
      fieldErrors['scopeId'] = 'ScopeId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<ProductRecommendation?>(
        ValidationFailure(
          'Invalid product recommendation request.',
          fieldErrors: fieldErrors,
          code: 'invalid_product_recommendation_request',
        ),
      );
    }

    if (scopeType == ProductRecommendationScopeType.customer) {
      final permissionResult = await _permissionService.hasPermission(
        organizationId: trimmedOrganizationId,
        userId: trimmedRequestedByUserId,
        capability: Capability.customerView,
      );
      if (permissionResult is AppFailure<bool>) {
        return AppFailure<ProductRecommendation?>(permissionResult.failure);
      }
      if (!(permissionResult as AppSuccess<bool>).value) {
        return const AppFailure<ProductRecommendation?>(
          PermissionFailure(
            'User is not allowed to view this customer\'s recommendations.',
            code: 'product_recommendation_view_denied',
          ),
        );
      }
    }

    final result = await _repository.getRecommendation(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      scopeType: scopeType,
      scopeId: trimmedScopeId,
    );
    if (result case AppSuccess<ProductRecommendation?>()) {
      final recommendation = result.value;
      await _analyticsService.logEvent(
        AnalyticsEvents.productRecommendationsViewed,
        parameters: <String, Object?>{
          'organization_id': trimmedOrganizationId,
          'scope_type': scopeType.code,
          'scope_id': trimmedScopeId,
          'fallback_applied': recommendation?.fallbackApplied,
          'insufficient_data': recommendation?.insufficientData,
        },
      );
    }
    return result;
  }
}
