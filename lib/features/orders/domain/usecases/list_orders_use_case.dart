import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/errors/errors.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../entities/order.dart';
import '../entities/order_list_filters.dart';
import '../entities/order_list_page_result.dart';
import '../entities/order_visibility_filter.dart';
import '../repositories/order_list_repository.dart';
import '../services/order_visibility_service.dart';

/// Lists the pedidos listing/tracking screen's server-side page (TASK-102):
/// combinable status/período/cliente/vendedor filters and cursor pagination,
/// scoped by [OrderVisibilityService] so a seller only ever sees their own
/// orders and a manager only the orders of the sellers under their own
/// teams — [Capability.orderView] is re-checked here as defense-in-depth,
/// same precedent `ListAuditLogEntriesUseCase`/`ListStockAlertsUseCase`
/// already follow; `firestore.rules` remains the real, independent source
/// of truth for both the capability and the seller-scope decision.
@injectable
final class ListOrdersUseCase {
  const ListOrdersUseCase(
    this._repository,
    this._visibilityService,
    this._permissionService,
  );

  final OrderListRepository _repository;
  final OrderVisibilityService _visibilityService;
  final PermissionService _permissionService;

  Future<AppResult<OrderListPageResult>> call({
    required String organizationId,
    required String companyId,
    required String userId,
    int limit = 20,
    DateTime? before,
    OrderListFilters filters = OrderListFilters.empty,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedUserId = userId.trim();
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
    if (limit <= 0 || limit > 100) {
      fieldErrors['limit'] = 'Limit must be between 1 and 100.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<OrderListPageResult>(
        ValidationFailure(
          'Invalid order listing payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_order_list_payload',
        ),
      );
    }

    final permissionResult = await _permissionService.hasPermission(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
      capability: Capability.orderView,
    );
    if (permissionResult is AppFailure<bool>) {
      return AppFailure<OrderListPageResult>(permissionResult.failure);
    }
    if (!(permissionResult as AppSuccess<bool>).value) {
      return const AppFailure<OrderListPageResult>(
        PermissionFailure(
          'User is not allowed to view orders.',
          code: 'order_view_denied',
        ),
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
      return AppFailure<OrderListPageResult>(failure);
    }
    final visibility =
        (visibilityResult as AppSuccess<OrderVisibilityFilter>).value;
    if (!visibility.canReadAny) {
      return const AppFailure<OrderListPageResult>(
        PermissionFailure(
          'User has no visible orders.',
          code: 'order_list_not_visible',
        ),
      );
    }

    final normalizedFilters = filters.normalized();
    final resolvedSellerIds = _resolveSellerIds(
      visibility: visibility,
      requestedSellerIds: normalizedFilters.sellerIds,
    );
    // A restricted visibility mode (everything but `allCompany`) resolving
    // to an empty seller set means "narrowed to nobody" (e.g. a manager
    // explicitly picked a seller outside their own teams) — it must never
    // fall through to an unfiltered, effectively organization-wide query.
    if (resolvedSellerIds.isEmpty &&
        visibility.mode != OrderVisibilityMode.allCompany) {
      return const AppSuccess<OrderListPageResult>(
        OrderListPageResult(orders: <Order>[], hasMore: false),
      );
    }

    return _repository.listPageByCompany(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      limit: limit,
      before: before,
      filters: normalizedFilters.copyWith(sellerIds: resolvedSellerIds),
    );
  }

  /// Never trusts [requestedSellerIds] (a raw UI selection) beyond what
  /// [visibility] itself already allows: [OrderVisibilityMode.ownOnly]
  /// always forces the caller's own id, [OrderVisibilityMode.sellerSubset]
  /// intersects the request with the manager's own visible sellers (an
  /// out-of-scope pick silently narrows to "nothing", never to "everyone"),
  /// and [OrderVisibilityMode.allCompany] passes an explicit pick through
  /// unrestricted.
  Set<String> _resolveSellerIds({
    required OrderVisibilityFilter visibility,
    required Set<String> requestedSellerIds,
  }) {
    return switch (visibility.mode) {
      OrderVisibilityMode.ownOnly => visibility.sellerIds,
      OrderVisibilityMode.sellerSubset =>
        requestedSellerIds.isEmpty
            ? visibility.sellerIds
            : requestedSellerIds.where(visibility.sellerIds.contains).toSet(),
      OrderVisibilityMode.allCompany => requestedSellerIds,
      OrderVisibilityMode.none => const <String>{},
    };
  }
}
