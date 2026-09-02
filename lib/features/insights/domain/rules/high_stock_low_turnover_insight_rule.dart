import 'package:injectable/injectable.dart';

import '../entities/insight.dart';
import '../entities/insight_action.dart';
import '../entities/insight_context.dart';
import '../entities/insight_estimated_impact.dart';
import '../entities/insight_evidence.dart';
import '../services/insight_rule.dart';
import '../value_objects/insight_action_type.dart';
import '../value_objects/insight_severity.dart';
import '../value_objects/insight_status.dart';
import '../value_objects/insight_type.dart';

/// Identifies products/variants whose stock balance covers more days than
/// the organization/category-configured coverage threshold while rotating
/// below the minimum expected turnover index (TASK-094) — excess stock
/// parked with little to no sales movement, and therefore candidates for a
/// liquidation/promotional campaign.
///
/// This is the mirror-opposite signal of
/// [ReplenishmentSuggestionInsightRule]: by construction (high coverage +
/// low turnover here, versus low coverage + high turnover there), the two
/// rules can never both fire for the same product/variant in the same
/// cycle, as long as the organization's thresholds are configured
/// consistently (high-stock coverage threshold above the replenishment
/// low-coverage threshold, low-turnover threshold below the replenishment
/// high-turnover threshold).
///
/// Discontinued/out-of-current-collection products are not excluded here —
/// they are, in fact, prime liquidation candidates — unlike
/// [ReplenishmentSuggestionInsightRule], which never suggests restocking
/// them.
@lazySingleton
final class HighStockLowTurnoverInsightRule implements InsightRule {
  const HighStockLowTurnoverInsightRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    final insights = <Insight>[];
    final settings = context.dataset.settings;
    final expiresAt = context.asOf.add(settings.defaultLifetime);

    for (final snapshot in context.dataset.stockPositionSnapshots) {
      if (snapshot.organizationId != context.organizationId ||
          snapshot.companyId != context.companyId) {
        continue;
      }

      final coverageThreshold = settings.resolveHighStockCoverageDaysThreshold(
        snapshot.categoryId,
      );
      final turnoverThreshold = settings.resolveLowTurnoverIndexThreshold(
        snapshot.categoryId,
      );
      if (snapshot.coverageDays < coverageThreshold ||
          snapshot.turnoverIndex > turnoverThreshold) {
        continue;
      }

      final entityId = snapshot.variantId ?? snapshot.productId;
      final displayName = snapshot.variantLabel == null
          ? snapshot.productName
          : '${snapshot.productName} (${snapshot.variantLabel})';
      final coverageExcessRatio = coverageThreshold <= 0
          ? 1.0
          : (snapshot.coverageDays - coverageThreshold) / coverageThreshold;

      insights.add(
        Insight(
          id: 'high_stock_low_turnover:${snapshot.recipientUserId}:$entityId',
          type: InsightType.highStockLowTurnover,
          title: 'Estoque alto e giro baixo: $displayName',
          description:
              '$displayName tem ${snapshot.currentStockQuantity} unidade(s) '
              'em estoque, com cobertura estimada de '
              '${snapshot.coverageDays.toStringAsFixed(0)} dia(s) — acima do '
              'limiar de ${coverageThreshold.toStringAsFixed(0)} dia(s) para '
              'a categoria ${snapshot.categoryName} — e indice de giro de '
              '${snapshot.turnoverIndex.toStringAsFixed(2)}, abaixo do '
              'minimo esperado de ${turnoverThreshold.toStringAsFixed(2)}. '
              'Sem saida relevante ha ${snapshot.daysWithoutRelevantSale} '
              'dia(s).',
          evidence: <InsightEvidence>[
            InsightEvidence(
              code: 'high_stock_current_quantity',
              label: 'Saldo atual em estoque',
              value: '${snapshot.currentStockQuantity}',
              numericValue: snapshot.currentStockQuantity.toDouble(),
              unit: 'unidades',
            ),
            InsightEvidence(
              code: 'high_stock_coverage_days',
              label: 'Cobertura estimada em dias',
              value: snapshot.coverageDays.toStringAsFixed(1),
              numericValue: snapshot.coverageDays,
              unit: 'dias',
            ),
            InsightEvidence(
              code: 'high_stock_turnover_index',
              label: 'Indice de giro',
              value: snapshot.turnoverIndex.toStringAsFixed(2),
              numericValue: snapshot.turnoverIndex,
            ),
            InsightEvidence(
              code: 'high_stock_days_without_relevant_sale',
              label: 'Dias parado sem saida relevante',
              value: '${snapshot.daysWithoutRelevantSale}',
              numericValue: snapshot.daysWithoutRelevantSale.toDouble(),
              unit: 'dias',
            ),
          ],
          estimatedImpact: InsightEstimatedImpact(
            percentage: coverageExcessRatio,
          ),
          severity: _severityFor(coverageExcessRatio),
          confidenceScore: 0.6,
          recommendation:
              'Avalie incluir o produto em uma campanha promocional ou '
              'liquidacao para acelerar o giro e liberar capital parado em '
              'estoque.',
          quickAction: InsightAction(
            type: InsightActionType.suggestCampaign,
            label: 'Sugerir campanha/desconto',
            route:
                '/pricing/campaigns/new?productId=${snapshot.productId}'
                '${snapshot.variantId == null ? '' : '&variantId=${snapshot.variantId}'}'
                '&categoryId=${snapshot.categoryId}'
                '&suggestedReason=high_stock_low_turnover',
            productId: entityId,
            payload: <String, Object?>{
              'productId': snapshot.productId,
              'variantId': snapshot.variantId,
              'categoryId': snapshot.categoryId,
              'suggestedReason': 'high_stock_low_turnover',
            },
          ),
          organizationId: snapshot.organizationId,
          companyId: snapshot.companyId,
          recipientUserId: snapshot.recipientUserId,
          productId: entityId,
          generatedAt: context.asOf,
          expiresAt: expiresAt,
          status: InsightStatus.fresh,
        ),
      );
    }
    return insights;
  }

  InsightSeverity _severityFor(double coverageExcessRatio) {
    if (coverageExcessRatio >= 1.0) {
      return InsightSeverity.high;
    }
    if (coverageExcessRatio >= 0.5) {
      return InsightSeverity.medium;
    }
    return InsightSeverity.low;
  }
}
