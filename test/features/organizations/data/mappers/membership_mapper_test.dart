import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/organizations/data/dtos/membership_dto.dart';
import 'package:vestipro/features/organizations/data/mappers/membership_mapper.dart';
import 'package:vestipro/features/organizations/organizations.dart';

void main() {
  group('MembershipMapper', () {
    const mapper = MembershipMapper();

    final dto = MembershipDto(
      id: 'user-1',
      organizationId: 'org-1',
      userId: 'user-1',
      roleId: 'SALES_REP',
      roleName: 'SALES_REP',
      teamIds: const <String>['team-1'],
      status: 'active',
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 2),
      updatedBy: 'user-2',
    );

    test('toEntity maps every field, including status and teamIds', () {
      final entity = mapper.toEntity(dto);

      expect(entity.id, 'user-1');
      expect(entity.organizationId, 'org-1');
      expect(entity.userId, 'user-1');
      expect(entity.roleId, 'SALES_REP');
      expect(entity.teamIds, <String>['team-1']);
      expect(entity.status, MembershipStatus.active);
      expect(entity.deletedAt, isNull);
    });

    test('toEntity maps an inactive membership', () {
      final inactiveDto = MembershipDto(
        id: dto.id,
        organizationId: dto.organizationId,
        userId: dto.userId,
        roleId: dto.roleId,
        roleName: dto.roleName,
        status: 'inactive',
        version: dto.version,
        createdAt: dto.createdAt,
        createdBy: dto.createdBy,
        updatedAt: dto.updatedAt,
        updatedBy: dto.updatedBy,
      );

      final entity = mapper.toEntity(inactiveDto);

      expect(entity.status, MembershipStatus.inactive);
      expect(entity.teamIds, isEmpty);
    });

    test('toEntity throws ValidationException for an unknown status', () {
      final invalidDto = MembershipDto(
        id: dto.id,
        organizationId: dto.organizationId,
        userId: dto.userId,
        roleId: dto.roleId,
        roleName: dto.roleName,
        status: 'archived',
        version: dto.version,
        createdAt: dto.createdAt,
        createdBy: dto.createdBy,
        updatedAt: dto.updatedAt,
        updatedBy: dto.updatedBy,
      );

      expect(
        () => mapper.toEntity(invalidDto),
        throwsA(isA<ValidationException>()),
      );
    });

    test('toDto is the exact inverse of toEntity', () {
      final entity = mapper.toEntity(dto);
      final roundTrippedDto = mapper.toDto(entity);

      expect(roundTrippedDto.id, dto.id);
      expect(roundTrippedDto.organizationId, dto.organizationId);
      expect(roundTrippedDto.userId, dto.userId);
      expect(roundTrippedDto.roleId, dto.roleId);
      expect(roundTrippedDto.teamIds, dto.teamIds);
      expect(roundTrippedDto.status, dto.status);
    });

    test('toEntity/toDto pass the denormalized name/email through unchanged '
        '(TASK-042)', () {
      final dtoWithDisplayFields = MembershipDto(
        id: dto.id,
        organizationId: dto.organizationId,
        userId: dto.userId,
        roleId: dto.roleId,
        roleName: dto.roleName,
        teamIds: dto.teamIds,
        status: dto.status,
        version: dto.version,
        createdAt: dto.createdAt,
        createdBy: dto.createdBy,
        updatedAt: dto.updatedAt,
        updatedBy: dto.updatedBy,
        name: 'Ana Souza',
        email: 'ana@vestipro.com.br',
      );

      final entity = mapper.toEntity(dtoWithDisplayFields);
      expect(entity.name, 'Ana Souza');
      expect(entity.email, 'ana@vestipro.com.br');

      final roundTrippedDto = mapper.toDto(entity);
      expect(roundTrippedDto.name, 'Ana Souza');
      expect(roundTrippedDto.email, 'ana@vestipro.com.br');
    });

    test('toEntity defaults name/email to null when the DTO omits them '
        '(TASK-042)', () {
      final entity = mapper.toEntity(dto);

      expect(entity.name, isNull);
      expect(entity.email, isNull);
    });
  });
}
