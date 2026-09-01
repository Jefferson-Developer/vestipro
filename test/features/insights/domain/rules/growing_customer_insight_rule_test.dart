import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/insights/insights.dart';

void main() {
  group('GrowingCustomerInsightRule', () {
    const rule = GrowingCustomerInsightRule();
    final asOf = DateTime.utc(2026, 9, 1, 12);

    test('fires with consistent growth across 3 consecutive periods', () {
      final context = InsightContext(
        organizationId: 'org-1',
        companyId: 'company-1',
        asOf: asOf,
        dataset: InsightDataset(
          settings: const InsightOrganizationSettings(),
          customerGrowthSnapshots: <InsightCustomerGrowthSnapshot>[
            InsightCustomerGrowthSnapshot(
              customerId: 'growing',
              organizationId: 'org-1',
              companyId: 'company-1',
              recipientUserId: 'seller-1',
              customerName: 'Growing',
              periods: const <InsightCustomerGrowthPeriod>[
                InsightCustomerGrowthPeriod(
                  periodKey: '2026-05',
                  revenue: 1000,
                ),
                InsightCustomerGrowthPeriod(
                  periodKey: '2026-06',
                  revenue: 1200,
                ),
                InsightCustomerGrowthPeriod(
                  periodKey: '2026-07',
                  revenue: 1450,
                ),
                InsightCustomerGrowthPeriod(
                  periodKey: '2026-08',
                  revenue: 1750,
                ),
              ],
            ),
          ],
        ),
      );

      final insights = rule.evaluate(context);

      expect(insights, hasLength(1));
      expect(insights.single.customerId, 'growing');
      expect(insights.single.estimatedImpact.percentage, greaterThan(0.15));
      expect(
        insights.single.evidence.map((item) => item.code),
        containsAll(<String>[
          'period_revenue:2026-05',
          'period_revenue:2026-06',
          'period_revenue:2026-07',
          'period_revenue:2026-08',
          'average_growth_rate',
        ]),
      );
    });

    test('does not fire when growth is not consistent across periods', () {
      final context = InsightContext(
        organizationId: 'org-1',
        companyId: 'company-1',
        asOf: asOf,
        dataset: InsightDataset(
          settings: const InsightOrganizationSettings(),
          customerGrowthSnapshots: <InsightCustomerGrowthSnapshot>[
            InsightCustomerGrowthSnapshot(
              customerId: 'inconsistent',
              organizationId: 'org-1',
              companyId: 'company-1',
              recipientUserId: 'seller-1',
              customerName: 'Inconsistent',
              periods: const <InsightCustomerGrowthPeriod>[
                InsightCustomerGrowthPeriod(
                  periodKey: '2026-05',
                  revenue: 1000,
                ),
                InsightCustomerGrowthPeriod(
                  periodKey: '2026-06',
                  revenue: 1200,
                ),
                InsightCustomerGrowthPeriod(
                  periodKey: '2026-07',
                  revenue: 1100,
                ),
                InsightCustomerGrowthPeriod(
                  periodKey: '2026-08',
                  revenue: 1400,
                ),
              ],
            ),
          ],
        ),
      );

      expect(rule.evaluate(context), isEmpty);
    });

    test(
      'excludes an isolated outlier order from the trend and avoids a false positive',
      () {
        final context = InsightContext(
          organizationId: 'org-1',
          companyId: 'company-1',
          asOf: asOf,
          dataset: InsightDataset(
            settings: const InsightOrganizationSettings(),
            customerGrowthSnapshots: <InsightCustomerGrowthSnapshot>[
              InsightCustomerGrowthSnapshot(
                customerId: 'outlier',
                organizationId: 'org-1',
                companyId: 'company-1',
                recipientUserId: 'seller-1',
                customerName: 'Outlier',
                periods: const <InsightCustomerGrowthPeriod>[
                  InsightCustomerGrowthPeriod(
                    periodKey: '2026-05',
                    revenue: 1000,
                  ),
                  InsightCustomerGrowthPeriod(
                    periodKey: '2026-06',
                    revenue: 1150,
                  ),
                  InsightCustomerGrowthPeriod(
                    periodKey: '2026-07',
                    revenue: 1300,
                  ),
                  // One atypical order inflates this period's raw revenue,
                  // which would otherwise manufacture a false-positive
                  // growth spike (raw rate would be ~130%).
                  InsightCustomerGrowthPeriod(
                    periodKey: '2026-08',
                    revenue: 3000,
                    hasOutlierOrder: true,
                    outlierAdjustedRevenue: 1450,
                  ),
                ],
              ),
            ],
          ),
        );

        expect(rule.evaluate(context), isEmpty);
      },
    );

    test(
      'honors organization-configured minimum periods and growth threshold',
      () {
        final snapshot = InsightCustomerGrowthSnapshot(
          customerId: 'configured',
          organizationId: 'org-1',
          companyId: 'company-1',
          recipientUserId: 'seller-1',
          customerName: 'Configured',
          periods: const <InsightCustomerGrowthPeriod>[
            InsightCustomerGrowthPeriod(periodKey: '2026-06', revenue: 1000),
            InsightCustomerGrowthPeriod(periodKey: '2026-07', revenue: 1060),
            InsightCustomerGrowthPeriod(periodKey: '2026-08', revenue: 1120),
          ],
        );

        final defaultContext = InsightContext(
          organizationId: 'org-1',
          companyId: 'company-1',
          asOf: asOf,
          dataset: InsightDataset(
            settings: const InsightOrganizationSettings(),
            customerGrowthSnapshots: <InsightCustomerGrowthSnapshot>[
              snapshot,
            ],
          ),
        );
        // Default settings require 3 consecutive growth readings (4
        // periods); only 3 periods (2 readings) are available here.
        expect(rule.evaluate(defaultContext), isEmpty);

        final configuredContext = InsightContext(
          organizationId: 'org-1',
          companyId: 'company-1',
          asOf: asOf,
          dataset: InsightDataset(
            settings: const InsightOrganizationSettings(
              customerGrowthMinConsecutivePeriods: 2,
              customerGrowthMinimumAverageRate: 0.05,
            ),
            customerGrowthSnapshots: <InsightCustomerGrowthSnapshot>[
              snapshot,
            ],
          ),
        );

        final insights = rule.evaluate(configuredContext);
        expect(insights, hasLength(1));
        expect(insights.single.customerId, 'configured');
      },
    );
  });
}
