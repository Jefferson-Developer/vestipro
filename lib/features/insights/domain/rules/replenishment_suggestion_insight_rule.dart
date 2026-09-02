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

/// Identifies products/variants with a high turnover index (TASK-094)
/// whose stock coverage has dropped below the organization/category
/// configured minimum, signaling a risk of rupture — surfaced early enough
/// for the purchasing/replenishment team to act, cross-referencing the
/// low-stock alerts already raised by TASK-093.
///
/// This is the mirror-opposite signal of
/// [HighStockLowTurnoverInsightRule]: by construction (low coverage + high
/// turnover here, versus high coverage + low turnover there), the two rules
/// can never both fire for the same product/variant in the same cycle, as
/// long as the organization's thresholds are configured consistently.
///
/// This rule never generates a purchase order automatically — it only
/// raises an insight/notification for the responsible team; automating the
/// actual replenishment is out of scope (EPIC-27). Discontinued/out of
/// current-collection products are always excluded: restocking them would
/// never be the right call.
@lazySingleton
final class ReplenishmentSuggestionInsightRule implements InsightRule {
  const ReplenishmentSuggestionInsightRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    final insights = <Insight>[];
    final settings = context.dataset.settings;
    final expiresAt = context.asOf.add(settings.defaultLifetime);

    for (final snapshot in context.dataset.stockPositionSnapshots) {
      if (snapshot.organizationId != context.organizationId ||
          snapshot.companyId != context.companyId ||
          snapshot.isDiscontinued) {
        continue;
      }

      final coverageThreshold = settings
          .resolveReplenishmentLowCoverageDaysThreshold(snapshot.categoryId);
      final turnoverThreshold = settings
          .resolveReplenishmentHighTurnoverIndexThreshold(snapshot.categoryId);
      if (snapshot.coverageDays > coverageThreshold ||
          snapshot.turnoverIndex < turnoverThreshold) {
        continue;
      }

      final entityId = snapshot.variantId ?? snapshot.productId;
      final displayName = snapshot.variantLabel == null
          ? snapshot.productName
          : '${snapshot.productName} (${snapshot.variantLabel})';
      final coverageDeficitRatio = coverageThreshold <= 0
          ? 1.0
          : (coverageThreshold - snapshot.coverageDays) / coverageThreshold;

      insights.add(
        Insight(
          id:
              'replenishment_suggestion:${snapshot.recipientUserId}:'
              '$entityId',
          type: InsightType.replenishmentSuggestion,
          title: 'Risco de ruptura, sugestao de reposicao: $displayName',
          description:
              '$displayName tem indice de giro de '
              '${snapshot.turnoverIndex.toStringAsFixed(2)} — acima do '
              'minimo de ${turnoverThreshold.toStringAsFixed(2)} esperado '
              'para a categoria ${snapshot.categoryName} — mas cobertura '
              'atual de apenas ${snapshot.coverageDays.toStringAsFixed(0)} '
              'dia(s), abaixo do limiar de '
              '${coverageThreshold.toStringAsFixed(0)} dia(s). Ponto de '
              'ressuprimento sugerido: '
              '${snapshot.suggestedReorderPointQuantity.toStringAsFixed(0)} '
              'unidade(s).',
          evidence: <InsightEvidence>[
            InsightEvidence(
              code: 'replenishment_turnover_index',
              label: 'Indice de giro',
              value: snapshot.turnoverIndex.toStringAsFixed(2),
              numericValue: snapshot.turnoverIndex,
            ),
            InsightEvidence(
              code: 'replenishment_coverage_days',
              label: 'Cobertura atual em dias',
              value: snapshot.coverageDays.toStringAsFixed(1),
              numericValue: snapshot.coverageDays,
              unit: 'dias',
            ),
            InsightEvidence(
              code: 'replenishment_suggested_reorder_point',
              label: 'Ponto de ressuprimento sugerido',
              value: snapshot.suggestedReorderPointQuantity.toStringAsFixed(0),
              numericValue: snapshot.suggestedReorderPointQuantity,
              unit: 'unidades',
            ),
            InsightEvidence(
              code: 'replenishment_average_daily_consumption',
              label: 'Consumo medio diario recente',
              value: snapshot.averageDailyConsumption.toStringAsFixed(2),
              numericValue: snapshot.averageDailyConsumption,
              unit: 'unidades/dia',
            ),
          ],
          estimatedImpact: InsightEstimatedImpact(
            percentage: coverageDeficitRatio.clamp(0, 1).toDouble(),
          ),
          severity: _severityFor(coverageDeficitRatio),
          confidenceScore: 0.65,
          recommendation:
              'Notifique o time de compras/reposicao para avaliar um novo '
              'pedido antes que o estoque se esgote.',
          quickAction: InsightAction(
            type: InsightActionType.notifyReplenishment,
            label: 'Notificar compras/reposicao',
            route:
                '/inventory/replenishment?productId=${snapshot.productId}'
                '${snapshot.variantId == null ? '' : '&variantId=${snapshot.variantId}'}'
                '&suggestedReason=replenishment_suggestion',
            productId: entityId,
            payload: <String, Object?>{
              'productId': snapshot.productId,
              'variantId': snapshot.variantId,
              'categoryId': snapshot.categoryId,
              'suggestedReorderPointQuantity':
                  snapshot.suggestedReorderPointQuantity,
              'suggestedReason': 'replenishment_suggestion',
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

  InsightSeverity _severityFor(double coverageDeficitRatio) {
    if (coverageDeficitRatio >= 0.7) {
      return InsightSeverity.high;
    }
    if (coverageDeficitRatio >= 0.3) {
      return InsightSeverity.medium;
    }
    return InsightSeverity.low;
  }
}
