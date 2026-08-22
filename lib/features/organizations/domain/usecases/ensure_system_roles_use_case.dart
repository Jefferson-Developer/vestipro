import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/role.dart';
import '../repositories/role_repository.dart';
import '../value_objects/system_role_name.dart';

/// Seeds the 7 initial system roles (`tasks.md`, seção 3.3) for one
/// Organization, so `AssignRoleToUserUseCase` always has a role to point a
/// [Membership] at.
///
/// Idempotent: only creates the [SystemRoleName]s missing from
/// [RoleRepository.listByOrganization] — calling it again for the same
/// Organization never duplicates nor renames an existing role. Meant to be
/// invoked once, right after `Organization.create` (TASK-037's onboarding
/// flow), without duplicating this seeding logic there.
@injectable
final class EnsureSystemRolesUseCase {
  const EnsureSystemRolesUseCase(this._repository);

  final RoleRepository _repository;

  Future<AppResult<List<Role>>> call({
    required String organizationId,
    required String createdBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCreatedBy = createdBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<List<Role>>(
        ValidationFailure(
          'Invalid system role seeding payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_ensure_system_roles_payload',
        ),
      );
    }

    final existingResult = await _repository.listByOrganization(
      trimmedOrganizationId,
    );
    if (existingResult is AppFailure<List<Role>>) {
      return existingResult;
    }

    final existing = (existingResult as AppSuccess<List<Role>>).value;
    final existingIds = existing.map((role) => role.id).toSet();

    final roles = List<Role>.of(existing);
    for (final systemRole in SystemRoleName.values) {
      if (existingIds.contains(systemRole.code)) continue;

      final createResult = await _repository.create(
        id: systemRole.code,
        organizationId: trimmedOrganizationId,
        name: systemRole.code,
        isSystemRole: true,
        createdBy: trimmedCreatedBy,
      );
      if (createResult is AppFailure<Role>) {
        return AppFailure<List<Role>>(createResult.failure);
      }
      roles.add((createResult as AppSuccess<Role>).value);
    }

    return AppSuccess<List<Role>>(roles);
  }
}
