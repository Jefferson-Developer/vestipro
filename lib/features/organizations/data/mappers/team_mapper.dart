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
