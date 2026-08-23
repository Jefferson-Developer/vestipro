import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/team.dart';
import '../repositories/team_repository.dart';

@injectable
final class DeleteTeamUseCase {
  const DeleteTeamUseCase(this._repository);

  final TeamRepository _repository;

  Future<AppResult<Team>> call({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedDeletedBy = deletedBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedDeletedBy.isEmpty) {
      fieldErrors['deletedBy'] = 'DeletedBy is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<Team>(
        ValidationFailure(
          'Invalid delete-team payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_delete_team_payload',
        ),
      );
    }

    final linksResult = await _repository.hasCommercialLinks(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (linksResult case AppFailure<bool>(failure: final failure)) {
      return AppFailure<Team>(failure);
    }
    final hasLinks = (linksResult as AppSuccess<bool>).value;
    if (hasLinks) {
      return const AppFailure<Team>(
        ConflictFailure(
          'Team has linked customer portfolios or orders and must be '
          'reallocated before deletion.',
          code: 'team_has_commercial_links',
        ),
      );
    }

    return _repository.delete(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
      deletedBy: trimmedDeletedBy,
    );
  }
}
