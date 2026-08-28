import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../entities/stock_alert_page.dart';
import '../repositories/stock_alert_repository.dart';
import '../value_objects/stock_alert_level.dart';

@injectable
final class ListStockAlertsUseCase {
  const ListStockAlertsUseCase(this._repository, this._permissionService);

  final StockAlertRepository _repository;
  final PermissionService _permissionService;

  Future<AppResult<StockAlertPage>> call({
    required String organizationId,
    required String requestedByUserId,
    int limit = 25,
    DateTime? before,
    StockAlertLevel? level,
    String? productId,
    String? warehouseId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedRequestedByUserId = requestedByUserId.trim();
    final trimmedProductId = productId?.trim();
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
      return AppFailure<StockAlertPage>(
        ValidationFailure(
          'Invalid stock alert listing request.',
          fieldErrors: fieldErrors,
          code: 'invalid_stock_alert_list_request',
        ),
      );
    }

    final permissionResult = await _permissionService.hasPermission(
      organizationId: trimmedOrganizationId,
      userId: trimmedRequestedByUserId,
      capability: Capability.reportViewSensitive,
    );

    if (permissionResult is AppFailure<bool>) {
      return AppFailure<StockAlertPage>(permissionResult.failure);
    }

    final isAllowed = (permissionResult as AppSuccess<bool>).value;
    if (!isAllowed) {
      return AppFailure<StockAlertPage>(
        const PermissionFailure(
          'User is not allowed to view stock alerts.',
          code: 'stock_alert_view_denied',
        ),
      );
    }

    return _repository.listPageByOrganization(
      organizationId: trimmedOrganizationId,
      limit: limit,
      before: before,
      level: level,
      productId: trimmedProductId == null || trimmedProductId.isEmpty
          ? null
          : trimmedProductId,
      warehouseId: trimmedWarehouseId == null || trimmedWarehouseId.isEmpty
          ? null
          : trimmedWarehouseId,
    );
  }
}
