import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../organizations/domain/value_objects/membership_status.dart';
import '../../domain/entities/user_access_update_result.dart';
import '../dtos/user_access_update_result_dto.dart';

@lazySingleton
final class UserAccessUpdateResultMapper {
  const UserAccessUpdateResultMapper();

  UserAccessUpdateResult toEntity(UserAccessUpdateResultDto dto) {
    return UserAccessUpdateResult(
      organizationId: dto.organizationId,
      targetUserId: dto.targetUserId,
      previousStatus: _statusFromDto(dto.previousStatus),
      status: _statusFromDto(dto.status),
      updatedAt: dto.updatedAt,
    );
  }

  MembershipStatus _statusFromDto(String status) {
    return switch (status) {
      'active' => MembershipStatus.active,
      'inactive' => MembershipStatus.inactive,
      _ => throw const ServerException(
        'Unexpected user access callable response shape.',
        code: 'invalid_user_access_callable_response',
      ),
    };
  }
}
