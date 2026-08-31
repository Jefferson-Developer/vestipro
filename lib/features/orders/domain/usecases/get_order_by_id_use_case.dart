import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/errors/errors.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../entities/order.dart';
import '../entities/order_visibility_filter.dart';
import '../repositories/order_list_repository.dart';
import '../services/order_visibility_service.dart';

/// Fetches one Order fresh from Firestore by [orderId], scoped by
/// [OrderVisibilityService] exactly like `ListOrdersUseCase` (TASK-102) —
/// the single entry point TASK-104's history screen and "Repetir pedido"
/// flow both call, so neither has to re-derive who may see whose order.
///
/// [Capability.orderView] is re-checked here as defense-in-depth, same
/// precedent [ListOrdersUseCase] already follows; `firestore.rules`'
/// `canReadOrder` remains the real, independent source of truth for both the
/// capability and the seller-scope decision — this use case's own
/// visibility check only ever narrows what the UI is allowed to *request*,
/// never widens what Firestore actually returns.
// Deliberately not `final class`: `DuplicateOrderUseCase`'s own tests fake
// this class outright (`implements GetOrderByIdUseCase`), same precedent
// `StartOrderDraftForCustomerUseCase`/`AddItemsToOrderDraftUseCase` already
// set for a thin use case a composing use case/bloc calls directly.
@injectable
class GetOrderByIdUseCase {
  const GetOrderByIdUseCase(
    this._repository,
    this._visibilityService,
    this._permissionService,
  );

  final OrderListRepository _repository;
  final OrderVisibilityService _visibilityService;
  final PermissionService _permissionService;

  Future<AppResult<Order>> call({
    required String organizationId,
    required String companyId,
    required String userId,
    required String orderId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedUserId = userId.trim();
    final trimmedOrderId = orderId.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (trimmedUserId.isEmpty) {
      fieldErrors['userId'] = 'UserId is required.';
    }
    if (trimmedOrderId.isEmpty) {
      fieldErrors['orderId'] = 'OrderId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<Order>(
        ValidationFailure(
          'Invalid order lookup payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_order_get_by_id_payload',
        ),
      );
    }

    final permissionResult = await _permissionService.hasPermission(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
      capability: Capability.orderView,
    );
    if (permissionResult is AppFailure<bool>) {
      return AppFailure<Order>(permissionResult.failure);
    }
    if (!(permissionResult as AppSuccess<bool>).value) {
      return const AppFailure<Order>(
        PermissionFailure(
          'User is not allowed to view orders.',
          code: 'order_view_denied',
        ),
      );
    }

    final orderResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      id: trimmedOrderId,
    );
    if (orderResult case AppFailure<Order?>(failure: final failure)) {
      return AppFailure<Order>(failure);
    }
    final order = (orderResult as AppSuccess<Order?>).value;
    if (order == null) {
      return const AppFailure<Order>(
        NotFoundFailure('Order not found.', code: 'order_not_found'),
      );
    }

    final visibilityResult = await _visibilityService.resolve(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      userId: trimmedUserId,
    );
    if (visibilityResult case AppFailure<OrderVisibilityFilter>(
      failure: final failure,
    )) {
      return AppFailure<Order>(failure);
    }
    final visibility =
        (visibilityResult as AppSuccess<OrderVisibilityFilter>).value;
    if (!_isVisible(visibility, order)) {
      return const AppFailure<Order>(
        PermissionFailure(
          'User is not allowed to view this order.',
          code: 'order_not_visible',
        ),
      );
    }

    return AppSuccess<Order>(order);
  }

  bool _isVisible(OrderVisibilityFilter visibility, Order order) {
    return switch (visibility.mode) {
      OrderVisibilityMode.allCompany => true,
      OrderVisibilityMode.ownOnly || OrderVisibilityMode.sellerSubset =>
        visibility.sellerIds.contains(order.sellerId),
      OrderVisibilityMode.none => false,
    };
  }
}
