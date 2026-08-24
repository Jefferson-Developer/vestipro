import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/customers/data/dtos/customer_dto.dart';
import 'package:vestipro/features/customers/data/mappers/customer_mapper.dart';

void main() {
  group('CustomerMapper', () {
    const mapper = CustomerMapper();
    final registeredAt = DateTime.utc(2026, 1, 1);
    final createdAt = DateTime.utc(2026, 1, 2);
    final updatedAt = DateTime.utc(2026, 1, 3);

    CustomerDto buildLegalEntityDto({
      String type = 'legalEntity',
      String status = 'active',
      String syncStatus = 'synced',
    }) {
      return CustomerDto(
        id: 'customer-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        type: type,
        document: '04252011000110',
        legalName: 'Moda Sul Confeccoes Ltda',
        tradeName: 'Moda Sul',
        stateRegistration: '123456789',
        primaryEmail: 'compras@modasul.test',
        primaryPhone: '+55 47 99999-0000',
        status: status,
        classification: 'tier-a',
        potential: 'high',
        segment: 'multimarcas',
        originChannel: 'field_sales',
        responsibleSellerId: 'user-1',
        registeredAt: registeredAt,
        lastPurchaseAt: DateTime.utc(2026, 2),
        tags: const <String>['vip'],
        customFields: const <String, Object?>{'regionalCode': 'SC-01'},
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-2',
        version: 3,
        syncStatus: syncStatus,
      );
    }

    CustomerDto buildIndividualDto() {
      return CustomerDto(
        id: 'customer-2',
        organizationId: 'org-1',
        companyId: 'company-1',
        type: 'individual',
        document: '52998224725',
        fullName: 'Ana Souza',
        status: 'prospect',
        registeredAt: registeredAt,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-1',
        version: 1,
        syncStatus: 'pending',
      );
    }

    test('toEntity maps a legal entity customer with optional fields', () {
      final entity = mapper.toEntity(buildLegalEntityDto());

      expect(entity.id, 'customer-1');
      expect(entity.organizationId, 'org-1');
      expect(entity.companyId, 'company-1');
      expect(entity.type, CustomerType.legalEntity);
      expect(entity.document, CnpjCpf.parse('04.252.011/0001-10'));
      expect(entity.legalName, 'Moda Sul Confeccoes Ltda');
      expect(entity.tradeName, 'Moda Sul');
      expect(entity.stateRegistration, '123456789');
      expect(entity.status, CustomerStatus.active);
      expect(entity.classification, 'tier-a');
      expect(entity.potential, 'high');
      expect(entity.segment, 'multimarcas');
      expect(entity.originChannel, 'field_sales');
      expect(entity.responsibleSellerId, 'user-1');
      expect(entity.lastPurchaseAt, DateTime.utc(2026, 2));
      expect(entity.tags, const <String>['vip']);
      expect(entity.customFields, const <String, Object?>{
        'regionalCode': 'SC-01',
      });
      expect(entity.syncStatus, CustomerSyncStatus.synced);
    });

    test('toEntity maps an individual customer with nullable optionals', () {
      final entity = mapper.toEntity(buildIndividualDto());

      expect(entity.type, CustomerType.individual);
      expect(entity.fullName, 'Ana Souza');
      expect(entity.legalName, isNull);
      expect(entity.tradeName, isNull);
      expect(entity.stateRegistration, isNull);
      expect(entity.primaryEmail, isNull);
      expect(entity.lastPurchaseAt, isNull);
      expect(entity.tags, isEmpty);
      expect(entity.customFields, isEmpty);
      expect(entity.status, CustomerStatus.prospect);
      expect(entity.syncStatus, CustomerSyncStatus.pending);
    });

    test('toDto is the inverse of toEntity for a legal entity', () {
      final dto = buildLegalEntityDto();
      final roundTrippedDto = mapper.toDto(mapper.toEntity(dto));

      expect(roundTrippedDto.id, dto.id);
      expect(roundTrippedDto.organizationId, dto.organizationId);
      expect(roundTrippedDto.companyId, dto.companyId);
      expect(roundTrippedDto.type, dto.type);
      expect(roundTrippedDto.document, dto.document);
      expect(roundTrippedDto.legalName, dto.legalName);
      expect(roundTrippedDto.tradeName, dto.tradeName);
      expect(roundTrippedDto.fullName, dto.fullName);
      expect(roundTrippedDto.stateRegistration, dto.stateRegistration);
      expect(roundTrippedDto.status, dto.status);
      expect(roundTrippedDto.registeredAt, dto.registeredAt);
      expect(roundTrippedDto.createdAt, dto.createdAt);
      expect(roundTrippedDto.updatedAt, dto.updatedAt);
      expect(roundTrippedDto.version, dto.version);
      expect(roundTrippedDto.syncStatus, dto.syncStatus);
    });

    test('toEntity throws for an inconsistent type/document pair', () {
      final invalidDto = CustomerDto(
        id: 'customer-3',
        organizationId: 'org-1',
        companyId: 'company-1',
        type: 'legalEntity',
        document: '52998224725',
        legalName: 'Ana Souza ME',
        status: 'active',
        registeredAt: registeredAt,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-1',
        version: 1,
        syncStatus: 'synced',
      );

      expect(
        () => mapper.toEntity(invalidDto),
        throwsA(isA<ValidationException>()),
      );
    });

    test('toEntity throws for unknown status or sync status', () {
      expect(
        () => mapper.toEntity(buildLegalEntityDto(status: 'archived')),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => mapper.toEntity(buildLegalEntityDto(syncStatus: 'remote_only')),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
