import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../dtos/user_role_update_result_dto.dart';
import 'user_role_data_source.dart';

/// Cloud Functions-backed data source for sensitive user-role changes
/// (TASK-043). It never writes Firestore directly: `updateUserRole` is the
/// only authority for RBAC, last OWNER and central audit log.
@LazySingleton(as: UserRoleDataSource)
final class CloudFunctionsUserRoleDataSource implements UserRoleDataSource {
  const CloudFunctionsUserRoleDataSource(this._cloudFunctionsService);

  final CloudFunctionsService _cloudFunctionsService;

  @override
  Future<UserRoleUpdateResultDto> updateUserRole({
    required String organizationId,
    required String targetUserId,
    required String roleName,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'updateUserRole',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'targetUserId': targetUserId,
        'roleName': roleName,
      },
      requireAuth: true,
    );

    return UserRoleUpdateResultDto.fromCallableResponse(response);
  }
}
