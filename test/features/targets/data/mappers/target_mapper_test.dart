import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/targets/targets.dart';

void main() {
  group('TargetMapper', () {
    const mapper = TargetMapper();
    final startDate = DateTime.utc(2026, 1, 1);
    final endDate = DateTime.utc(2026, 2, 1);
    final createdAt = DateTime.utc(2025, 12, 20);
    final updatedAt = DateTime.utc(2025, 12, 21);

    TargetDto buildDto({
      String dimensionType = 'salesRep',
      String periodGranularity = 'monthly',
      String metricType = 'revenue',
      String status = 'active',
      String syncStatus = 'synced',
      DateTime? deletedAt,
    }) {
      return TargetDto(
        id: 'target-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        dimensionType: dimensionType,
        dimensionId: 'user-1',
        periodGranularity: periodGranularity,
        startDate: startDate,
        endDate: endDate,
        metricType: metricType,
        targetValue: 100000,
        currency: 'BRL',
        status: status,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-2',
        deletedAt: deletedAt,
        version: 2,
        syncStatus: syncStatus,
      );
    }

    test('toEntity maps every field', () {
      final entity = mapper.toEntity(buildDto());

      expect(entity.id, 'target-1');
      expect(entity.organizationId, 'org-1');
      expect(entity.companyId, 'company-1');
      expect(entity.dimensionType, TargetDimensionType.salesRep);
      expect(entity.dimensionId, 'user-1');
      expect(entity.periodGranularity, TargetPeriodGranularity.monthly);
      expect(entity.startDate, startDate);
      expect(entity.endDate, endDate);
      expect(entity.metricType, TargetMetricType.revenue);
      expect(entity.targetValue, 100000);
      expect(entity.currency, 'BRL');
      expect(entity.status, TargetStatus.active);
      expect(entity.deletedAt, isNull);
      expect(entity.version, 2);
      expect(entity.syncStatus, TargetSyncStatus.synced);
    });

    test(
      'toEntity maps the positivacao metric and a closed/deleted target',
      () {
        final deletedAt = DateTime.utc(2026, 3, 1);
        final entity = mapper.toEntity(
          buildDto(
            metricType: 'positivacao',
            status: 'closed',
            deletedAt: deletedAt,
          ),
        );

        expect(entity.metricType, TargetMetricType.positivacao);
        expect(entity.status, TargetStatus.closed);
        expect(entity.deletedAt, deletedAt);
      },
    );

    test('toDto is the inverse of toEntity', () {
      final dto = buildDto();
      final roundTripped = mapper.toDto(mapper.toEntity(dto));

      expect(roundTripped.id, dto.id);
      expect(roundTripped.organizationId, dto.organizationId);
      expect(roundTripped.companyId, dto.companyId);
      expect(roundTripped.dimensionType, dto.dimensionType);
      expect(roundTripped.dimensionId, dto.dimensionId);
      expect(roundTripped.periodGranularity, dto.periodGranularity);
      expect(roundTripped.startDate, dto.startDate);
      expect(roundTripped.endDate, dto.endDate);
      expect(roundTripped.metricType, dto.metricType);
      expect(roundTripped.targetValue, dto.targetValue);
      expect(roundTripped.currency, dto.currency);
      expect(roundTripped.status, dto.status);
      expect(roundTripped.version, dto.version);
      expect(roundTripped.syncStatus, dto.syncStatus);
    });

    test('toEntity throws for unknown enum codes', () {
      expect(
        () => mapper.toEntity(buildDto(dimensionType: 'region')),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => mapper.toEntity(buildDto(periodGranularity: 'weekly')),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => mapper.toEntity(buildDto(metricType: 'margin')),
        throwsA(isA<ValidationException>()),
      );
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
