import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/insights/insights.dart';

void main() {
  group('CrossSellInsightRule', () {
    const rule = CrossSellInsightRule();
    final asOf = DateTime.utc(2026, 9, 1, 12);

    InsightContext contextWith(List<InsightCrossSellSnapshot> snapshots) {
      return InsightContext(
        organizationId: 'org-1',
        companyId: 'company-1',
        asOf: asOf,
        dataset: InsightDataset(
          settings: const InsightOrganizationSettings(),
          crossSellSnapshots: snapshots,
        ),
      );
    }

    test(
      'fires when a category popular among similar customers is absent from '
      "the customer's own purchase history",
      () {
        final context = contextWith(<InsightCrossSellSnapshot>[
          const InsightCrossSellSnapshot(
            customerId: 'customer-1',
            organizationId: 'org-1',
            companyId: 'company-1',
            recipientUserId: 'seller-1',
            customerName: 'Boutique Aurora',
            similarityGroupLabel: 'Mesmo segmento (Premium) e regiao (Sul)',
            similarityGroupSize: 12,
            candidates: <InsightCrossSellCategoryCandidate>[
              InsightCrossSellCategoryCandidate(
                categoryId: 'cat-vestidos',
                categoryName: 'Vestidos',
                peerAdoptionRate: 0.75,
                peerAverageTicket: 1200,
              ),
            ],
          ),
        ]);

        final insights = rule.evaluate(context);

        expect(insights, hasLength(1));
        final insight = insights.single;
        expect(insight.customerId, 'customer-1');
        expect(insight.type, InsightType.crossSell);
        expect(
          insight.evidence.map((item) => item.code),
          containsAll(<String>[
            'similarity_group',
            'cross_sell_category_adoption:cat-vestidos',
            'cross_sell_category_ticket:cat-vestidos',
          ]),
        );
        expect(
          insight.evidence.firstWhere((item) => item.code == 'similarity_group').value,
          'Mesmo segmento (Premium) e regiao (Sul)',
        );
        expect(insight.quickAction.type, InsightActionType.startOrder);
        expect(insight.quickAction.payload['categoryId'], 'cat-vestidos');
      },
    );

    test(
      'does not fire when the customer already buys every relevant category '
      'from the comparison group',
      () {
        final context = contextWith(<InsightCrossSellSnapshot>[
          const InsightCrossSellSnapshot(
            customerId: 'customer-2',
            organizationId: 'org-1',
            companyId: 'company-1',
            recipientUserId: 'seller-1',
            customerName: 'Loja Sol',
            similarityGroupLabel: 'Mesmo segmento e regiao',
            similarityGroupSize: 8,
            candidates: <InsightCrossSellCategoryCandidate>[
              InsightCrossSellCategoryCandidate(
                categoryId: 'cat-vestidos',
                categoryName: 'Vestidos',
                peerAdoptionRate: 0.75,
                peerAverageTicket: 1200,
                alreadyPurchasedByCustomer: true,
              ),
              InsightCrossSellCategoryCandidate(
                categoryId: 'cat-blusas',
                categoryName: 'Blusas',
                peerAdoptionRate: 0.5,
                peerAverageTicket: 400,
                alreadyPurchasedByCustomer: true,
              ),
            ],
          ),
        ]);

        expect(rule.evaluate(context), isEmpty);
      },
    );

    test(
      'limits suggestions to 3 per customer, ordered by relevance '
      '(adoption x average ticket)',
      () {
        final context = contextWith(<InsightCrossSellSnapshot>[
          const InsightCrossSellSnapshot(
            customerId: 'customer-3',
            organizationId: 'org-1',
            companyId: 'company-1',
            recipientUserId: 'seller-1',
            customerName: 'Multimarcas Estrela',
            similarityGroupLabel: 'Mesmo segmento e regiao',
            similarityGroupSize: 20,
            candidates: <InsightCrossSellCategoryCandidate>[
              InsightCrossSellCategoryCandidate(
                categoryId: 'cat-low',
                categoryName: 'Acessorios',
                peerAdoptionRate: 0.2,
                peerAverageTicket: 100,
              ),
              InsightCrossSellCategoryCandidate(
                categoryId: 'cat-high',
                categoryName: 'Vestidos',
                peerAdoptionRate: 0.9,
                peerAverageTicket: 1500,
              ),
              InsightCrossSellCategoryCandidate(
                categoryId: 'cat-mid-1',
                categoryName: 'Blusas',
                peerAdoptionRate: 0.6,
                peerAverageTicket: 500,
              ),
              InsightCrossSellCategoryCandidate(
                categoryId: 'cat-mid-2',
                categoryName: 'Calcas',
                peerAdoptionRate: 0.55,
                peerAverageTicket: 450,
              ),
              InsightCrossSellCategoryCandidate(
                categoryId: 'cat-lowest',
                categoryName: 'Meias',
                peerAdoptionRate: 0.1,
                peerAverageTicket: 50,
              ),
            ],
          ),
        ]);

        final insights = rule.evaluate(context);

        expect(insights, hasLength(1));
        final insight = insights.single;
        expect(insight.quickAction.payload['categoryId'], 'cat-high');
        expect(
          insight.secondaryActions
              .map((action) => action.payload['categoryId'])
              .toList(),
          <String>['cat-mid-1', 'cat-mid-2'],
        );
        // Only the top 3 by relevance surface as evidence: cat-high,
        // cat-mid-1 and cat-mid-2. cat-low and cat-lowest are excluded.
        expect(
          insight.evidence
              .where((item) => item.code.startsWith('cross_sell_category_adoption:'))
              .length,
          3,
        );
        expect(
          insight.evidence.map((item) => item.code),
          isNot(contains('cross_sell_category_adoption:cat-low')),
        );
      },
    );

    test(
      'excludes a category unavailable in the customer price list even when '
      'popular among similar customers',
      () {
        final context = contextWith(<InsightCrossSellSnapshot>[
          const InsightCrossSellSnapshot(
            customerId: 'customer-4',
            organizationId: 'org-1',
            companyId: 'company-1',
            recipientUserId: 'seller-1',
            customerName: 'Casa da Moda',
            similarityGroupLabel: 'Mesmo segmento e regiao',
            similarityGroupSize: 10,
            candidates: <InsightCrossSellCategoryCandidate>[
              InsightCrossSellCategoryCandidate(
                categoryId: 'cat-unavailable',
                categoryName: 'Casacos',
                peerAdoptionRate: 0.8,
                peerAverageTicket: 900,
                isAvailableInCustomerPriceList: false,
              ),
              InsightCrossSellCategoryCandidate(
                categoryId: 'cat-discontinued',
                categoryName: 'Colecao passada',
                peerAdoptionRate: 0.7,
                peerAverageTicket: 800,
                isActiveCollection: false,
              ),
            ],
          ),
        ]);

        expect(rule.evaluate(context), isEmpty);
      },
    );
  });
}
