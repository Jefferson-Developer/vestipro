import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../entities/user_role_update_result.dart';
import '../repositories/user_role_repository.dart';

/// Updates one organization user's role through the server-side
/// `updateUserRole` callable (TASK-043).
///
/// Client-side validation here is only shape/blank-field validation. RBAC,
/// role hierarchy, last active OWNER and audit log guarantees are deliberately
/// left to the Cloud Function.
@injectable
final class UpdateUserRoleUseCase {
  const UpdateUserRoleUseCase(this._repository);

  final UserRoleRepository _repository;

  Future<AppResult<UserRoleUpdateResult>> call({
    required String organizationId,
    required String targetUserId,
    required SystemRoleName roleName,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedTargetUserId = targetUserId.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedTargetUserId.isEmpty) {
      fieldErrors['targetUserId'] = 'TargetUserId is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return Future<AppResult<UserRoleUpdateResult>>.value(
        AppFailure<UserRoleUpdateResult>(
          ValidationFailure(
            'Invalid user role update payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_update_user_role_payload',
          ),
        ),
      );
    }

    return _repository.updateUserRole(
      organizationId: trimmedOrganizationId,
      targetUserId: trimmedTargetUserId,
      roleName: roleName,
    );
  }
}
