import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/membership.dart';
import '../repositories/membership_repository.dart';

/// Assigns [roleId]/[roleName] to [userId] within [organizationId]
/// (`tasks.md`, seção 3.3): creates a brand new [Membership] when the user
/// has none yet, or updates the [roleId]/[roleName] of the existing one
/// otherwise — [Membership.teamIds] and [Membership.status] are preserved
/// as-is in that case.
///
/// Whether the acting user ([updatedBy]) is allowed to grant [roleId] is
/// RBAC's job (TASK-029), not this use case's — every `Failure` returned by
/// the repository (including a `NotFoundFailure` when [organizationId]
/// itself does not exist) is propagated unchanged.
@injectable
final class AssignRoleToUserUseCase {
  const AssignRoleToUserUseCase(this._repository);

  final MembershipRepository _repository;

  Future<AppResult<Membership>> call({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedUserId = userId.trim();
    final trimmedRoleId = roleId.trim();
    final trimmedRoleName = roleName.trim();
    final trimmedUpdatedBy = updatedBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedUserId.isEmpty) fieldErrors['userId'] = 'UserId is required.';
    if (trimmedRoleId.isEmpty) fieldErrors['roleId'] = 'RoleId is required.';
    if (trimmedRoleName.isEmpty) {
      fieldErrors['roleName'] = 'RoleName is required.';
    }
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Membership>(
        ValidationFailure(
          'Invalid assign-role-to-user payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_assign_role_to_user_payload',
        ),
      );
    }

    final currentResult = await _repository.getByUser(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
    );

    if (currentResult is AppFailure<Membership>) {
      if (currentResult.failure is! NotFoundFailure) {
        return currentResult;
      }

      return _repository.create(
        organizationId: trimmedOrganizationId,
        userId: trimmedUserId,
        roleId: trimmedRoleId,
        roleName: trimmedRoleName,
        createdBy: trimmedUpdatedBy,
      );
    }

    final current = (currentResult as AppSuccess<Membership>).value;
    return _repository.update(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
      roleId: trimmedRoleId,
      roleName: trimmedRoleName,
      teamIds: current.teamIds,
      status: current.status,
      updatedBy: trimmedUpdatedBy,
    );
  }
}
