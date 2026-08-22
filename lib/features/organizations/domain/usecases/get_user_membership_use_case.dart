import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/membership.dart';
import '../repositories/membership_repository.dart';

/// Reads the [Membership] of [userId] within [organizationId] (`tasks.md`,
/// seção 3.3). A user only ever has access to an Organization through this
/// explicit link — never inferred by any other means.
@injectable
final class GetUserMembershipUseCase {
  const GetUserMembershipUseCase(this._repository);

  final MembershipRepository _repository;

  Future<AppResult<Membership>> call({
    required String organizationId,
    required String userId,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedUserId = userId.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedUserId.isEmpty) fieldErrors['userId'] = 'UserId is required.';

    if (fieldErrors.isNotEmpty) {
      return Future<AppResult<Membership>>.value(
        AppFailure<Membership>(
          ValidationFailure(
            'Invalid get-user-membership payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_get_user_membership_payload',
          ),
        ),
      );
    }

    return _repository.getByUser(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
    );
  }
}
