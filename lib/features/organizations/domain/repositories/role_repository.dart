import '../../../../core/utils/utils.dart';
import '../entities/role.dart';

/// Contract for reading and writing [Role] documents scoped under one
/// [Organization] (TASK-028).
///
/// Every method requires [organizationId] so no query can be built without a
/// tenant scope by mistake — Firestore Security Rules (TASK-030) remain the
/// real source of truth for isolation, this is defense-in-depth only.
/// Deliberately narrow: there is no `update`/`delete` method, since system
/// roles ([Role.isSystemRole] `== true`) can never be renamed or excluded by
/// any use case of this feature (see [assertRoleIsMutable]).
abstract interface class RoleRepository {
  Future<AppResult<Role>> create({
    required String id,
    required String organizationId,
    required String name,
    required bool isSystemRole,
    required String createdBy,
  });

  /// Lists every non-deleted Role of [organizationId]. Never returns a Role
  /// belonging to a different organization.
  Future<AppResult<List<Role>>> listByOrganization(String organizationId);

  Future<AppResult<Role>> getById({
    required String organizationId,
    required String id,
  });
}
