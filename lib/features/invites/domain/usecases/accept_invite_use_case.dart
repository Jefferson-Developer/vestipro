import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/accepted_invite.dart';
import '../repositories/invite_acceptance_repository.dart';

/// Accepts an invite [token] via [InviteAcceptanceRepository.accept]
/// (TASK-040) — the only client-side check is that a token was actually
/// provided; the real authorization (caller authenticated, e-mail matches
/// the invite, invite still valid) is always `acceptInvite`'s.
@injectable
final class AcceptInviteUseCase {
  const AcceptInviteUseCase(this._repository);

  final InviteAcceptanceRepository _repository;

  Future<AppResult<AcceptedInvite>> call({required String token}) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return Future<AppResult<AcceptedInvite>>.value(
        AppFailure<AcceptedInvite>(
          const ValidationFailure(
            'Token de convite ausente.',
            code: 'invite_token_required',
          ),
        ),
      );
    }

    return _repository.accept(token: trimmed);
  }
}
