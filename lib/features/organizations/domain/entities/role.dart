import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/errors.dart';

part 'role.freezed.dart';

/// A permission profile scoped to one [Organization] (`tasks.md`, seção
/// 3.3): one of the 7 built-in system roles (`OWNER`, `ADMIN`,
/// `SALES_MANAGER`, `SALES_REP`, `SALES_ASSISTANT`, `FINANCE`, `READ_ONLY`)
/// or, in the future, a custom role created by an `OWNER`/`ADMIN`.
///
/// [isSystemRole] roles are seeded automatically for every Organization (see
/// `EnsureSystemRolesUseCase`) and — per [assertRoleIsMutable] — can never be
/// deleted or renamed by any use case. What each role is actually allowed to
/// do is modeled in TASK-029 (RBAC), not here: this task only models the
/// data and its immutability invariant.
@freezed
abstract class Role with _$Role {
  const factory Role({
    required String id,
    required String organizationId,
    required String name,
    required bool isSystemRole,
    required int version,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    DateTime? deletedAt,
  }) = _Role;
}

/// Throws a [ForbiddenException] when [role] is a system role
/// ([Role.isSystemRole] `== true`) — the 7 initial profiles (`tasks.md`,
/// seção 3.3) must always exist, unmodified, for RBAC (TASK-029) and
/// Security Rules (TASK-030) to rely on. Does nothing for a custom
/// (non-system) role, which future rename/delete use cases may call before
/// mutating it.
void assertRoleIsMutable(Role role) {
  if (role.isSystemRole) {
    throw ForbiddenException(
      'System roles cannot be deleted or renamed.',
      code: 'system_role_immutable',
      cause: role.name,
    );
  }
}
