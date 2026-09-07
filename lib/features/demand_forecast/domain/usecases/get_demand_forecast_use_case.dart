import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../entities/demand_forecast.dart';
import '../repositories/demand_forecast_repository.dart';
import '../value_objects/demand_forecast_scope_type.dart';
import '../value_objects/demand_forecast_status.dart';

/// Reads the latest `DemandForecast` for one produto/coleção/região
/// (TASK-185, EPIC-27), gated by [Capability.reportViewSensitive] — same
/// gestor-level capability `ListReplenishmentSuggestionsUseCase` (TASK-184)
/// already checks, since both read the same class of sensitive, aggregated
/// planning data.
@injectable
final class GetDemandForecastUseCase {
  const GetDemandForecastUseCase(
    this._repository,
    this._permissionService,
    this._analyticsService,
  );

  final DemandForecastRepository _repository;
  final PermissionService _permissionService;
  final AnalyticsService _analyticsService;

  Future<AppResult<DemandForecast?>> call({
    required String organizationId,
    required String companyId,
    required String requestedByUserId,
    required DemandForecastScopeType scopeType,
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
      return AppFailure<DemandForecast?>(
        ValidationFailure(
          'Invalid demand forecast request.',
          fieldErrors: fieldErrors,
          code: 'invalid_demand_forecast_request',
        ),
      );
    }

    final permissionResult = await _permissionService.hasPermission(
      organizationId: trimmedOrganizationId,
      userId: trimmedRequestedByUserId,
      capability: Capability.reportViewSensitive,
    );
    if (permissionResult is AppFailure<bool>) {
      return AppFailure<DemandForecast?>(permissionResult.failure);
    }
    if (!(permissionResult as AppSuccess<bool>).value) {
      return const AppFailure<DemandForecast?>(
        PermissionFailure(
          'User is not allowed to view demand forecasts.',
          code: 'demand_forecast_view_denied',
        ),
      );
    }

    final result = await _repository.getLatestForecast(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      scopeType: scopeType,
      scopeId: trimmedScopeId,
    );
    if (result case AppSuccess<DemandForecast?>()) {
      await _analyticsService.logEvent(
        AnalyticsEvents.demandForecastViewed,
        parameters: <String, Object?>{
          'organization_id': trimmedOrganizationId,
          'scope_type': scopeType.code,
          'scope_id': trimmedScopeId,
          'status': result.value?.status.code,
        },
      );
    }
    return result;
  }
}
