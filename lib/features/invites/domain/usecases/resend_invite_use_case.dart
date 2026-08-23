import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/issued_invite.dart';
import '../repositories/invite_repository.dart';

/// Reissues [inviteId] of [organizationId] with a brand-new token/hash and
/// `expiresAt`, invalidating the previous token (TASK-039). Only a
/// pending/expired invite can actually be resent — enforced by
/// [InviteRepository.resend] (ultimately `resendInvite`), not this use case.
@injectable
final class ResendInviteUseCase {
  const ResendInviteUseCase(this._repository);

  final InviteRepository _repository;

  Future<AppResult<IssuedInvite>> call({
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
      return Future<AppResult<IssuedInvite>>.value(
        AppFailure<IssuedInvite>(
          ValidationFailure(
            'Invalid resend invite payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_resend_invite_payload',
          ),
        ),
      );
    }

    return _repository.resend(
      organizationId: trimmedOrganizationId,
      inviteId: trimmedInviteId,
    );
  }
}
