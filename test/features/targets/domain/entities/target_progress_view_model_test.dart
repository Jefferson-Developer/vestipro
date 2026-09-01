import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/targets/targets.dart';

void main() {
  group('TargetProgressViewModel.compute', () {
    final createdAt = DateTime.utc(2026, 1, 1);

    Target buildTarget({
      double targetValue = 100000,
      DateTime? startDate,
      DateTime? endDate,
    }) {
      return Target(
        id: 'target-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        dimensionType: TargetDimensionType.salesRep,
        dimensionId: 'user-1',
        periodGranularity: TargetPeriodGranularity.monthly,
        startDate: startDate ?? DateTime.utc(2026, 1, 1),
        endDate: endDate ?? DateTime.utc(2026, 2, 1),
        metricType: TargetMetricType.revenue,
        targetValue: targetValue,
        currency: 'BRL',
        status: TargetStatus.active,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: createdAt,
        updatedBy: 'user-1',
        version: 1,
        syncStatus: TargetSyncStatus.pending,
      );
    }

    test('in-progress period: gap, achievement %, elapsed % and a linear '
        'projection are all consistent with the pace so far', () {
      final target = buildTarget(); // Jan 1 - Feb 1 (31 days)
      final now = DateTime.utc(2026, 1, 16); // 15 days elapsed (~48.4%)

      final progress = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 40000,
        calculatedAt: now,
        now: now,
      );

      expect(progress.gapAbsolute, 60000);
      expect(progress.gapPercentage, closeTo(60, 0.01));
      expect(progress.achievementPercentage, closeTo(40, 0.01));
      expect(progress.elapsedTimePercentage, closeTo(48.39, 0.1));
      expect(progress.isOnPace, isFalse);
      // Projected: 40000 / (15/31) ~= 82_666.67
      expect(progress.projectedValue, closeTo(82666.67, 1));
      expect(progress.isPeriodNotStarted, isFalse);
      expect(progress.isPeriodEnded, isFalse);
    });

    test('meta zerada: achievement/gap percentages never divide by zero', () {
      final target = buildTarget(targetValue: 0);
      final now = DateTime.utc(2026, 1, 16);

      final zeroRealized = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 0,
        calculatedAt: now,
        now: now,
      );
      expect(zeroRealized.gapPercentage, 0);
      expect(zeroRealized.achievementPercentage, 0);
      expect(zeroRealized.gapAbsolute, 0);

      final anyRealized = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 500,
        calculatedAt: now,
        now: now,
      );
      expect(anyRealized.achievementPercentage, 100);
      expect(anyRealized.gapAbsolute, -500);
    });

    test('realizado maior que a meta: gap goes negative and achievement '
        'exceeds 100%, never clamped', () {
      final target = buildTarget(targetValue: 100000);
      final now = DateTime.utc(2026, 1, 31);

      final progress = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 150000,
        calculatedAt: now,
        now: now,
      );

      expect(progress.gapAbsolute, -50000);
      expect(progress.gapPercentage, -50);
      expect(progress.achievementPercentage, 150);
      expect(progress.isOnPace, isTrue);
    });

    test('período ainda não iniciado: elapsed % is 0 and the projection '
        'never extrapolates from zero pace', () {
      final target = buildTarget(
        startDate: DateTime.utc(2026, 3, 1),
        endDate: DateTime.utc(2026, 4, 1),
      );
      final now = DateTime.utc(2026, 1, 1);

      final progress = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 0,
        calculatedAt: now,
        now: now,
      );

      expect(progress.isPeriodNotStarted, isTrue);
      expect(progress.isPeriodEnded, isFalse);
      expect(progress.elapsedTimePercentage, 0);
      expect(progress.projectedValue, 0);
    });

    test('período já encerrado: elapsed % clamps at 100 and the projection '
        'is simply the final realized value, never re-extrapolated', () {
      final target = buildTarget(); // Jan 1 - Feb 1
      final now = DateTime.utc(2026, 3, 15); // long after endDate

      final progress = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 90000,
        calculatedAt: DateTime.utc(2026, 2, 1),
        now: now,
      );

      expect(progress.isPeriodEnded, isTrue);
      expect(progress.elapsedTimePercentage, 100);
      expect(progress.projectedValue, 90000);
      expect(progress.projectedAchievementPercentage, closeTo(90, 0.01));
    });
  });
}
