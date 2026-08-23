import '../dtos/user_role_update_result_dto.dart';

abstract interface class UserRoleDataSource {
  Future<UserRoleUpdateResultDto> updateUserRole({
    required String organizationId,
    required String targetUserId,
    required String roleName,
  });
}
