import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/user_access_update_result.dart';
import '../repositories/user_access_repository.dart';

/// Reactivates one organization Membership through the server-side
/// `reactivateUser` callable (TASK-046). It is intentionally symmetric with
/// [DeactivateUserUseCase]: validation is client-side shape only, while RBAC
/// and audit remain server-side.
@injectable
final class ReactivateUserUseCase {
  const ReactivateUserUseCase(this._repository);

  final UserAccessRepository _repository;

  Future<AppResult<UserAccessUpdateResult>> call({
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
    if (fieldErrors.isNotEmpty) {
      return Future<AppResult<UserAccessUpdateResult>>.value(
        AppFailure<UserAccessUpdateResult>(
          ValidationFailure(
            'Invalid reactivate user payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_reactivate_user_payload',
          ),
        ),
      );
    }

    return _repository.reactivateUser(
      organizationId: organizationId.trim(),
      targetUserId: targetUserId.trim(),
    );
  }
}
