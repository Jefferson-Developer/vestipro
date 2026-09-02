import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/insights/insights.dart';

void main() {
  group('HighStockLowTurnoverInsightRule', () {
    const rule = HighStockLowTurnoverInsightRule();
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
        productName: 'Camisa Social',
        variantLabel: 'Branco P',
        categoryId: categoryId,
        categoryName: 'Basico',
        currentStockQuantity: 500,
        coverageDays: coverageDays,
        turnoverIndex: turnoverIndex,
        daysWithoutRelevantSale: 45,
        averageDailyConsumption: 1.5,
        suggestedReorderPointQuantity: 45,
        isDiscontinued: isDiscontinued,
      );
    }

    test('fires when coverage is above threshold and turnover is below '
        'threshold', () {
      final context = contextWith(<InsightStockPositionSnapshot>[
        snapshotWith(coverageDays: 90, turnoverIndex: 0.2),
      ]);

      final insights = rule.evaluate(context);

      expect(insights, hasLength(1));
      final insight = insights.single;
      expect(insight.type, InsightType.highStockLowTurnover);
      expect(insight.productId, 'variant-1');
      expect(
        insight.evidence.map((item) => item.code),
        containsAll(<String>[
          'high_stock_current_quantity',
          'high_stock_coverage_days',
          'high_stock_turnover_index',
          'high_stock_days_without_relevant_sale',
        ]),
      );
      expect(insight.quickAction.type, InsightActionType.suggestCampaign);
    });

    test('does not fire when coverage is within the configured threshold, even '
        'with low turnover', () {
      final context = contextWith(<InsightStockPositionSnapshot>[
        snapshotWith(coverageDays: 30, turnoverIndex: 0.2),
      ]);

      expect(rule.evaluate(context), isEmpty);
    });

    test('does not fire when turnover is above the configured threshold, even '
        'with high coverage', () {
      final context = contextWith(<InsightStockPositionSnapshot>[
        snapshotWith(coverageDays: 90, turnoverIndex: 1.2),
      ]);

      expect(rule.evaluate(context), isEmpty);
    });

    test('respects category-specific thresholds', () {
      final settings = const InsightOrganizationSettings(
        highStockCoverageDaysThresholdByCategory: <String, double>{
          'cat-fashion': 20,
        },
        lowTurnoverIndexThresholdByCategory: <String, double>{
          'cat-fashion': 1.0,
        },
      );

      // Would not fire under the default (basic) thresholds...
      final basicContext = contextWith(<InsightStockPositionSnapshot>[
        snapshotWith(
          coverageDays: 25,
          turnoverIndex: 0.8,
          categoryId: 'cat-basico',
        ),
      ], settings: settings);
      expect(rule.evaluate(basicContext), isEmpty);

      // ...but fires for a fashion-category product with a lower expected
      // coverage/turnover profile.
      final fashionContext = contextWith(<InsightStockPositionSnapshot>[
        snapshotWith(
          coverageDays: 25,
          turnoverIndex: 0.8,
          categoryId: 'cat-fashion',
        ),
      ], settings: settings);
      expect(rule.evaluate(fashionContext), hasLength(1));
    });

    test('includes discontinued products as liquidation candidates', () {
      final context = contextWith(<InsightStockPositionSnapshot>[
        snapshotWith(
          coverageDays: 90,
          turnoverIndex: 0.2,
          isDiscontinued: true,
        ),
      ]);

      expect(rule.evaluate(context), hasLength(1));
    });
  });
}
