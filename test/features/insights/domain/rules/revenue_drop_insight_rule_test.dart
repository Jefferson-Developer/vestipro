import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/insights/insights.dart';

void main() {
  group('RevenueDropInsightRule', () {
    const rule = RevenueDropInsightRule();
    final context = InsightContext(
      organizationId: 'org-1',
      companyId: 'company-1',
      asOf: DateTime.utc(2026, 9, 1, 12),
      dataset: InsightDataset(
        settings: const InsightOrganizationSettings(
          revenueDropThreshold: 0.30,
          revenueDropMinimumBaselineAmount: 1000,
          revenueComparisonMode: InsightRevenueComparisonMode.yearOverYear,
        ),
        revenueComparisons: <InsightRevenueComparisonSnapshot>[
          const InsightRevenueComparisonSnapshot(
            customerId: 'trigger',
            organizationId: 'org-1',
            companyId: 'company-1',
            recipientUserId: 'seller-1',
            customerName: 'Trigger',
            mode: InsightRevenueComparisonMode.yearOverYear,
            currentPeriodRevenue: 7000,
            previousEquivalentRevenue: 10000,
            currentPeriodKey: '2026-08',
            previousPeriodKey: '2025-08',
            currentSeasonCode: 'summer',
            previousSeasonCode: 'summer',
          ),
          const InsightRevenueComparisonSnapshot(
            customerId: 'below-threshold',
            organizationId: 'org-1',
            companyId: 'company-1',
            recipientUserId: 'seller-1',
            customerName: 'Below',
            mode: InsightRevenueComparisonMode.yearOverYear,
            currentPeriodRevenue: 8200,
            previousEquivalentRevenue: 10000,
            currentPeriodKey: '2026-08',
            previousPeriodKey: '2025-08',
            currentSeasonCode: 'summer',
            previousSeasonCode: 'summer',
          ),
          const InsightRevenueComparisonSnapshot(
            customerId: 'below-baseline',
            organizationId: 'org-1',
            companyId: 'company-1',
            recipientUserId: 'seller-1',
            customerName: 'Small',
            mode: InsightRevenueComparisonMode.yearOverYear,
            currentPeriodRevenue: 200,
            previousEquivalentRevenue: 500,
            currentPeriodKey: '2026-08',
            previousPeriodKey: '2025-08',
            currentSeasonCode: 'summer',
            previousSeasonCode: 'summer',
          ),
          const InsightRevenueComparisonSnapshot(
            customerId: 'different-season',
            organizationId: 'org-1',
            companyId: 'company-1',
            recipientUserId: 'seller-1',
            customerName: 'Season',
            mode: InsightRevenueComparisonMode.yearOverYear,
            currentPeriodRevenue: 5000,
            previousEquivalentRevenue: 10000,
            currentPeriodKey: '2026-08',
            previousPeriodKey: '2025-08',
            currentSeasonCode: 'winter',
            previousSeasonCode: 'summer',
          ),
        ],
      ),
    );

    test('fires above threshold and skips invalid comparisons', () {
      final insights = rule.evaluate(context);

      expect(insights.map((item) => item.customerId), <String?>['trigger']);
      expect(insights.single.estimatedImpact.amount, 3000);
      expect(insights.single.estimatedImpact.percentage, 0.3);
    });
  });
}
