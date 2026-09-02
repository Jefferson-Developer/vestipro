import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/insights/insights.dart';

void main() {
  group('ChurnRiskInsightRule', () {
    const rule = ChurnRiskInsightRule();
    const settings = InsightOrganizationSettings(
      churnRiskFrequencyWeight: 0.35,
      churnRiskValueWeight: 0.35,
      churnRiskHealthScoreWeight: 0.30,
      churnRiskMinimumHistoricalOrders: 3,
      churnRiskMediumThreshold: 0.35,
      churnRiskHighThreshold: 0.55,
      churnRiskCriticalThreshold: 0.75,
    );
    final asOf = DateTime.utc(2026, 9, 1, 12);

    InsightContext contextWith(List<InsightChurnRiskSnapshot> snapshots) {
      return InsightContext(
        organizationId: 'org-1',
        companyId: 'company-1',
        asOf: asOf,
        dataset: InsightDataset(
          settings: settings,
          churnRiskSnapshots: snapshots,
        ),
      );
    }

    InsightChurnRiskSnapshot snapshotWithScore({
      required String customerId,
      required double score,
      int historicalOrderCount = 10,
      double historicalRevenue = 10000,
      double? averageTicket,
    }) {
      // All three signals set to the same value so the weighted average
      // (weights summing to 1) equals `score` exactly.
      final historicalFrequency = 10.0;
      final recentFrequency = historicalFrequency * (1 - score);
      final recentRevenue = historicalRevenue * (1 - score);
      final health = (100 * (1 - score)).round();
      return InsightChurnRiskSnapshot(
        customerId: customerId,
        organizationId: 'org-1',
        companyId: 'company-1',
        recipientUserId: 'seller-1',
        customerName: 'Cliente $customerId',
        historicalOrderCount: historicalOrderCount,
        recentPurchaseFrequency: recentFrequency,
        historicalPurchaseFrequency: historicalFrequency,
        recentRevenue: recentRevenue,
        historicalRevenue: historicalRevenue,
        healthScore: health,
        averageTicket: averageTicket,
      );
    }

    test('composes all-high signals into a critical churn-risk insight', () {
      final context = contextWith(<InsightChurnRiskSnapshot>[
        snapshotWithScore(customerId: 'all-high', score: 1.0),
      ]);

      final insights = rule.evaluate(context);

      expect(insights, hasLength(1));
      final insight = insights.single;
      expect(insight.severity, InsightSeverity.critical);
      expect(insight.estimatedImpact.percentage, closeTo(1.0, 1e-9));
      expect(insight.estimatedImpact.amount, closeTo(10000, 1e-6));
      expect(
        insight.evidence.map((e) => e.code),
        containsAll(<String>[
          'frequency_decline_ratio',
          'value_decline_ratio',
          'health_score',
          'churn_risk_score',
          'churn_risk_band',
        ]),
      );
    });

    test('composes mixed signals into a medium churn-risk insight', () {
      final context = contextWith(<InsightChurnRiskSnapshot>[
        snapshotWithScore(customerId: 'mixed', score: 0.5),
      ]);

      final insights = rule.evaluate(context);

      expect(insights, hasLength(1));
      expect(insights.single.severity, InsightSeverity.medium);
      expect(insights.single.estimatedImpact.percentage, closeTo(0.5, 1e-9));
    });

    test(
      'does not raise an insight when all signals are low (baixo risco)',
      () {
        final context = contextWith(<InsightChurnRiskSnapshot>[
          snapshotWithScore(customerId: 'all-low', score: 0.1),
        ]);

        final insights = rule.evaluate(context);

        expect(insights, isEmpty);
      },
    );

    test('classifies risk bands at their exact thresholds', () {
      // Values are offset by a small epsilon from the configured thresholds
      // (0.35 / 0.55 / 0.75) rather than landing exactly on them, since the
      // composed score is a floating-point weighted average and an exact
      // equality could drift by a rounding error of a few ULPs either way.
      final context = contextWith(<InsightChurnRiskSnapshot>[
        snapshotWithScore(customerId: 'just-below-medium', score: 0.349),
        snapshotWithScore(customerId: 'medium-boundary', score: 0.351),
        snapshotWithScore(customerId: 'just-below-high', score: 0.549),
        snapshotWithScore(customerId: 'high-boundary', score: 0.551),
        snapshotWithScore(customerId: 'just-below-critical', score: 0.749),
        snapshotWithScore(customerId: 'critical-boundary', score: 0.751),
      ]);

      final insights = rule.evaluate(context);
      final byCustomer = <String, Insight>{
        for (final insight in insights) insight.customerId!: insight,
      };

      expect(byCustomer.containsKey('just-below-medium'), isFalse);
      expect(byCustomer['medium-boundary']!.severity, InsightSeverity.medium);
      expect(byCustomer['just-below-high']!.severity, InsightSeverity.medium);
      expect(byCustomer['high-boundary']!.severity, InsightSeverity.high);
      expect(byCustomer['just-below-critical']!.severity, InsightSeverity.high);
      expect(
        byCustomer['critical-boundary']!.severity,
        InsightSeverity.critical,
      );
    });

    test('prioritizes by financial impact: high-value/medium-risk customer '
        'ranks above low-value/high-risk customer', () {
      final context = contextWith(<InsightChurnRiskSnapshot>[
        snapshotWithScore(
          customerId: 'high-value-medium-risk',
          score: 0.5,
          historicalRevenue: 200000,
        ),
        snapshotWithScore(
          customerId: 'low-value-high-risk',
          score: 0.9,
          historicalRevenue: 5000,
        ),
      ]);

      final insights = rule.evaluate(context)
        ..sort((left, right) {
          double impact(Insight insight) =>
              (insight.estimatedImpact.amount ?? 0) +
              (insight.estimatedImpact.percentage ?? 0) * 1000;
          return impact(right).compareTo(impact(left));
        });

      expect(insights.map((item) => item.customerId), <String?>[
        'high-value-medium-risk',
        'low-value-high-risk',
      ]);
      expect(
        insights.first.estimatedImpact.amount,
        greaterThan(insights.last.estimatedImpact.amount!),
      );
    });

    test('skips customers with insufficient historical orders instead of '
        'producing a false-positive score', () {
      final context = contextWith(<InsightChurnRiskSnapshot>[
        snapshotWithScore(
          customerId: 'too-new',
          score: 1.0,
          historicalOrderCount: 2,
        ),
      ]);

      final insights = rule.evaluate(context);

      expect(insights, isEmpty);
    });

    test('falls back to average ticket when historical revenue is zero', () {
      final snapshot = InsightChurnRiskSnapshot(
        customerId: 'no-revenue-history',
        organizationId: 'org-1',
        companyId: 'company-1',
        recipientUserId: 'seller-1',
        customerName: 'Sem historico de receita',
        historicalOrderCount: 5,
        recentPurchaseFrequency: 0,
        historicalPurchaseFrequency: 4,
        recentRevenue: 0,
        historicalRevenue: 0,
        healthScore: 20,
        averageTicket: 1500,
      );

      final insights = rule.evaluate(
        contextWith(<InsightChurnRiskSnapshot>[snapshot]),
      );

      expect(insights, hasLength(1));
      expect(insights.single.estimatedImpact.amount, isNotNull);
      expect(insights.single.estimatedImpact.amount, greaterThan(0));
    });
  });
}
