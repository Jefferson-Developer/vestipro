import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/invite_preview.dart';
import '../repositories/invite_acceptance_repository.dart';

/// Validates an invite [token] against
/// [InviteAcceptanceRepository.validate] (TASK-040) — the only client-side
/// check is that a token was actually provided; every other decision
/// (unknown/expired/accepted/revoked/valid) is the repository's (ultimately
/// `validateInvite`'s).
@injectable
final class ValidateInviteUseCase {
  const ValidateInviteUseCase(this._repository);

  final InviteAcceptanceRepository _repository;

  Future<AppResult<InvitePreview>> call({required String token}) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return Future<AppResult<InvitePreview>>.value(
        AppFailure<InvitePreview>(
          const ValidationFailure(
            'Token de convite ausente.',
            code: 'invite_token_required',
          ),
        ),
      );
    }

    return _repository.validate(token: trimmed);
  }
}
