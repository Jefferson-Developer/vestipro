import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../../domain/entities/invite.dart';
import '../../domain/value_objects/invite_status.dart';
import '../dtos/invite_dto.dart';

@lazySingleton
final class InviteMapper {
  const InviteMapper();

  Invite toEntity(InviteDto dto) {
    return Invite(
      id: dto.id,
      organizationId: dto.organizationId,
      email: dto.email,
      roleName: roleNameToEntity(dto.roleName),
      status: statusToEntity(dto.status),
      invitedByUserId: dto.invitedByUserId,
      invitedByName: dto.invitedByName,
      message: dto.message,
      expiresAt: dto.expiresAt,
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
    );
  }

  /// Parses the raw `Invite.roleName` string into a [SystemRoleName].
  /// Custom (non-system) roles are not modeled by invites yet — an unknown
  /// value throws [ValidationException] instead of silently defaulting to
  /// any particular role, same precedent as [statusToEntity].
  SystemRoleName roleNameToEntity(String value) {
    for (final role in SystemRoleName.values) {
      if (role.code == value) return role;
    }
    throw ValidationException(
      'Invalid invite roleName.',
      code: 'invalid_invite_role_name',
      cause: value,
    );
  }

  String roleNameToDto(SystemRoleName roleName) => roleName.code;

  InviteStatus statusToEntity(String value) {
    final status = inviteStatusFromCode(value);
    if (status == null) {
      throw ValidationException(
        'Invalid invite status.',
        code: 'invalid_invite_status',
        cause: value,
      );
    }
    return status;
  }

  String statusToDto(InviteStatus status) => status.code;
}
