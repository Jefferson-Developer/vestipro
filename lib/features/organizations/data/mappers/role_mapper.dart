import 'package:injectable/injectable.dart';

import '../../domain/entities/role.dart';
import '../dtos/role_dto.dart';

@lazySingleton
final class RoleMapper {
  const RoleMapper();

  Role toEntity(RoleDto dto) {
    return Role(
      id: dto.id,
      organizationId: dto.organizationId,
      name: dto.name,
      isSystemRole: dto.isSystemRole,
      version: dto.version,
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      deletedAt: dto.deletedAt,
    );
  }

  RoleDto toDto(Role entity) {
    return RoleDto(
      id: entity.id,
      organizationId: entity.organizationId,
      name: entity.name,
      isSystemRole: entity.isSystemRole,
      version: entity.version,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      deletedAt: entity.deletedAt,
    );
  }
}
