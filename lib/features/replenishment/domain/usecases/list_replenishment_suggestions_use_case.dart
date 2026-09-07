import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../entities/replenishment_suggestion_page.dart';
import '../repositories/replenishment_repository.dart';
import '../value_objects/replenishment_suggestion_status.dart';

/// Lists `ReplenishmentSuggestion`s for one organization (TASK-184,
/// EPIC-27), gated by [Capability.reportViewSensitive] — the same
/// gestor-level capability `ListStockAlertsUseCase` already checks for the
/// sibling stock-alerts screen, since a replenishment suggestion is the same
/// class of sensitive, aggregated stock/commercial data.
@injectable
final class ListReplenishmentSuggestionsUseCase {
  const ListReplenishmentSuggestionsUseCase(
    this._repository,
    this._permissionService,
  );

  final ReplenishmentRepository _repository;
  final PermissionService _permissionService;

  Future<AppResult<ReplenishmentSuggestionPage>> call({
    required String organizationId,
    required String requestedByUserId,
    int limit = 25,
    DateTime? before,
    ReplenishmentSuggestionStatus? status,
    String? warehouseId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedRequestedByUserId = requestedByUserId.trim();
    final trimmedWarehouseId = warehouseId?.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedRequestedByUserId.isEmpty) {
      fieldErrors['requestedByUserId'] = 'RequestedByUserId is required.';
    }
    if (limit < 1 || limit > 100) {
      fieldErrors['limit'] = 'Limit must be between 1 and 100.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<ReplenishmentSuggestionPage>(
        ValidationFailure(
          'Invalid replenishment suggestion listing request.',
          fieldErrors: fieldErrors,
          code: 'invalid_replenishment_suggestion_list_request',
        ),
      );
    }

    final permissionResult = await _permissionService.hasPermission(
      organizationId: trimmedOrganizationId,
      userId: trimmedRequestedByUserId,
      capability: Capability.reportViewSensitive,
    );
    if (permissionResult is AppFailure<bool>) {
      return AppFailure<ReplenishmentSuggestionPage>(permissionResult.failure);
    }
    if (!(permissionResult as AppSuccess<bool>).value) {
      return const AppFailure<ReplenishmentSuggestionPage>(
        PermissionFailure(
          'User is not allowed to view replenishment suggestions.',
          code: 'replenishment_suggestion_view_denied',
        ),
      );
    }

    return _repository.listPageByOrganization(
      organizationId: trimmedOrganizationId,
      limit: limit,
      before: before,
      status: status,
      warehouseId: trimmedWarehouseId == null || trimmedWarehouseId.isEmpty
          ? null
          : trimmedWarehouseId,
    );
  }
}
