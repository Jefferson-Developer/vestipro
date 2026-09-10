import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../entities/return_request_decision_result.dart';
import '../repositories/return_request_repository.dart';
import '../value_objects/return_request_status.dart';

/// Decides (aprova/recusa) a `ReturnRequest` still solicitada (TASK-199,
/// EPIC-30) — re-checks [Capability.returnRequestApprove] here as
/// defense-in-depth, same precedent every other decision use case in this
/// codebase already follows; `resolveReturnRequest` (Cloud Function) remains
/// the real, independent source of truth for both the capability and the
/// manager/team scope.
@injectable
final class ResolveReturnRequestUseCase {
  const ResolveReturnRequestUseCase(this._repository, this._permissionService);

  final ReturnRequestRepository _repository;
  final PermissionService _permissionService;

  Future<AppResult<ReturnRequestDecisionResult>> call({
    required String organizationId,
    required String companyId,
    required String userId,
    required String returnRequestId,
    required ReturnRequestDecisionValue decision,
    String? reason,
  }) async {
    if (decision == ReturnRequestDecisionValue.rejected &&
        (reason == null || reason.trim().isEmpty)) {
      return const AppFailure<ReturnRequestDecisionResult>(
        ValidationFailure(
          'É necessário informar o motivo da recusa.',
          fieldErrors: <String, String>{
            'reason': 'É necessário informar o motivo da recusa.',
          },
          code: 'return_request_rejection_reason_required',
        ),
      );
    }

    final permissionResult = await _permissionService.hasPermission(
      organizationId: organizationId,
      userId: userId,
      capability: Capability.returnRequestApprove,
    );
    if (permissionResult is AppFailure<bool>) {
      return AppFailure<ReturnRequestDecisionResult>(permissionResult.failure);
    }
    if (!(permissionResult as AppSuccess<bool>).value) {
      return const AppFailure<ReturnRequestDecisionResult>(
        PermissionFailure(
          'Seu perfil não pode decidir devoluções.',
          code: 'return_request_approve_denied',
        ),
      );
    }

    return _repository.resolveReturnRequest(
      organizationId: organizationId,
      companyId: companyId,
      returnRequestId: returnRequestId,
      decision: decision,
      reason: reason,
    );
  }
}
