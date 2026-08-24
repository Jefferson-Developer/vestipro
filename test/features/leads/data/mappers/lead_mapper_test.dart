import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/leads/data/dtos/lead_dto.dart';
import 'package:vestipro/features/leads/data/mappers/lead_mapper.dart';
import 'package:vestipro/features/leads/leads.dart';

void main() {
  group('LeadMapper', () {
    const mapper = LeadMapper();
    final createdAt = DateTime.utc(2026, 1, 1);
    final updatedAt = DateTime.utc(2026, 1, 3);

    LeadDto buildDto({
      String status = 'qualified',
      String syncStatus = 'synced',
    }) {
      return LeadDto(
        id: 'lead-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        name: 'Loja Vitrine Moda',
        document: '04252011000110',
        sourceCode: 'website',
        sourceLabel: 'Site',
        responsibleUserId: 'user-1',
        status: status,
        score: 42,
        disqualificationReason: null,
        convertedCustomerId: null,
        convertedOpportunityId: null,
        createdAt: createdAt,
        contactedAt: DateTime.utc(2026, 1, 2),
        qualifiedAt: DateTime.utc(2026, 1, 2, 12),
        convertedAt: null,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-2',
        version: 3,
        syncStatus: syncStatus,
      );
    }

    test('toEntity maps every field including the source', () {
      final entity = mapper.toEntity(buildDto());

      expect(entity.id, 'lead-1');
      expect(entity.organizationId, 'org-1');
      expect(entity.companyId, 'company-1');
      expect(entity.name, 'Loja Vitrine Moda');
      expect(entity.document, '04252011000110');
      expect(entity.source, LeadSource.website);
      expect(entity.responsibleUserId, 'user-1');
      expect(entity.status, LeadStatus.qualified);
      expect(entity.score, 42);
      expect(entity.contactedAt, DateTime.utc(2026, 1, 2));
      expect(entity.qualifiedAt, DateTime.utc(2026, 1, 2, 12));
      expect(entity.convertedAt, isNull);
      expect(entity.version, 3);
      expect(entity.syncStatus, LeadSyncStatus.synced);
    });

    test('toEntity maps a custom source code with its label', () {
      final dto = LeadDto(
        id: 'lead-2',
        organizationId: 'org-1',
        name: 'Loja Custom',
        sourceCode: 'trade_show',
        sourceLabel: 'Feira setorial',
        responsibleUserId: 'user-1',
        status: 'new',
        score: 0,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: createdAt,
        updatedBy: 'user-1',
        version: 1,
        syncStatus: 'pending',
      );

      final entity = mapper.toEntity(dto);

      expect(entity.source.code, 'trade_show');
      expect(entity.source.label, 'Feira setorial');
      expect(entity.source.isCustom, isTrue);
    });

    test('toDto is the inverse of toEntity', () {
      final dto = buildDto();
      final roundTripped = mapper.toDto(mapper.toEntity(dto));

      expect(roundTripped.id, dto.id);
      expect(roundTripped.organizationId, dto.organizationId);
      expect(roundTripped.name, dto.name);
      expect(roundTripped.sourceCode, dto.sourceCode);
      expect(roundTripped.sourceLabel, dto.sourceLabel);
      expect(roundTripped.status, dto.status);
      expect(roundTripped.score, dto.score);
      expect(roundTripped.version, dto.version);
      expect(roundTripped.syncStatus, dto.syncStatus);
    });

    test('toEntity throws for an unknown status or sync status', () {
      expect(
        () => mapper.toEntity(buildDto(status: 'archived')),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => mapper.toEntity(buildDto(syncStatus: 'remote_only')),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
