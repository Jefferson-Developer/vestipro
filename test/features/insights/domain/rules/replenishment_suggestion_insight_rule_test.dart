import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/insights/insights.dart';

void main() {
  group('ReplenishmentSuggestionInsightRule', () {
    const rule = ReplenishmentSuggestionInsightRule();
    final asOf = DateTime.utc(2026, 9, 1, 12);

    InsightContext contextWith(
      List<InsightStockPositionSnapshot> snapshots, {
      InsightOrganizationSettings settings =
          const InsightOrganizationSettings(),
    }) {
      return InsightContext(
        organizationId: 'org-1',
        companyId: 'company-1',
        asOf: asOf,
        dataset: InsightDataset(
          settings: settings,
          stockPositionSnapshots: snapshots,
        ),
      );
    }

    InsightStockPositionSnapshot snapshotWith({
      String productId = 'product-1',
      String? variantId = 'variant-1',
      required double coverageDays,
      required double turnoverIndex,
      String categoryId = 'cat-basico',
      bool isDiscontinued = false,
    }) {
      return InsightStockPositionSnapshot(
        productId: productId,
        variantId: variantId,
        organizationId: 'org-1',
        companyId: 'company-1',
        recipientUserId: 'buyer-1',
        productName: 'Calca Jeans',
        variantLabel: 'Azul 40',
        categoryId: categoryId,
        categoryName: 'Basico',
        currentStockQuantity: 8,
        coverageDays: coverageDays,
        turnoverIndex: turnoverIndex,
        daysWithoutRelevantSale: 0,
        averageDailyConsumption: 3,
        suggestedReorderPointQuantity: 90,
        isDiscontinued: isDiscontinued,
      );
    }

    test('fires for a product with high turnover and coverage below the '
        'configured minimum', () {
      final context = contextWith(<InsightStockPositionSnapshot>[
        snapshotWith(coverageDays: 5, turnoverIndex: 2.5),
      ]);

      final insights = rule.evaluate(context);

      expect(insights, hasLength(1));
      final insight = insights.single;
      expect(insight.type, InsightType.replenishmentSuggestion);
      expect(insight.productId, 'variant-1');
      expect(
        insight.evidence.map((item) => item.code),
        containsAll(<String>[
          'replenishment_turnover_index',
          'replenishment_coverage_days',
          'replenishment_suggested_reorder_point',
        ]),
      );
      expect(insight.quickAction.type, InsightActionType.notifyReplenishment);
      expect(
        insight.quickAction.payload['suggestedReorderPointQuantity'],
        90.0,
      );
    });

    test('does not fire when coverage is comfortable', () {
      final context = contextWith(<InsightStockPositionSnapshot>[
        snapshotWith(coverageDays: 40, turnoverIndex: 2.5),
      ]);

      expect(rule.evaluate(context), isEmpty);
    });

    test('does not fire when turnover is below the configured minimum, '
        'even with low coverage', () {
      final context = contextWith(<InsightStockPositionSnapshot>[
        snapshotWith(coverageDays: 5, turnoverIndex: 0.8),
      ]);

      expect(rule.evaluate(context), isEmpty);
    });

    test('excludes discontinued products from the replenishment rule', () {
      final context = contextWith(<InsightStockPositionSnapshot>[
        snapshotWith(coverageDays: 5, turnoverIndex: 2.5, isDiscontinued: true),
      ]);

      expect(rule.evaluate(context), isEmpty);
    });

    test('respects category-specific thresholds', () {
      final settings = const InsightOrganizationSettings(
        replenishmentLowCoverageDaysThresholdByCategory: <String, double>{
          'cat-fashion': 25,
        },
        replenishmentHighTurnoverIndexThresholdByCategory: <String, double>{
          'cat-fashion': 1.0,
        },
      );

      // Would not fire under the default (basic) thresholds...
      final basicContext = contextWith(<InsightStockPositionSnapshot>[
        snapshotWith(
          coverageDays: 20,
          turnoverIndex: 1.2,
          categoryId: 'cat-basico',
        ),
      ], settings: settings);
      expect(rule.evaluate(basicContext), isEmpty);

      // ...but fires for a fashion-category product with a higher expected
      // turnover/lower coverage profile.
      final fashionContext = contextWith(<InsightStockPositionSnapshot>[
        snapshotWith(
          coverageDays: 20,
          turnoverIndex: 1.2,
          categoryId: 'cat-fashion',
        ),
      ], settings: settings);
      expect(rule.evaluate(fashionContext), hasLength(1));
    });
  });
}
