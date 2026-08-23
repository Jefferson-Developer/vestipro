import '../../../../core/errors/errors.dart';

final class UserAccessUpdateResultDto {
  const UserAccessUpdateResultDto({
    required this.organizationId,
    required this.targetUserId,
    required this.previousStatus,
    required this.status,
    required this.updatedAt,
  });

  final String organizationId;
  final String targetUserId;
  final String previousStatus;
  final String status;
  final DateTime updatedAt;

  factory UserAccessUpdateResultDto.fromCallableResponse(
    Map<String, dynamic> json,
  ) {
    final organizationId = json['organizationId'];
    final targetUserId = json['targetUserId'];
    final previousStatus = json['previousStatus'];
    final status = json['status'];
    final updatedAt = json['updatedAt'];

    if (organizationId is! String ||
        targetUserId is! String ||
        previousStatus is! String ||
        status is! String ||
        updatedAt is! String) {
      throw const ServerException(
        'Unexpected user access callable response shape.',
        code: 'invalid_user_access_callable_response',
      );
    }

    return UserAccessUpdateResultDto(
      organizationId: organizationId,
      targetUserId: targetUserId,
      previousStatus: previousStatus,
      status: status,
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
