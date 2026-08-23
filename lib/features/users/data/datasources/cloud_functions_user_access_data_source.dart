import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../dtos/user_access_update_result_dto.dart';
import 'user_access_data_source.dart';

/// Cloud Functions-backed data source for sensitive user access changes
/// (TASK-046). It never writes Firestore directly: `deactivateUser` and
/// `reactivateUser` are the only authorities for RBAC, last OWNER,
/// refresh-token revocation and central audit log.
@LazySingleton(as: UserAccessDataSource)
final class CloudFunctionsUserAccessDataSource implements UserAccessDataSource {
  const CloudFunctionsUserAccessDataSource(this._cloudFunctionsService);

  final CloudFunctionsService _cloudFunctionsService;

  @override
  Future<UserAccessUpdateResultDto> deactivateUser({
    required String organizationId,
    required String targetUserId,
  }) {
    return _call(
      'deactivateUser',
      organizationId: organizationId,
      targetUserId: targetUserId,
    );
  }

  @override
  Future<UserAccessUpdateResultDto> reactivateUser({
    required String organizationId,
    required String targetUserId,
  }) {
    return _call(
      'reactivateUser',
      organizationId: organizationId,
      targetUserId: targetUserId,
    );
  }

  Future<UserAccessUpdateResultDto> _call(
    String functionName, {
    required String organizationId,
    required String targetUserId,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      functionName,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'targetUserId': targetUserId,
      },
      requireAuth: true,
    );

    return UserAccessUpdateResultDto.fromCallableResponse(response);
  }
}
