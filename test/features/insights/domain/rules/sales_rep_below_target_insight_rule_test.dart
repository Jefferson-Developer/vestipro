import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/insights/insights.dart';

void main() {
  group('SalesRepBelowTargetInsightRule', () {
    const rule = SalesRepBelowTargetInsightRule();
    const settings = InsightOrganizationSettings(
      sellerBelowTargetMinimumElapsedDays: 5,
      sellerBelowTargetMediumThreshold: 0.10,
      sellerBelowTargetHighThreshold: 0.30,
      sellerBelowTargetCriticalThreshold: 0.50,
    );
    final asOf = DateTime.utc(2026, 9, 15);
    final periodStart = DateTime.utc(2026, 9, 1);
    final periodEnd = DateTime.utc(2026, 9, 30);

    InsightContext contextWith(
      List<InsightSalesRepBelowTargetSnapshot> snapshots,
    ) {
      return InsightContext(
        organizationId: 'org-1',
        companyId: 'company-1',
        asOf: asOf,
        dataset: InsightDataset(
          settings: settings,
          salesRepBelowTargetSnapshots: snapshots,
        ),
      );
    }

    InsightSalesRepBelowTargetSnapshot snapshotWith({
      String sellerId = 'seller-1',
      String recipientUserId = 'manager-1',
      required double targetValue,
      required double realizedValue,
      int elapsedRelevantDays = 10,
      int totalRelevantDays = 20,
    }) {
      return InsightSalesRepBelowTargetSnapshot(
        sellerId: sellerId,
        organizationId: 'org-1',
        companyId: 'company-1',
        recipientUserId: recipientUserId,
        sellerName: 'Joao Silva',
        periodLabel: 'Setembro/2026',
        periodStartDate: periodStart,
        periodEndDate: periodEnd,
        targetValue: targetValue,
        realizedValue: realizedValue,
        elapsedRelevantDays: elapsedRelevantDays,
        totalRelevantDays: totalRelevantDays,
      );
    }

    test('does not raise an insight when the constant pace already meets the '
        'goal (projection at 100%)', () {
      // 10 dias decorridos, R$ 500/dia => projetado R$ 10.000 em 20 dias.
      final context = contextWith(<InsightSalesRepBelowTargetSnapshot>[
        snapshotWith(targetValue: 10000, realizedValue: 5000),
      ]);

      expect(rule.evaluate(context), isEmpty);
    });

    test('raises a high-risk insight when the pace is well below what is '
        'needed (a "decelerating" seller), projecting a large shortfall', () {
      // Realizado 3000 em 10 dias => ritmo 300/dia => projetado 6000/10000
      // = 60% (under-achievement 40% >= limiar de alto risco de 30%).
      final context = contextWith(<InsightSalesRepBelowTargetSnapshot>[
        snapshotWith(targetValue: 10000, realizedValue: 3000),
      ]);

      final insights = rule.evaluate(context);

      expect(insights, hasLength(1));
      expect(insights.single.severity, InsightSeverity.high);
      expect(insights.single.type, InsightType.sellerBelowTarget);
    });

    test('raises a moderate-risk insight when the pace is "accelerating" but '
        'still not quite enough to clear the gate threshold', () {
      // Realizado 4400 em 10 dias (ritmo mais proximo do necessario que o
      // caso "desacelerando" acima) => projetado 8800/10000 = 88%
      // (under-achievement 12%, entre o gate de 10% e o limiar de alto
      // risco de 30%: risco moderado).
      final context = contextWith(<InsightSalesRepBelowTargetSnapshot>[
        snapshotWith(targetValue: 10000, realizedValue: 4400),
      ]);

      final insights = rule.evaluate(context);

      expect(insights, hasLength(1));
      expect(insights.single.severity, InsightSeverity.medium);
    });

    test(
      'does not raise an insight before the minimum elapsed-days window',
      () {
        final context = contextWith(<InsightSalesRepBelowTargetSnapshot>[
          snapshotWith(
            targetValue: 10000,
            realizedValue: 1000,
            elapsedRelevantDays: 4,
          ),
        ]);

        expect(rule.evaluate(context), isEmpty);
      },
    );

    test('raises an insight exactly at the minimum elapsed-days window', () {
      final context = contextWith(<InsightSalesRepBelowTargetSnapshot>[
        snapshotWith(
          targetValue: 10000,
          realizedValue: 1000,
          elapsedRelevantDays: 5,
        ),
      ]);

      expect(rule.evaluate(context), hasLength(1));
    });

    group('projection threshold boundary (89% vs 90% vs 91% of the goal)', () {
      test('91% of the goal: on track, no insight', () {
        final context = contextWith(<InsightSalesRepBelowTargetSnapshot>[
          // Ritmo 455/dia * 20 dias projetado = 9100 => 91%.
          snapshotWith(targetValue: 10000, realizedValue: 4550),
        ]);

        expect(rule.evaluate(context), isEmpty);
      });

      test('90% of the goal: exactly at the gate, raises "medio" risk', () {
        final context = contextWith(<InsightSalesRepBelowTargetSnapshot>[
          // Ritmo 450/dia * 20 dias projetado = 9000 => exatos 90%.
          snapshotWith(targetValue: 10000, realizedValue: 4500),
        ]);

        final insights = rule.evaluate(context);

        expect(insights, hasLength(1));
        expect(insights.single.severity, InsightSeverity.medium);
      });

      test('89% of the goal: below the gate, raises "medio" risk', () {
        final context = contextWith(<InsightSalesRepBelowTargetSnapshot>[
          // Ritmo 445/dia * 20 dias projetado = 8900 => 89%.
          snapshotWith(targetValue: 10000, realizedValue: 4450),
        ]);

        final insights = rule.evaluate(context);

        expect(insights, hasLength(1));
        expect(insights.single.severity, InsightSeverity.medium);
      });
    });

    test('RBAC: the insight is only ever addressed to the seller\'s sales '
        'manager, never leaking across different teams', () {
      final context = contextWith(<InsightSalesRepBelowTargetSnapshot>[
        snapshotWith(
          sellerId: 'seller-1',
          recipientUserId: 'manager-1',
          targetValue: 10000,
          realizedValue: 4000,
        ),
        snapshotWith(
          sellerId: 'seller-2',
          recipientUserId: 'manager-2',
          targetValue: 10000,
          realizedValue: 4000,
        ),
      ]);

      final insights = rule.evaluate(context);

      expect(insights, hasLength(2));
      final bySeller = {for (final i in insights) i.sellerId: i};
      expect(bySeller['seller-1']!.recipientUserId, 'manager-1');
      expect(bySeller['seller-2']!.recipientUserId, 'manager-2');
      expect(
        bySeller['seller-1']!.recipientUserId,
        isNot(bySeller['seller-2']!.recipientUserId),
      );
    });

    test('quick action points to the seller detail with the right payload', () {
      final context = contextWith(<InsightSalesRepBelowTargetSnapshot>[
        snapshotWith(targetValue: 10000, realizedValue: 4000),
      ]);

      final insight = rule.evaluate(context).single;

      expect(insight.quickAction.type, InsightActionType.viewSellerDetail);
      expect(insight.quickAction.sellerId, 'seller-1');
      expect(
        insight.secondaryActions.single.type,
        InsightActionType.viewOpportunities,
      );
      expect(insight.secondaryActions.single.sellerId, 'seller-1');
    });

    test('ignores snapshots from a different organization/company', () {
      final context = InsightContext(
        organizationId: 'org-1',
        companyId: 'company-1',
        asOf: asOf,
        dataset: InsightDataset(
          settings: settings,
          salesRepBelowTargetSnapshots: <InsightSalesRepBelowTargetSnapshot>[
            InsightSalesRepBelowTargetSnapshot(
              sellerId: 'seller-9',
              organizationId: 'org-2',
              companyId: 'company-1',
              recipientUserId: 'manager-9',
              sellerName: 'Outra Org',
              periodLabel: 'Setembro/2026',
              periodStartDate: periodStart,
              periodEndDate: periodEnd,
              targetValue: 10000,
              realizedValue: 1000,
              elapsedRelevantDays: 10,
              totalRelevantDays: 20,
            ),
          ],
        ),
      );

      expect(rule.evaluate(context), isEmpty);
    });
  });
}
