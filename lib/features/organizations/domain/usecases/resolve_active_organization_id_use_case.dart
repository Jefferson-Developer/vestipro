import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../repositories/membership_repository.dart';

/// Resolves the single Organization a signed-in [userId] should land on
/// right after authenticating — post-login redirect (`LoginBloc`) and
/// [ActiveOrganizationGuard]'s self-heal both depend on this instead of
/// hardcoding a placeholder `organizationId` (`kPlaceholderOrganizationId`).
///
/// Returns `null` (never a failure) when [userId] has no active Membership
/// anywhere yet — the caller's cue to send them through onboarding instead
/// of a real Organization, not an error condition.
///
/// A user with more than one active Membership is a real (if rare) case
/// this use case does not attempt to resolve on its own: no
/// multi-organization switcher exists yet (out of scope, see `tasks.md`), so
/// it deterministically picks the oldest Membership (`createdAt` ascending —
/// typically the Organization the user originally onboarded/was first
/// invited into) and never crashes or returns an ambiguous result.
@injectable
final class ResolveActiveOrganizationIdUseCase {
  const ResolveActiveOrganizationIdUseCase(this._repository);

  final MembershipRepository _repository;

  Future<AppResult<String?>> call({required String userId}) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      return AppFailure<String?>(
        const ValidationFailure(
          'Invalid resolve-active-organization payload.',
          fieldErrors: <String, String>{'userId': 'UserId is required.'},
          code: 'invalid_resolve_active_organization_payload',
        ),
      );
    }

    final result = await _repository.listActiveByUser(trimmedUserId);

    return result.fold(
      onSuccess: (memberships) {
        if (memberships.isEmpty) return const AppSuccess<String?>(null);

        final sortedByOldestFirst = [...memberships]
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return AppSuccess<String?>(sortedByOldestFirst.first.organizationId);
      },
      onFailure: AppFailure<String?>.new,
    );
  }
}
