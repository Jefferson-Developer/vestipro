import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../invites/domain/role_hierarchy.dart';
import '../../domain/entities/user_role_update_result.dart';
import '../dtos/user_role_update_result_dto.dart';

@lazySingleton
final class UserRoleUpdateResultMapper {
  const UserRoleUpdateResultMapper();

  UserRoleUpdateResult toEntity(UserRoleUpdateResultDto dto) {
    final previousRole = systemRoleNameFromCode(dto.previousRoleName);
    final role = systemRoleNameFromCode(dto.roleName);
    if (previousRole == null || role == null) {
      throw const ServerException(
        'Unexpected user role callable response shape.',
        code: 'invalid_user_role_callable_response',
      );
    }

    return UserRoleUpdateResult(
      organizationId: dto.organizationId,
      targetUserId: dto.targetUserId,
      previousRoleName: previousRole,
      roleName: role,
      updatedAt: dto.updatedAt,
    );
  }
}
