import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/membership.dart';
import '../../domain/value_objects/membership_status.dart';
import '../dtos/membership_dto.dart';

@lazySingleton
final class MembershipMapper {
  const MembershipMapper();

  Membership toEntity(MembershipDto dto) {
    return Membership(
      id: dto.id,
      organizationId: dto.organizationId,
      userId: dto.userId,
      roleId: dto.roleId,
      roleName: dto.roleName,
      teamIds: dto.teamIds,
      status: statusToEntity(dto.status),
      version: dto.version,
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      deletedAt: dto.deletedAt,
    );
  }

  MembershipDto toDto(Membership entity) {
    return MembershipDto(
      id: entity.id,
      organizationId: entity.organizationId,
      userId: entity.userId,
      roleId: entity.roleId,
      roleName: entity.roleName,
      teamIds: entity.teamIds,
      status: statusToDto(entity.status),
      version: entity.version,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      deletedAt: entity.deletedAt,
    );
  }

  MembershipStatus statusToEntity(String value) {
    return switch (value) {
      'active' => MembershipStatus.active,
      'inactive' => MembershipStatus.inactive,
      _ => throw ValidationException(
        'Invalid membership status.',
        code: 'invalid_membership_status',
        cause: value,
      ),
    };
  }

  String statusToDto(MembershipStatus status) {
    return switch (status) {
      MembershipStatus.active => 'active',
      MembershipStatus.inactive => 'inactive',
    };
  }
}
