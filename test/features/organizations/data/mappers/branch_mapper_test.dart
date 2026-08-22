import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/organizations/data/dtos/branch_address_dto.dart';
import 'package:vestipro/features/organizations/data/dtos/branch_dto.dart';
import 'package:vestipro/features/organizations/data/mappers/branch_mapper.dart';
import 'package:vestipro/features/organizations/organizations.dart';

void main() {
  group('BranchMapper', () {
    const mapper = BranchMapper();

    const addressDto = BranchAddressDto(
      street: 'Rua XV de Novembro',
      number: '100',
      complement: 'Sala 2',
      neighborhood: 'Centro',
      city: 'Blumenau',
      state: 'SC',
      postalCode: '89010-000',
      country: 'BR',
    );

    final dto = BranchDto(
      id: 'branch-1',
      organizationId: 'org-1',
      companyId: 'company-1',
      name: 'Loja Blumenau',
      type: 'store',
      address: addressDto,
      status: 'active',
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 2),
      updatedBy: 'user-2',
    );

    test('toEntity maps every field, including a filled address', () {
      final entity = mapper.toEntity(dto);

      expect(entity.id, 'branch-1');
      expect(entity.organizationId, 'org-1');
      expect(entity.companyId, 'company-1');
      expect(entity.name, 'Loja Blumenau');
      expect(entity.type, BranchType.store);
      expect(entity.address, isNotNull);
      expect(entity.address!.street, 'Rua XV de Novembro');
      expect(entity.address!.complement, 'Sala 2');
      expect(entity.status, BranchStatus.active);
      expect(entity.version, 1);
      expect(entity.deletedAt, isNull);
    });

    test('toEntity maps a Branch without an address (null)', () {
      final minimalDto = BranchDto(
        id: dto.id,
        organizationId: dto.organizationId,
        companyId: dto.companyId,
        name: dto.name,
        type: 'showroom',
        status: dto.status,
        version: dto.version,
        createdAt: dto.createdAt,
        createdBy: dto.createdBy,
        updatedAt: dto.updatedAt,
        updatedBy: dto.updatedBy,
      );

      final entity = mapper.toEntity(minimalDto);

      expect(entity.address, isNull);
      expect(entity.type, BranchType.showroom);
    });

    test('toEntity maps every BranchType value', () {
      for (final entry in <String, BranchType>{
        'store': BranchType.store,
        'showroom': BranchType.showroom,
        'unit': BranchType.unit,
      }.entries) {
        final typedDto = BranchDto(
          id: dto.id,
          organizationId: dto.organizationId,
          companyId: dto.companyId,
          name: dto.name,
          type: entry.key,
          status: dto.status,
          version: dto.version,
          createdAt: dto.createdAt,
          createdBy: dto.createdBy,
          updatedAt: dto.updatedAt,
          updatedBy: dto.updatedBy,
        );

        expect(mapper.toEntity(typedDto).type, entry.value);
      }
    });

    test('toEntity throws ValidationException for an unknown type', () {
      final invalidDto = BranchDto(
        id: dto.id,
        organizationId: dto.organizationId,
        companyId: dto.companyId,
        name: dto.name,
        type: 'warehouse',
        status: dto.status,
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

    test('toEntity throws ValidationException for an unknown status', () {
      final invalidDto = BranchDto(
        id: dto.id,
        organizationId: dto.organizationId,
        companyId: dto.companyId,
        name: dto.name,
        type: dto.type,
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

    test('toDto is the exact inverse of toEntity, including the address', () {
      final entity = mapper.toEntity(dto);
      final roundTrippedDto = mapper.toDto(entity);

      expect(roundTrippedDto.id, dto.id);
      expect(roundTrippedDto.organizationId, dto.organizationId);
      expect(roundTrippedDto.companyId, dto.companyId);
      expect(roundTrippedDto.name, dto.name);
      expect(roundTrippedDto.type, dto.type);
      expect(roundTrippedDto.status, dto.status);
      expect(roundTrippedDto.version, dto.version);
      expect(roundTrippedDto.address, isNotNull);
      expect(roundTrippedDto.address!.street, dto.address!.street);
      expect(roundTrippedDto.address!.complement, dto.address!.complement);
    });
  });
}
