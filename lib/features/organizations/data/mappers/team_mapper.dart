import 'package:injectable/injectable.dart';

import '../../domain/entities/team.dart';
import '../dtos/team_dto.dart';

@lazySingleton
final class TeamMapper {
  const TeamMapper();

  Team toEntity(TeamDto dto) {
    return Team(
      id: dto.id,
      organizationId: dto.organizationId,
      name: dto.name,
      companyId: dto.companyId,
      branchId: dto.branchId,
      managerUserId: dto.managerUserId,
      memberIds: dto.memberIds,
      version: dto.version,
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      deletedAt: dto.deletedAt,
    );
  }

  TeamDto toDto(Team entity) {
    return TeamDto(
      id: entity.id,
      organizationId: entity.organizationId,
      name: entity.name,
      companyId: entity.companyId,
      branchId: entity.branchId,
      managerUserId: entity.managerUserId,
      memberIds: entity.memberIds,
      version: entity.version,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      deletedAt: entity.deletedAt,
    );
  }
}
