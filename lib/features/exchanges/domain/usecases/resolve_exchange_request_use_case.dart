import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../entities/exchange_request_decision_result.dart';
import '../repositories/exchange_request_repository.dart';
import '../value_objects/exchange_request_status.dart';

/// Decides (aprova/recusa) an `ExchangeRequest` still solicitada (TASK-200,
/// EPIC-30) — re-checks [Capability.exchangeRequestApprove] here as
/// defense-in-depth, same precedent `ResolveReturnRequestUseCase` (TASK-199)
/// already follows; `resolveExchangeRequest` (Cloud Function) remains the
/// real, independent source of truth for both the capability and the
/// manager/team scope, plus the destination variant's real-time
/// availability revalidation.
@injectable
final class ResolveExchangeRequestUseCase {
  const ResolveExchangeRequestUseCase(
    this._repository,
    this._permissionService,
  );

  final ExchangeRequestRepository _repository;
  final PermissionService _permissionService;

  Future<AppResult<ExchangeRequestDecisionResult>> call({
    required String organizationId,
    required String companyId,
    required String userId,
    required String exchangeRequestId,
    required ExchangeRequestDecisionValue decision,
    String? reason,
  }) async {
    if (decision == ExchangeRequestDecisionValue.rejected &&
        (reason == null || reason.trim().isEmpty)) {
      return const AppFailure<ExchangeRequestDecisionResult>(
        ValidationFailure(
          'É necessário informar o motivo da recusa.',
          fieldErrors: <String, String>{
            'reason': 'É necessário informar o motivo da recusa.',
          },
          code: 'exchange_request_rejection_reason_required',
        ),
      );
    }

    final permissionResult = await _permissionService.hasPermission(
      organizationId: organizationId,
      userId: userId,
      capability: Capability.exchangeRequestApprove,
    );
    if (permissionResult is AppFailure<bool>) {
      return AppFailure<ExchangeRequestDecisionResult>(
        permissionResult.failure,
      );
    }
    if (!(permissionResult as AppSuccess<bool>).value) {
      return const AppFailure<ExchangeRequestDecisionResult>(
        PermissionFailure(
          'Seu perfil não pode decidir trocas.',
          code: 'exchange_request_approve_denied',
        ),
      );
    }

    return _repository.resolveExchangeRequest(
      organizationId: organizationId,
      companyId: companyId,
      exchangeRequestId: exchangeRequestId,
      decision: decision,
      reason: reason,
    );
  }
}
