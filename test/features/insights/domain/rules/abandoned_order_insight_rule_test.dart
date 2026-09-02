import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/insights/insights.dart';

void main() {
  group('AbandonedDraftOrderInsightRule', () {
    const rule = AbandonedDraftOrderInsightRule();
    const settings = InsightOrganizationSettings(
      abandonedOrderSavedCartThresholdHours: 24,
      abandonedOrderAbandonedThresholdHours: 72,
    );
    final asOf = DateTime.utc(2026, 9, 1, 12);

    InsightContext contextWith(List<InsightAbandonedOrderSnapshot> snapshots) {
      return InsightContext(
        organizationId: 'org-1',
        companyId: 'company-1',
        asOf: asOf,
        dataset: InsightDataset(
          settings: settings,
          abandonedOrderSnapshots: snapshots,
        ),
      );
    }

    InsightAbandonedOrderSnapshot snapshotStaleFor({
      required String orderId,
      required Duration staleFor,
      bool hasPendingOutboxSync = false,
      bool startedInServiceContext = false,
      bool hasInvalidReference = false,
      String? invalidReferenceReason,
    }) {
      return InsightAbandonedOrderSnapshot(
        orderId: orderId,
        organizationId: 'org-1',
        companyId: 'company-1',
        recipientUserId: 'seller-1',
        customerId: 'customer-1',
        customerName: 'Boutique Aurora',
        lastContentChangeAt: asOf.subtract(staleFor),
        itemCount: 4,
        estimatedValue: 1200,
        hasPendingOutboxSync: hasPendingOutboxSync,
        startedInServiceContext: startedInServiceContext,
        hasInvalidReference: hasInvalidReference,
        invalidReferenceReason: invalidReferenceReason,
      );
    }

    test('does not raise an insight for a draft edited recently', () {
      final context = contextWith(<InsightAbandonedOrderSnapshot>[
        snapshotStaleFor(
          orderId: 'order-1',
          staleFor: const Duration(hours: 2),
        ),
      ]);

      expect(rule.evaluate(context), isEmpty);
    });

    test('raises "carrinho salvo" (low severity) exactly at the saved-cart '
        'threshold', () {
      final context = contextWith(<InsightAbandonedOrderSnapshot>[
        snapshotStaleFor(
          orderId: 'order-1',
          staleFor: const Duration(hours: 24),
        ),
      ]);

      final insights = rule.evaluate(context);

      expect(insights, hasLength(1));
      expect(insights.single.severity, InsightSeverity.low);
      expect(insights.single.title, contains('Carrinho salvo'));
    });

    test('stays "carrinho salvo" just below the abandoned threshold', () {
      final context = contextWith(<InsightAbandonedOrderSnapshot>[
        snapshotStaleFor(
          orderId: 'order-1',
          staleFor: const Duration(hours: 71, minutes: 59),
        ),
      ]);

      final insights = rule.evaluate(context);

      expect(insights.single.severity, InsightSeverity.low);
    });

    test('raises "pedido abandonado" (medium severity) exactly at the '
        'abandoned threshold', () {
      final context = contextWith(<InsightAbandonedOrderSnapshot>[
        snapshotStaleFor(
          orderId: 'order-1',
          staleFor: const Duration(hours: 72),
        ),
      ]);

      final insights = rule.evaluate(context);

      expect(insights, hasLength(1));
      expect(insights.single.severity, InsightSeverity.medium);
      expect(insights.single.title, contains('Pedido abandonado'));
    });

    test('never treats a draft pending only Outbox sync as abandoned', () {
      final context = contextWith(<InsightAbandonedOrderSnapshot>[
        snapshotStaleFor(
          orderId: 'order-1',
          staleFor: const Duration(hours: 1),
          hasPendingOutboxSync: true,
        ),
      ]);

      expect(rule.evaluate(context), isEmpty);
    });

    test('resume-order quick action restores the exact draft by id', () {
      final context = contextWith(<InsightAbandonedOrderSnapshot>[
        snapshotStaleFor(
          orderId: 'order-42',
          staleFor: const Duration(hours: 30),
        ),
      ]);

      final insight = rule.evaluate(context).single;

      expect(insight.quickAction.type, InsightActionType.resumeOrder);
      expect(insight.quickAction.payload['orderId'], 'order-42');
      expect(insight.quickAction.customerId, 'customer-1');
    });

    test('adds "Contatar cliente" as a secondary action only when the draft '
        'started in a service context', () {
      final withoutServiceContext = rule
          .evaluate(
            contextWith(<InsightAbandonedOrderSnapshot>[
              snapshotStaleFor(
                orderId: 'order-1',
                staleFor: const Duration(hours: 30),
              ),
            ]),
          )
          .single;
      final withServiceContext = rule
          .evaluate(
            contextWith(<InsightAbandonedOrderSnapshot>[
              snapshotStaleFor(
                orderId: 'order-2',
                staleFor: const Duration(hours: 30),
                startedInServiceContext: true,
              ),
            ]),
          )
          .single;

      expect(
        withoutServiceContext.secondaryActions.any(
          (action) => action.type == InsightActionType.scheduleContact,
        ),
        isFalse,
      );
      expect(
        withServiceContext.secondaryActions.any(
          (action) => action.type == InsightActionType.scheduleContact,
        ),
        isTrue,
      );
    });

    test('surfaces an explicit warning when the draft references stale '
        'customer/product/price-list data, never reopening silently', () {
      final context = contextWith(<InsightAbandonedOrderSnapshot>[
        snapshotStaleFor(
          orderId: 'order-1',
          staleFor: const Duration(hours: 30),
          hasInvalidReference: true,
          invalidReferenceReason: 'Tabela de preco expirada',
        ),
      ]);

      final insight = rule.evaluate(context).single;

      expect(
        insight.evidence.any((e) => e.code == 'invalid_reference_warning'),
        isTrue,
      );
      expect(insight.quickAction.payload['hasInvalidReference'], isTrue);
      expect(insight.recommendation, contains('tabela de preco'));
    });
  });
}
