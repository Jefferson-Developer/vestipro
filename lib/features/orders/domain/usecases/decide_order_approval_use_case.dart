import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../entities/order_approval_decision.dart';
import '../entities/order_approval_decision_result.dart';
import '../repositories/order_approval_repository.dart';

/// Approves or rejects a pedido routed to `underReview` (EPIC-13, TASK-103),
/// through the idempotent `decideOrderApproval` Cloud Function — the one and
/// only place this decision is authorized/persisted; nothing here decides
/// RBAC or the resulting `Order.status` itself, both are re-validated
/// server-side.
///
/// [Capability.orderApprove] is re-checked here as defense-in-depth (same
/// precedent `ListOrdersUseCase` already sets for `Capability.orderView`) —
/// `firestore.rules`/`decideOrderApproval` remain the real, independent
/// source of truth for both the capability and the "própria equipe" scope
/// decision for a `SALES_MANAGER`.
///
/// A rejection without a non-blank [reason] never reaches the Cloud
/// Function at all: `tasks.md`'s own "pedido rejeitado retorna ao vendedor
/// com o motivo" is a mandatory field, not an optional courtesy, so it is
/// validated here the same way every other required-field domain rule in
/// this codebase is (`OrderSubmissionValidator`), before any network call.
@injectable
final class DecideOrderApprovalUseCase {
  const DecideOrderApprovalUseCase(
    this._repository,
    this._permissionService,
    this._analyticsService,
  );

  final OrderApprovalRepository _repository;
  final PermissionService _permissionService;
  final AnalyticsService _analyticsService;

  Future<AppResult<OrderApprovalDecisionResult>> call({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String userId,
    required OrderApprovalDecisionValue decision,
    String? reason,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedOrderId = orderId.trim();
    final trimmedUserId = userId.trim();
    final trimmedReason = reason?.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (trimmedOrderId.isEmpty) {
      fieldErrors['orderId'] = 'OrderId is required.';
    }
    if (trimmedUserId.isEmpty) {
      fieldErrors['userId'] = 'UserId is required.';
    }
    if (decision == OrderApprovalDecisionValue.rejected &&
        (trimmedReason == null || trimmedReason.isEmpty)) {
      fieldErrors['reason'] = 'Informe o motivo da rejeição.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<OrderApprovalDecisionResult>(
        ValidationFailure(
          'Invalid order approval decision payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_order_approval_decision_payload',
        ),
      );
    }

    final permissionResult = await _permissionService.hasPermission(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
      capability: Capability.orderApprove,
    );
    if (permissionResult is AppFailure<bool>) {
      return AppFailure<OrderApprovalDecisionResult>(permissionResult.failure);
    }
    if (!(permissionResult as AppSuccess<bool>).value) {
      return const AppFailure<OrderApprovalDecisionResult>(
        PermissionFailure(
          'User is not allowed to approve orders.',
          code: 'order_approve_denied',
        ),
      );
    }

    final result = await _repository.decide(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      orderId: trimmedOrderId,
      decision: decision,
      reason: trimmedReason == null || trimmedReason.isEmpty
          ? null
          : trimmedReason,
    );
    if (result case AppSuccess<OrderApprovalDecisionResult>(
      value: final decided,
    )) {
      await _analyticsService.logEvent(
        decision == OrderApprovalDecisionValue.approved
            ? AnalyticsEvents.orderApproved
            : AnalyticsEvents.orderRejected,
        parameters: <String, Object?>{
          'organization_id': trimmedOrganizationId,
          'company_id': trimmedCompanyId,
          'order_id': decided.orderId,
        },
      );
    }
    return result;
  }
}
