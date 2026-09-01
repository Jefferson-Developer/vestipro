import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/targets/targets.dart';

void main() {
  group('Target', () {
    final createdAt = DateTime.utc(2026, 1, 1);
    final updatedAt = DateTime.utc(2026, 1, 2);

    Target buildTarget({
      String id = 'target-1',
      DateTime? startDate,
      DateTime? endDate,
      double targetValue = 100000,
      TargetStatus status = TargetStatus.active,
      TargetDimensionType dimensionType = TargetDimensionType.salesRep,
      String dimensionId = 'user-1',
      TargetMetricType metricType = TargetMetricType.revenue,
    }) {
      return Target(
        id: id,
        organizationId: 'org-1',
        companyId: 'company-1',
        dimensionType: dimensionType,
        dimensionId: dimensionId,
        periodGranularity: TargetPeriodGranularity.monthly,
        startDate: startDate ?? DateTime.utc(2026, 1, 1),
        endDate: endDate ?? DateTime.utc(2026, 2, 1),
        metricType: metricType,
        targetValue: targetValue,
        currency: 'BRL',
        status: status,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-1',
        version: 1,
        syncStatus: TargetSyncStatus.pending,
      );
    }

    test('holds every field it was built with', () {
      final target = buildTarget();

      expect(target.id, 'target-1');
      expect(target.organizationId, 'org-1');
      expect(target.companyId, 'company-1');
      expect(target.dimensionType, TargetDimensionType.salesRep);
      expect(target.dimensionId, 'user-1');
      expect(target.periodGranularity, TargetPeriodGranularity.monthly);
      expect(target.metricType, TargetMetricType.revenue);
      expect(target.targetValue, 100000);
      expect(target.currency, 'BRL');
      expect(target.status, TargetStatus.active);
      expect(target.deletedAt, isNull);
      expect(target.syncStatus, TargetSyncStatus.pending);
    });

    test('accepts a zero targetValue (the domain boundary)', () {
      final target = buildTarget(targetValue: 0);
      expect(target.targetValue, 0);
    });

    group('overlapsWith', () {
      test('returns true for two periods that overlap in the middle', () {
        final january = buildTarget(
          startDate: DateTime.utc(2026, 1, 1),
          endDate: DateTime.utc(2026, 2, 1),
        );
        final midJanuaryToFebruary = buildTarget(
          id: 'target-2',
          startDate: DateTime.utc(2026, 1, 15),
          endDate: DateTime.utc(2026, 2, 15),
        );

        expect(january.overlapsWith(midJanuaryToFebruary), isTrue);
        expect(midJanuaryToFebruary.overlapsWith(january), isTrue);
      });

      test('returns true when one period fully contains the other', () {
        final quarter = buildTarget(
          startDate: DateTime.utc(2026, 1, 1),
          endDate: DateTime.utc(2026, 4, 1),
        );
        final february = buildTarget(
          id: 'target-2',
          startDate: DateTime.utc(2026, 2, 1),
          endDate: DateTime.utc(2026, 3, 1),
        );

        expect(quarter.overlapsWith(february), isTrue);
      });

      test(
        'returns false for back-to-back periods touching at the boundary',
        () {
          final january = buildTarget(
            startDate: DateTime.utc(2026, 1, 1),
            endDate: DateTime.utc(2026, 2, 1),
          );
          final february = buildTarget(
            id: 'target-2',
            startDate: DateTime.utc(2026, 2, 1),
            endDate: DateTime.utc(2026, 3, 1),
          );

          expect(january.overlapsWith(february), isFalse);
          expect(february.overlapsWith(january), isFalse);
        },
      );

      test('returns false for two fully separate periods', () {
        final january = buildTarget(
          startDate: DateTime.utc(2026, 1, 1),
          endDate: DateTime.utc(2026, 2, 1),
        );
        final march = buildTarget(
          id: 'target-2',
          startDate: DateTime.utc(2026, 3, 1),
          endDate: DateTime.utc(2026, 4, 1),
        );

        expect(january.overlapsWith(march), isFalse);
      });
    });
  });
}
