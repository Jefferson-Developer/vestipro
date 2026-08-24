import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/opportunities/data/dtos/opportunity_dto.dart';
import 'package:vestipro/features/opportunities/data/mappers/opportunity_mapper.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';

void main() {
  group('OpportunityMapper', () {
    const mapper = OpportunityMapper();
    final createdAt = DateTime.utc(2026, 1, 1);
    final updatedAt = DateTime.utc(2026, 1, 3);
    final expectedCloseDate = DateTime.utc(2026, 2, 1);

    OpportunityDto buildDto({
      String status = 'open',
      String syncStatus = 'synced',
      String? wonReason,
      String? lostReason,
      DateTime? closedAt,
    }) {
      return OpportunityDto(
        id: 'opportunity-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        title: 'Reposição de inverno',
        description: 'Grade fechada de casacos',
        customerId: 'customer-1',
        estimatedValue: 2000,
        probability: 40,
        revenueForecast: 800,
        responsibleUserId: 'user-1',
        stageId: 'stage-qualification',
        status: status,
        expectedCloseDate: expectedCloseDate,
        wonReason: wonReason,
        lostReason: lostReason,
        closedAt: closedAt,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-2',
        version: 3,
        syncStatus: syncStatus,
      );
    }

    test('toEntity maps every field', () {
      final entity = mapper.toEntity(buildDto());

      expect(entity.id, 'opportunity-1');
      expect(entity.organizationId, 'org-1');
      expect(entity.companyId, 'company-1');
      expect(entity.title, 'Reposição de inverno');
      expect(entity.description, 'Grade fechada de casacos');
      expect(entity.customerId, 'customer-1');
      expect(entity.leadId, isNull);
      expect(entity.estimatedValue, 2000);
      expect(entity.probability, 40);
      expect(entity.revenueForecast, 800);
      expect(entity.responsibleUserId, 'user-1');
      expect(entity.stageId, 'stage-qualification');
      expect(entity.status, OpportunityStatus.open);
      expect(entity.expectedCloseDate, expectedCloseDate);
      expect(entity.version, 3);
      expect(entity.syncStatus, OpportunitySyncStatus.synced);
    });

    test('toEntity maps a won opportunity with its reason and closedAt', () {
      final closedAt = DateTime.utc(2026, 1, 10);
      final entity = mapper.toEntity(
        buildDto(
          status: 'won',
          wonReason: 'Preço competitivo',
          closedAt: closedAt,
        ),
      );

      expect(entity.status, OpportunityStatus.won);
      expect(entity.wonReason, 'Preço competitivo');
      expect(entity.closedAt, closedAt);
    });

    test('toDto is the inverse of toEntity', () {
      final dto = buildDto();
      final roundTripped = mapper.toDto(mapper.toEntity(dto));

      expect(roundTripped.id, dto.id);
      expect(roundTripped.organizationId, dto.organizationId);
      expect(roundTripped.title, dto.title);
      expect(roundTripped.customerId, dto.customerId);
      expect(roundTripped.estimatedValue, dto.estimatedValue);
      expect(roundTripped.probability, dto.probability);
      expect(roundTripped.revenueForecast, dto.revenueForecast);
      expect(roundTripped.status, dto.status);
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
