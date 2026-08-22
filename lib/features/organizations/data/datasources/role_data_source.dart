import '../dtos/role_dto.dart';

/// Data access contract for `organizations/{organizationId}/roles/{id}`
/// documents (TASK-028). [FirestoreRoleDataSource] is the only
/// implementation today.
abstract interface class RoleDataSource {
  Future<RoleDto> create(RoleDto dto);

  /// Lists every non-deleted Role document under [organizationId]. Never
  /// queries across organizations.
  Future<List<RoleDto>> listByOrganization(String organizationId);

  /// Returns `null` when no document exists for [id] under [organizationId].
  Future<RoleDto?> getById({
    required String organizationId,
    required String id,
  });
}
