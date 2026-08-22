import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/team.dart';
import '../repositories/team_repository.dart';

/// Adds a user to a Team's [Team.memberIds] (`tasks.md`, seção 3.3).
///
/// Propagates whatever `Failure` the repository returns — a `NotFoundFailure`
/// when [id] does not identify an existing Team under [organizationId]
/// included — without any authorization check: whether the acting user is
/// allowed to manage this Team's membership is RBAC's job (TASK-029).
@injectable
final class AddUserToTeamUseCase {
  const AddUserToTeamUseCase(this._repository);

  final TeamRepository _repository;

  Future<AppResult<Team>> call({
    required String organizationId,
    required String id,
    required String userId,
    required String updatedBy,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedUserId = userId.trim();
    final trimmedUpdatedBy = updatedBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedUserId.isEmpty) fieldErrors['userId'] = 'UserId is required.';
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return Future<AppResult<Team>>.value(
        AppFailure<Team>(
          ValidationFailure(
            'Invalid add-user-to-team payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_add_user_to_team_payload',
          ),
        ),
      );
    }

    return _repository.addMember(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
      userId: trimmedUserId,
      updatedBy: trimmedUpdatedBy,
    );
  }
}
