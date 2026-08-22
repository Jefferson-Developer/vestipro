import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/organizations/data/dtos/role_dto.dart';
import 'package:vestipro/features/organizations/data/mappers/role_mapper.dart';

void main() {
  group('RoleMapper', () {
    const mapper = RoleMapper();

    final dto = RoleDto(
      id: 'OWNER',
      organizationId: 'org-1',
      name: 'OWNER',
      isSystemRole: true,
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 2),
      updatedBy: 'user-2',
    );

    test('toEntity maps every field', () {
      final entity = mapper.toEntity(dto);

      expect(entity.id, 'OWNER');
      expect(entity.organizationId, 'org-1');
      expect(entity.name, 'OWNER');
      expect(entity.isSystemRole, isTrue);
      expect(entity.version, 1);
      expect(entity.createdAt, DateTime.utc(2026, 1, 1));
      expect(entity.updatedBy, 'user-2');
      expect(entity.deletedAt, isNull);
    });

    test('toDto is the exact inverse of toEntity', () {
      final entity = mapper.toEntity(dto);
      final roundTrippedDto = mapper.toDto(entity);

      expect(roundTrippedDto.id, dto.id);
      expect(roundTrippedDto.organizationId, dto.organizationId);
      expect(roundTrippedDto.name, dto.name);
      expect(roundTrippedDto.isSystemRole, dto.isSystemRole);
      expect(roundTrippedDto.version, dto.version);
      expect(roundTrippedDto.createdAt, dto.createdAt);
      expect(roundTrippedDto.updatedBy, dto.updatedBy);
      expect(roundTrippedDto.deletedAt, dto.deletedAt);
    });

    test('toEntity maps a custom (non-system) role', () {
      final customDto = RoleDto(
        id: 'custom-role',
        organizationId: 'org-1',
        name: 'Custom Sales',
        isSystemRole: false,
        version: 1,
        createdAt: dto.createdAt,
        createdBy: dto.createdBy,
        updatedAt: dto.updatedAt,
        updatedBy: dto.updatedBy,
      );

      final entity = mapper.toEntity(customDto);

      expect(entity.isSystemRole, isFalse);
      expect(entity.name, 'Custom Sales');
    });
  });
}
