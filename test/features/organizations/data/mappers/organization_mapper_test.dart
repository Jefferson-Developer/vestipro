import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/organizations/data/dtos/organization_dto.dart';
import 'package:vestipro/features/organizations/data/dtos/organization_settings_dto.dart';
import 'package:vestipro/features/organizations/data/mappers/organization_mapper.dart';
import 'package:vestipro/features/organizations/organizations.dart';

void main() {
  group('OrganizationMapper', () {
    const mapper = OrganizationMapper();

    final dto = OrganizationDto(
      id: 'org-1',
      name: 'Grupo Fashion XPTO',
      slug: 'grupo-fashion-xpto',
      settings: const OrganizationSettingsDto(
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
      ),
      status: 'active',
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 2),
      updatedBy: 'user-2',
    );

    test('toEntity maps every field, including a null deletedAt', () {
      final entity = mapper.toEntity(dto);

      expect(entity.id, 'org-1');
      expect(entity.name, 'Grupo Fashion XPTO');
      expect(entity.slug, 'grupo-fashion-xpto');
      expect(entity.settings.currency, 'BRL');
      expect(entity.settings.country, 'BR');
      expect(entity.settings.defaultLanguage, 'pt-BR');
      expect(entity.status, OrganizationStatus.active);
      expect(entity.createdAt, DateTime.utc(2026, 1, 1));
      expect(entity.createdBy, 'user-1');
      expect(entity.updatedAt, DateTime.utc(2026, 1, 2));
      expect(entity.updatedBy, 'user-2');
      expect(entity.deletedAt, isNull);
    });

    test('toEntity maps a non-null deletedAt (soft-deleted organization)', () {
      final deletedDto = OrganizationDto(
        id: dto.id,
        name: dto.name,
        slug: dto.slug,
        settings: dto.settings,
        status: 'suspended',
        createdAt: dto.createdAt,
        createdBy: dto.createdBy,
        updatedAt: dto.updatedAt,
        updatedBy: dto.updatedBy,
        deletedAt: DateTime.utc(2026, 1, 3),
      );

      final entity = mapper.toEntity(deletedDto);

      expect(entity.status, OrganizationStatus.suspended);
      expect(entity.deletedAt, DateTime.utc(2026, 1, 3));
    });

    test('toEntity throws ValidationException for an unknown status', () {
      final invalidDto = OrganizationDto(
        id: dto.id,
        name: dto.name,
        slug: dto.slug,
        settings: dto.settings,
        status: 'archived',
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

    test('settingsToEntity/settingsToDto round-trip the segment', () {
      const dtoWithSegment = OrganizationSettingsDto(
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
        segment: 'apparel',
      );

      final entity = mapper.settingsToEntity(dtoWithSegment);
      expect(entity.segment, 'apparel');

      final roundTrippedDto = mapper.settingsToDto(entity);
      expect(roundTrippedDto.segment, 'apparel');
    });

    test('toDto is the exact inverse of toEntity', () {
      final entity = mapper.toEntity(dto);
      final roundTrippedDto = mapper.toDto(entity);

      expect(roundTrippedDto.id, dto.id);
      expect(roundTrippedDto.name, dto.name);
      expect(roundTrippedDto.slug, dto.slug);
      expect(roundTrippedDto.status, dto.status);
      expect(roundTrippedDto.createdAt, dto.createdAt);
      expect(roundTrippedDto.createdBy, dto.createdBy);
      expect(roundTrippedDto.updatedAt, dto.updatedAt);
      expect(roundTrippedDto.updatedBy, dto.updatedBy);
      expect(roundTrippedDto.deletedAt, dto.deletedAt);
      expect(roundTrippedDto.settings.currency, dto.settings.currency);
      expect(roundTrippedDto.settings.country, dto.settings.country);
      expect(
        roundTrippedDto.settings.defaultLanguage,
        dto.settings.defaultLanguage,
      );
    });
  });
}
