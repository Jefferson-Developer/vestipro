import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/team.dart';
import '../repositories/team_repository.dart';

/// Creates a Team under an Organization (`tasks.md`, seção 3.3).
///
/// [id] must be generated once by the caller and kept stable across retries
/// — mirrors `CreateCompanyUseCase` so a retried create after a network
/// failure does not depend on this use case to stay idempotent.
@injectable
final class CreateTeamUseCase {
  const CreateTeamUseCase(this._repository);

  final TeamRepository _repository;

  Future<AppResult<Team>> call({
    required String id,
    required String organizationId,
    required String name,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedName = name.trim();
    final trimmedCreatedBy = createdBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedName.isEmpty) fieldErrors['name'] = 'Name is required.';
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Team>(
        ValidationFailure(
          'Invalid team creation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_team_create_payload',
        ),
      );
    }

    return _repository.create(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      name: trimmedName,
      createdBy: trimmedCreatedBy,
    );
  }
}
