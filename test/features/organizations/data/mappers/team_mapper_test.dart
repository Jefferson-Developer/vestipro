import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/organizations/data/dtos/team_dto.dart';
import 'package:vestipro/features/organizations/data/mappers/team_mapper.dart';

void main() {
  group('TeamMapper', () {
    const mapper = TeamMapper();

    final dto = TeamDto(
      id: 'team-1',
      organizationId: 'org-1',
      name: 'Equipe Blumenau',
      memberIds: const <String>['user-1', 'user-2'],
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 2),
      updatedBy: 'user-2',
    );

    test('toEntity maps every field, including memberIds', () {
      final entity = mapper.toEntity(dto);

      expect(entity.id, 'team-1');
      expect(entity.organizationId, 'org-1');
      expect(entity.name, 'Equipe Blumenau');
      expect(entity.memberIds, <String>['user-1', 'user-2']);
      expect(entity.deletedAt, isNull);
    });

    test('toEntity maps a Team without members (empty memberIds)', () {
      final emptyDto = TeamDto(
        id: dto.id,
        organizationId: dto.organizationId,
        name: dto.name,
        version: dto.version,
        createdAt: dto.createdAt,
        createdBy: dto.createdBy,
        updatedAt: dto.updatedAt,
        updatedBy: dto.updatedBy,
      );

      final entity = mapper.toEntity(emptyDto);

      expect(entity.memberIds, isEmpty);
    });

    test('toDto is the exact inverse of toEntity', () {
      final entity = mapper.toEntity(dto);
      final roundTrippedDto = mapper.toDto(entity);

      expect(roundTrippedDto.id, dto.id);
      expect(roundTrippedDto.organizationId, dto.organizationId);
      expect(roundTrippedDto.memberIds, dto.memberIds);
      expect(roundTrippedDto.version, dto.version);
    });
  });
}
