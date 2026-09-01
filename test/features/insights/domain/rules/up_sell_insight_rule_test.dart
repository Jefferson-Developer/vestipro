import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/insights/insights.dart';

void main() {
  group('UpSellInsightRule', () {
    const rule = UpSellInsightRule();
    final asOf = DateTime.utc(2026, 9, 1, 12);

    InsightContext contextWith(
      List<InsightUpSellSnapshot> snapshots, {
      InsightOrganizationSettings settings = const InsightOrganizationSettings(),
    }) {
      return InsightContext(
        organizationId: 'org-1',
        companyId: 'company-1',
        asOf: asOf,
        dataset: InsightDataset(settings: settings, upSellSnapshots: snapshots),
      );
    }

    test(
      'fires when the customer sits below the higher-volume comparison '
      "group's average ticket in a category the customer already buys",
      () {
        final context = contextWith(<InsightUpSellSnapshot>[
          const InsightUpSellSnapshot(
            customerId: 'customer-1',
            organizationId: 'org-1',
            companyId: 'company-1',
            recipientUserId: 'seller-1',
            customerName: 'Boutique Aurora',
            comparisonGroupLabel: 'Mesmo segmento (Premium) e regiao (Sul), maior volume',
            comparisonGroupSize: 10,
            candidates: <InsightUpSellCategoryCandidate>[
              InsightUpSellCategoryCandidate(
                categoryId: 'cat-vestidos',
                categoryName: 'Vestidos',
                customerAverageTicket: 700,
                customerAverageQuantity: 10,
                peerAverageTicket: 1000,
                peerAverageQuantity: 15,
                variantCandidates: <InsightUpSellVariantCandidate>[
                  InsightUpSellVariantCandidate(
                    variantId: 'variant-azul-m',
                    variantLabel: 'Azul - M',
                    desiredAdditionalQuantity: 5,
                    availableStock: 20,
                  ),
                ],
              ),
            ],
          ),
        ]);

        final insights = rule.evaluate(context);

        expect(insights, hasLength(1));
        final insight = insights.single;
        expect(insight.customerId, 'customer-1');
        expect(insight.type, InsightType.upSell);
        expect(
          insight.evidence.map((item) => item.code),
          containsAll(<String>[
            'up_sell_comparison_group',
            'up_sell_customer_average_ticket:cat-vestidos',
            'up_sell_peer_average_ticket:cat-vestidos',
            'up_sell_ticket_gap:cat-vestidos',
          ]),
        );
        expect(
          insight.evidence
              .firstWhere((item) => item.code == 'up_sell_comparison_group')
              .value,
          'Mesmo segmento (Premium) e regiao (Sul), maior volume',
        );
        expect(insight.quickAction.type, InsightActionType.expandGrid);
        expect(insight.quickAction.payload['categoryId'], 'cat-vestidos');
        expect(
          insight.quickAction.payload['variantQuantities'],
          <String, Object?>{'variant-azul-m': 5},
        );
      },
    );

    test(
      'does not fire when the customer is already at or above the '
      'comparison group average in the category',
      () {
        final context = contextWith(<InsightUpSellSnapshot>[
          const InsightUpSellSnapshot(
            customerId: 'customer-2',
            organizationId: 'org-1',
            companyId: 'company-1',
            recipientUserId: 'seller-1',
            customerName: 'Loja Sol',
            comparisonGroupLabel: 'Mesmo segmento e regiao, maior volume',
            comparisonGroupSize: 8,
            candidates: <InsightUpSellCategoryCandidate>[
              InsightUpSellCategoryCandidate(
                categoryId: 'cat-vestidos',
                categoryName: 'Vestidos',
                customerAverageTicket: 1200,
                customerAverageQuantity: 18,
                peerAverageTicket: 1000,
                peerAverageQuantity: 15,
                variantCandidates: <InsightUpSellVariantCandidate>[
                  InsightUpSellVariantCandidate(
                    variantId: 'variant-azul-m',
                    variantLabel: 'Azul - M',
                    desiredAdditionalQuantity: 5,
                    availableStock: 20,
                  ),
                ],
              ),
              InsightUpSellCategoryCandidate(
                categoryId: 'cat-blusas',
                categoryName: 'Blusas',
                customerAverageTicket: 400,
                customerAverageQuantity: 6,
                peerAverageTicket: 400,
                peerAverageQuantity: 6,
              ),
            ],
          ),
        ]);

        expect(rule.evaluate(context), isEmpty);
      },
    );

    test(
      'does not fire when the gap is below the configured minimum relevant '
      'and sustainable difference',
      () {
        final context = contextWith(
          <InsightUpSellSnapshot>[
            const InsightUpSellSnapshot(
              customerId: 'customer-3',
              organizationId: 'org-1',
              companyId: 'company-1',
              recipientUserId: 'seller-1',
              customerName: 'Multimarcas Estrela',
              comparisonGroupLabel: 'Mesmo segmento e regiao, maior volume',
              comparisonGroupSize: 12,
              candidates: <InsightUpSellCategoryCandidate>[
                InsightUpSellCategoryCandidate(
                  categoryId: 'cat-vestidos',
                  categoryName: 'Vestidos',
                  customerAverageTicket: 960,
                  customerAverageQuantity: 14,
                  peerAverageTicket: 1000,
                  peerAverageQuantity: 15,
                  variantCandidates: <InsightUpSellVariantCandidate>[
                    InsightUpSellVariantCandidate(
                      variantId: 'variant-azul-m',
                      variantLabel: 'Azul - M',
                      desiredAdditionalQuantity: 2,
                      availableStock: 20,
                    ),
                  ],
                ),
              ],
            ),
          ],
          settings: const InsightOrganizationSettings(
            upSellMinimumTicketGapPercentage: 0.15,
          ),
        );

        expect(rule.evaluate(context), isEmpty);
      },
    );

    test(
      'caps the suggested additional quantity by the real available stock '
      'of the variant',
      () {
        final context = contextWith(<InsightUpSellSnapshot>[
          const InsightUpSellSnapshot(
            customerId: 'customer-4',
            organizationId: 'org-1',
            companyId: 'company-1',
            recipientUserId: 'seller-1',
            customerName: 'Casa da Moda',
            comparisonGroupLabel: 'Mesmo segmento e regiao, maior volume',
            comparisonGroupSize: 9,
            candidates: <InsightUpSellCategoryCandidate>[
              InsightUpSellCategoryCandidate(
                categoryId: 'cat-vestidos',
                categoryName: 'Vestidos',
                customerAverageTicket: 500,
                customerAverageQuantity: 8,
                peerAverageTicket: 1000,
                peerAverageQuantity: 15,
                variantCandidates: <InsightUpSellVariantCandidate>[
                  InsightUpSellVariantCandidate(
                    variantId: 'variant-azul-m',
                    variantLabel: 'Azul - M',
                    desiredAdditionalQuantity: 10,
                    availableStock: 3,
                  ),
                  InsightUpSellVariantCandidate(
                    variantId: 'variant-preto-g',
                    variantLabel: 'Preto - G',
                    desiredAdditionalQuantity: 4,
                    availableStock: 0,
                  ),
                ],
              ),
            ],
          ),
        ]);

        final insights = rule.evaluate(context);

        expect(insights, hasLength(1));
        final quantities =
            insights.single.quickAction.payload['variantQuantities']
                as Map<String, Object?>;
        // Capped at the real stock balance (3), never the desired 10.
        expect(quantities['variant-azul-m'], 3);
        // A variant with zero stock is never suggested.
        expect(quantities.containsKey('variant-preto-g'), isFalse);
      },
    );

    test(
      'does not fire when every variant candidate in the category has no '
      'available stock to suggest',
      () {
        final context = contextWith(<InsightUpSellSnapshot>[
          const InsightUpSellSnapshot(
            customerId: 'customer-5',
            organizationId: 'org-1',
            companyId: 'company-1',
            recipientUserId: 'seller-1',
            customerName: 'Studio Fashion',
            comparisonGroupLabel: 'Mesmo segmento e regiao, maior volume',
            comparisonGroupSize: 6,
            candidates: <InsightUpSellCategoryCandidate>[
              InsightUpSellCategoryCandidate(
                categoryId: 'cat-vestidos',
                categoryName: 'Vestidos',
                customerAverageTicket: 500,
                customerAverageQuantity: 8,
                peerAverageTicket: 1000,
                peerAverageQuantity: 15,
                variantCandidates: <InsightUpSellVariantCandidate>[
                  InsightUpSellVariantCandidate(
                    variantId: 'variant-azul-m',
                    variantLabel: 'Azul - M',
                    desiredAdditionalQuantity: 5,
                    availableStock: 0,
                  ),
                ],
              ),
            ],
          ),
        ]);

        expect(rule.evaluate(context), isEmpty);
      },
    );
  });
}
