import '../dtos/user_access_update_result_dto.dart';

abstract interface class UserAccessDataSource {
  Future<UserAccessUpdateResultDto> deactivateUser({
    required String organizationId,
    required String targetUserId,
  });

  Future<UserAccessUpdateResultDto> reactivateUser({
    required String organizationId,
    required String targetUserId,
  });
}
