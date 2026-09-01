import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/targets/targets.dart';

void main() {
  group('TargetAlertEvaluator.evaluate', () {
    const evaluator = TargetAlertEvaluator();
    final createdAt = DateTime.utc(2026, 1, 1);

    Target buildTarget({
      DateTime? startDate,
      DateTime? endDate,
      double targetValue = 100,
    }) {
      return Target(
        id: 'target-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        dimensionType: TargetDimensionType.salesRep,
        dimensionId: 'rep-1',
        periodGranularity: TargetPeriodGranularity.monthly,
        startDate: startDate ?? DateTime.utc(2026, 1, 1),
        endDate: endDate ?? DateTime.utc(2026, 2, 1),
        metricType: TargetMetricType.revenue,
        targetValue: targetValue,
        currency: 'BRL',
        status: TargetStatus.active,
        createdAt: createdAt,
        createdBy: 'manager-1',
        updatedAt: createdAt,
        updatedBy: 'manager-1',
        version: 1,
        syncStatus: TargetSyncStatus.pending,
      );
    }

    test('classifies high risk when pace ratio stays below the organization '
        'high-risk threshold', () {
      final now = DateTime.utc(2026, 1, 16);
      final target = buildTarget();
      final progress = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 20,
        now: now,
      );

      final result = evaluator.evaluate(
        target: target,
        progress: progress,
        settings: const TargetAlertSettings(
          highRiskPaceRatioThreshold: 0.6,
          moderateRiskPaceRatioThreshold: 0.9,
        ),
        now: now,
      );

      expect(result.classification, TargetAlertClassification.highRisk);
    });

    test('classifies moderate risk when pace is below moderate but above high '
        'risk threshold', () {
      final now = DateTime.utc(2026, 1, 16);
      final target = buildTarget();
      final progress = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 40,
        now: now,
      );

      final result = evaluator.evaluate(
        target: target,
        progress: progress,
        settings: const TargetAlertSettings(
          highRiskPaceRatioThreshold: 0.7,
          moderateRiskPaceRatioThreshold: 0.9,
        ),
        now: now,
      );

      expect(result.classification, TargetAlertClassification.moderateRisk);
    });

    test('classifies on track when pace meets the organization threshold', () {
      final now = DateTime.utc(2026, 1, 16);
      final target = buildTarget();
      final progress = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 55,
        now: now,
      );

      final result = evaluator.evaluate(
        target: target,
        progress: progress,
        settings: const TargetAlertSettings(
          highRiskPaceRatioThreshold: 0.7,
          moderateRiskPaceRatioThreshold: 0.9,
        ),
        now: now,
      );

      expect(result.classification, TargetAlertClassification.onTrack);
    });

    test('classifies opportunity when the organization threshold is met near '
        'the end of the period', () {
      final now = DateTime.utc(2026, 1, 29);
      final target = buildTarget();
      final progress = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 92,
        now: now,
      );

      final result = evaluator.evaluate(
        target: target,
        progress: progress,
        settings: const TargetAlertSettings(
          highRiskPaceRatioThreshold: 0.7,
          moderateRiskPaceRatioThreshold: 0.9,
          opportunityAchievementThreshold: 90,
          opportunityDaysRemainingThreshold: 5,
        ),
        now: now,
      );

      expect(result.classification, TargetAlertClassification.opportunity);
    });
  });
}
