import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/invite.dart';
import '../repositories/invite_repository.dart';

/// Revokes [inviteId] of [organizationId] (TASK-039). Only a pending invite
/// can actually be revoked — enforced by [InviteRepository.revoke]
/// (ultimately `revokeInvite`), not this use case.
@injectable
final class RevokeInviteUseCase {
  const RevokeInviteUseCase(this._repository);

  final InviteRepository _repository;

  Future<AppResult<Invite>> call({
    required String organizationId,
    required String inviteId,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedInviteId = inviteId.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedInviteId.isEmpty) {
      fieldErrors['inviteId'] = 'InviteId is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return Future<AppResult<Invite>>.value(
        AppFailure<Invite>(
          ValidationFailure(
            'Invalid revoke invite payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_revoke_invite_payload',
          ),
        ),
      );
    }

    return _repository.revoke(
      organizationId: trimmedOrganizationId,
      inviteId: trimmedInviteId,
    );
  }
}
