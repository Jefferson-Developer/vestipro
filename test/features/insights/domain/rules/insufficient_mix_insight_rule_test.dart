import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/insights/insights.dart';

void main() {
  group('InsufficientMixInsightRule', () {
    const rule = InsufficientMixInsightRule();
    final asOf = DateTime.utc(2026, 9, 1, 12);

    InsightContext contextWith(
      List<InsightInsufficientMixSnapshot> snapshots, {
      InsightOrganizationSettings settings =
          const InsightOrganizationSettings(),
    }) {
      return InsightContext(
        organizationId: 'org-1',
        companyId: 'company-1',
        asOf: asOf,
        dataset: InsightDataset(
          settings: settings,
          insufficientMixSnapshots: snapshots,
        ),
      );
    }

    // Universe of 4 categories with adoption rates summing to a benchmark of
    // 2.6 distinct categories on average per peer in the comparison group.
    List<InsightInsufficientMixCategoryCandidate> universe({
      required bool vestidos,
      required bool blusas,
      required bool calcas,
      required bool acessorios,
    }) {
      return <InsightInsufficientMixCategoryCandidate>[
        InsightInsufficientMixCategoryCandidate(
          categoryId: 'cat-vestidos',
          categoryName: 'Vestidos',
          peerAdoptionRate: 0.9,
          purchasedByCustomer: vestidos,
        ),
        InsightInsufficientMixCategoryCandidate(
          categoryId: 'cat-blusas',
          categoryName: 'Blusas',
          peerAdoptionRate: 0.8,
          purchasedByCustomer: blusas,
        ),
        InsightInsufficientMixCategoryCandidate(
          categoryId: 'cat-calcas',
          categoryName: 'Calcas',
          peerAdoptionRate: 0.6,
          purchasedByCustomer: calcas,
        ),
        InsightInsufficientMixCategoryCandidate(
          categoryId: 'cat-acessorios',
          categoryName: 'Acessorios',
          peerAdoptionRate: 0.3,
          purchasedByCustomer: acessorios,
        ),
      ];
    }

    test('fires when the customer buys fewer distinct categories than the '
        "comparison group's mix benchmark", () {
      final context = contextWith(<InsightInsufficientMixSnapshot>[
        InsightInsufficientMixSnapshot(
          customerId: 'customer-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          recipientUserId: 'seller-1',
          customerName: 'Boutique Aurora',
          comparisonGroupLabel: 'Mesmo segmento (Premium) e regiao (Sul)',
          comparisonGroupSize: 10,
          candidates: universe(
            vestidos: true,
            blusas: false,
            calcas: false,
            acessorios: false,
          ),
        ),
      ]);

      final insights = rule.evaluate(context);

      expect(insights, hasLength(1));
      final insight = insights.single;
      expect(insight.customerId, 'customer-1');
      expect(insight.type, InsightType.insufficientMix);
      expect(
        insight.evidence.map((item) => item.code),
        containsAll(<String>[
          'insufficient_mix_comparison_group',
          'insufficient_mix_customer_category_count',
          'insufficient_mix_benchmark_category_count',
          'insufficient_mix_ratio',
        ]),
      );
      expect(
        insight.evidence
            .firstWhere(
              (item) =>
                  item.code == 'insufficient_mix_benchmark_category_count',
            )
            .numericValue,
        closeTo(2.6, 0.0001),
      );
      expect(insight.quickAction.type, InsightActionType.viewCategory);
      expect(insight.quickAction.payload['categoryIds'], <String>[
        'cat-blusas',
        'cat-calcas',
        'cat-acessorios',
      ]);
    });

    test('does not fire when the customer is already at or above the mix '
        'benchmark of the comparison group', () {
      final context = contextWith(<InsightInsufficientMixSnapshot>[
        InsightInsufficientMixSnapshot(
          customerId: 'customer-2',
          organizationId: 'org-1',
          companyId: 'company-1',
          recipientUserId: 'seller-1',
          customerName: 'Loja Sol',
          comparisonGroupLabel: 'Mesmo segmento e regiao',
          comparisonGroupSize: 8,
          candidates: universe(
            vestidos: true,
            blusas: true,
            calcas: true,
            acessorios: false,
          ),
        ),
      ]);

      expect(rule.evaluate(context), isEmpty);
    });

    test('excludes organization-configured irrelevant categories from the mix '
        'calculation, both from the benchmark and from the customer count', () {
      // Without exclusion: customer buys only Vestidos (1) against a
      // benchmark of 2.6 -> ratio ~38%, fires.
      // With Blusas and Calcas excluded from the calculation: benchmark
      // becomes 0.9 (Vestidos) + 0.3 (Acessorios) = 1.2, customer count
      // stays 1 (Vestidos) -> ratio ~83%, at/above the 70% threshold, does
      // not fire.
      final snapshot = InsightInsufficientMixSnapshot(
        customerId: 'customer-3',
        organizationId: 'org-1',
        companyId: 'company-1',
        recipientUserId: 'seller-1',
        customerName: 'Multimarcas Estrela',
        comparisonGroupLabel: 'Mesmo segmento e regiao',
        comparisonGroupSize: 12,
        segment: 'atacado',
        candidates: universe(
          vestidos: true,
          blusas: false,
          calcas: false,
          acessorios: false,
        ),
      );

      final withoutExclusion = contextWith(<InsightInsufficientMixSnapshot>[
        snapshot,
      ]);
      expect(rule.evaluate(withoutExclusion), hasLength(1));

      final withExclusion = contextWith(
        <InsightInsufficientMixSnapshot>[snapshot],
        settings: const InsightOrganizationSettings(
          insufficientMixExcludedCategoryIdsBySegment: <String, Set<String>>{
            'atacado': <String>{'cat-blusas', 'cat-calcas'},
          },
        ),
      );
      expect(rule.evaluate(withExclusion), isEmpty);
    });

    test('recomputes the benchmark when the comparison group changes for the '
        'same customer', () {
      final customerCandidates = <InsightInsufficientMixCategoryCandidate>[
        InsightInsufficientMixCategoryCandidate(
          categoryId: 'cat-vestidos',
          categoryName: 'Vestidos',
          peerAdoptionRate: 0.9,
          purchasedByCustomer: true,
        ),
        InsightInsufficientMixCategoryCandidate(
          categoryId: 'cat-blusas',
          categoryName: 'Blusas',
          peerAdoptionRate: 0.8,
        ),
      ];

      // Comparison group A (broader, higher adoption): benchmark 1.7,
      // customer count 1 -> ratio ~59%, fires.
      final groupA = contextWith(<InsightInsufficientMixSnapshot>[
        InsightInsufficientMixSnapshot(
          customerId: 'customer-4',
          organizationId: 'org-1',
          companyId: 'company-1',
          recipientUserId: 'seller-1',
          customerName: 'Casa da Moda',
          comparisonGroupLabel: 'Mesmo segmento (Premium) e regiao (Sul)',
          comparisonGroupSize: 10,
          candidates: customerCandidates,
        ),
      ]);
      expect(rule.evaluate(groupA), hasLength(1));

      // Comparison group B (narrower region, lower adoption): benchmark
      // recalculated to 1.0, customer count 1 -> ratio 100%, does not
      // fire.
      final groupB = contextWith(<InsightInsufficientMixSnapshot>[
        InsightInsufficientMixSnapshot(
          customerId: 'customer-4',
          organizationId: 'org-1',
          companyId: 'company-1',
          recipientUserId: 'seller-1',
          customerName: 'Casa da Moda',
          comparisonGroupLabel: 'Mesmo segmento (Premium) e regiao (Nordeste)',
          comparisonGroupSize: 4,
          candidates: <InsightInsufficientMixCategoryCandidate>[
            InsightInsufficientMixCategoryCandidate(
              categoryId: 'cat-vestidos',
              categoryName: 'Vestidos',
              peerAdoptionRate: 0.7,
              purchasedByCustomer: true,
            ),
            InsightInsufficientMixCategoryCandidate(
              categoryId: 'cat-blusas',
              categoryName: 'Blusas',
              peerAdoptionRate: 0.3,
            ),
          ],
        ),
      ]);
      expect(rule.evaluate(groupB), isEmpty);
    });
  });
}
