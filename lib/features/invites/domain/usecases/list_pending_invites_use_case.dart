import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/invite.dart';
import '../repositories/invite_repository.dart';

/// Lists every pending/expired invite of [organizationId], for
/// `InviteListPage` (TASK-039). Always scoped by [organizationId] — there is
/// no "list every invite across organizations" method anywhere in this
/// feature.
@injectable
final class ListPendingInvitesUseCase {
  const ListPendingInvitesUseCase(this._repository);

  final InviteRepository _repository;

  Future<AppResult<List<Invite>>> call(String organizationId) {
    final trimmedOrganizationId = organizationId.trim();

    if (trimmedOrganizationId.isEmpty) {
      return Future<AppResult<List<Invite>>>.value(
        AppFailure<List<Invite>>(
          const ValidationFailure(
            'OrganizationId is required.',
            code: 'invalid_invite_list_organization_id',
          ),
        ),
      );
    }

    return _repository.listPending(trimmedOrganizationId);
  }
}
