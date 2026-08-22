import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/organizations/data/dtos/company_dto.dart';
import 'package:vestipro/features/organizations/data/mappers/company_mapper.dart';
import 'package:vestipro/features/organizations/organizations.dart';

void main() {
  group('CompanyMapper', () {
    const mapper = CompanyMapper();

    final dto = CompanyDto(
      id: 'company-1',
      organizationId: 'org-1',
      name: 'Marca A',
      legalName: 'Marca A Confecções Ltda',
      taxId: '12.345.678/0001-90',
      status: 'active',
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 2),
      updatedBy: 'user-2',
    );

    test('toEntity maps every field, including optional legalName/taxId', () {
      final entity = mapper.toEntity(dto);

      expect(entity.id, 'company-1');
      expect(entity.organizationId, 'org-1');
      expect(entity.name, 'Marca A');
      expect(entity.legalName, 'Marca A Confecções Ltda');
      expect(entity.taxId, '12.345.678/0001-90');
      expect(entity.status, CompanyStatus.active);
      expect(entity.version, 1);
      expect(entity.createdAt, DateTime.utc(2026, 1, 1));
      expect(entity.createdBy, 'user-1');
      expect(entity.updatedAt, DateTime.utc(2026, 1, 2));
      expect(entity.updatedBy, 'user-2');
      expect(entity.deletedAt, isNull);
    });

    test('toEntity maps a Company without legalName/taxId (both null)', () {
      final minimalDto = CompanyDto(
        id: dto.id,
        organizationId: dto.organizationId,
        name: dto.name,
        status: dto.status,
        version: dto.version,
        createdAt: dto.createdAt,
        createdBy: dto.createdBy,
        updatedAt: dto.updatedAt,
        updatedBy: dto.updatedBy,
      );

      final entity = mapper.toEntity(minimalDto);

      expect(entity.legalName, isNull);
      expect(entity.taxId, isNull);
    });

    test('toEntity maps a non-null deletedAt (soft-deleted company)', () {
      final deletedDto = CompanyDto(
        id: dto.id,
        organizationId: dto.organizationId,
        name: dto.name,
        status: 'suspended',
        version: dto.version,
        createdAt: dto.createdAt,
        createdBy: dto.createdBy,
        updatedAt: dto.updatedAt,
        updatedBy: dto.updatedBy,
        deletedAt: DateTime.utc(2026, 1, 3),
      );

      final entity = mapper.toEntity(deletedDto);

      expect(entity.status, CompanyStatus.suspended);
      expect(entity.deletedAt, DateTime.utc(2026, 1, 3));
    });

    test('toEntity throws ValidationException for an unknown status', () {
      final invalidDto = CompanyDto(
        id: dto.id,
        organizationId: dto.organizationId,
        name: dto.name,
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
      expect(roundTrippedDto.name, dto.name);
      expect(roundTrippedDto.legalName, dto.legalName);
      expect(roundTrippedDto.taxId, dto.taxId);
      expect(roundTrippedDto.status, dto.status);
      expect(roundTrippedDto.version, dto.version);
      expect(roundTrippedDto.createdAt, dto.createdAt);
      expect(roundTrippedDto.createdBy, dto.createdBy);
      expect(roundTrippedDto.updatedAt, dto.updatedAt);
      expect(roundTrippedDto.updatedBy, dto.updatedBy);
      expect(roundTrippedDto.deletedAt, dto.deletedAt);
    });
  });
}
