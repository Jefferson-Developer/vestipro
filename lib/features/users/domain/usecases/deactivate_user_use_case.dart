import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/user_access_update_result.dart';
import '../repositories/user_access_repository.dart';

/// Deactivates one organization Membership through the server-side
/// `deactivateUser` callable (TASK-046).
///
/// Client-side validation here is only shape/blank-field validation. RBAC,
/// last active OWNER, history preservation, token revocation and audit log
/// guarantees are deliberately left to the Cloud Function.
@injectable
final class DeactivateUserUseCase {
  const DeactivateUserUseCase(this._repository);

  final UserAccessRepository _repository;

  Future<AppResult<UserAccessUpdateResult>> call({
    required String organizationId,
    required String targetUserId,
  }) {
    final fieldErrors = _validateIds(
      organizationId: organizationId,
      targetUserId: targetUserId,
    );
    if (fieldErrors.isNotEmpty) {
      return Future<AppResult<UserAccessUpdateResult>>.value(
        AppFailure<UserAccessUpdateResult>(
          ValidationFailure(
            'Invalid deactivate user payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_deactivate_user_payload',
          ),
        ),
      );
    }

    return _repository.deactivateUser(
      organizationId: organizationId.trim(),
      targetUserId: targetUserId.trim(),
    );
  }
}

Map<String, String> _validateIds({
  required String organizationId,
  required String targetUserId,
}) {
  final fieldErrors = <String, String>{};
  if (organizationId.trim().isEmpty) {
    fieldErrors['organizationId'] = 'OrganizationId is required.';
  }
  if (targetUserId.trim().isEmpty) {
    fieldErrors['targetUserId'] = 'TargetUserId is required.';
  }
  return fieldErrors;
}
