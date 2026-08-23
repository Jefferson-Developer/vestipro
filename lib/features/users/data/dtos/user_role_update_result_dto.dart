import '../../../../core/errors/errors.dart';

final class UserRoleUpdateResultDto {
  const UserRoleUpdateResultDto({
    required this.organizationId,
    required this.targetUserId,
    required this.previousRoleName,
    required this.roleName,
    required this.updatedAt,
  });

  final String organizationId;
  final String targetUserId;
  final String previousRoleName;
  final String roleName;
  final DateTime updatedAt;

  factory UserRoleUpdateResultDto.fromCallableResponse(
    Map<String, dynamic> json,
  ) {
    final organizationId = json['organizationId'];
    final targetUserId = json['targetUserId'];
    final previousRoleName = json['previousRoleName'];
    final roleName = json['roleName'];
    final updatedAt = json['updatedAt'];

    if (organizationId is! String ||
        targetUserId is! String ||
        previousRoleName is! String ||
        roleName is! String ||
        updatedAt is! String) {
      throw const ServerException(
        'Unexpected user role callable response shape.',
        code: 'invalid_user_role_callable_response',
      );
    }

    return UserRoleUpdateResultDto(
      organizationId: organizationId,
      targetUserId: targetUserId,
      previousRoleName: previousRoleName,
      roleName: roleName,
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
