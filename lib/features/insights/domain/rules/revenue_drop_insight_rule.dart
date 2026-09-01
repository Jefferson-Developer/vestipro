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

@lazySingleton
final class RevenueDropInsightRule implements InsightRule {
  const RevenueDropInsightRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    final insights = <Insight>[];
    final settings = context.dataset.settings;
    for (final snapshot in context.dataset.revenueComparisons) {
      if (snapshot.organizationId != context.organizationId ||
          snapshot.companyId != context.companyId ||
          snapshot.mode != settings.revenueComparisonMode ||
          !snapshot.isSeasonallyEquivalent) {
        continue;
      }
      if (snapshot.previousEquivalentRevenue <
          settings.revenueDropMinimumBaselineAmount) {
        continue;
      }
      final drop = snapshot.dropPercentage;
      if (drop < settings.revenueDropThreshold || snapshot.absoluteDrop <= 0) {
        continue;
      }

      final expiresAt = context.asOf.add(settings.defaultLifetime);
      insights.add(
        Insight(
          id: 'revenue_drop:${snapshot.recipientUserId}:${snapshot.customerId}:${snapshot.currentPeriodKey}',
          type: InsightType.revenueDrop,
          title: 'Queda de faturamento: ${snapshot.customerName}',
          description:
              '${snapshot.customerName} recuou ${(drop * 100).toStringAsFixed(1)}% no periodo ${snapshot.currentPeriodKey}.',
          evidence: <InsightEvidence>[
            InsightEvidence(
              code: 'current_period_revenue',
              label: 'Faturamento periodo atual',
              value: snapshot.currentPeriodRevenue.toStringAsFixed(2),
              numericValue: snapshot.currentPeriodRevenue,
              unit: 'BRL',
            ),
            InsightEvidence(
              code: 'previous_period_revenue',
              label: 'Faturamento periodo equivalente anterior',
              value: snapshot.previousEquivalentRevenue.toStringAsFixed(2),
              numericValue: snapshot.previousEquivalentRevenue,
              unit: 'BRL',
            ),
            InsightEvidence(
              code: 'revenue_drop_percentage',
              label: 'Percentual de queda',
              value: (drop * 100).toStringAsFixed(1),
              numericValue: drop * 100,
              unit: 'percent',
            ),
            if (snapshot.topCategoryName != null)
              InsightEvidence(
                code: 'top_category_drop',
                label: 'Categoria com maior retracao',
                value: snapshot.topCategoryName!,
                numericValue: snapshot.topCategoryRevenueDropAmount,
                unit: 'BRL',
              ),
          ],
          estimatedImpact: InsightEstimatedImpact(
            amount: snapshot.absoluteDrop,
            percentage: drop,
          ),
          severity: _severityFor(drop),
          confidenceScore: 0.88,
          recommendation:
              'Revise o historico recente do cliente e acione um follow-up comercial para recuperar o faturamento.',
          quickAction: InsightAction(
            type: InsightActionType.openCustomer,
            label: 'Abrir cliente',
            route: '/customers/${snapshot.customerId}',
            customerId: snapshot.customerId,
          ),
          secondaryActions: <InsightAction>[
            InsightAction(
              type: InsightActionType.scheduleContact,
              label: 'Agendar contato',
              customerId: snapshot.customerId,
              payload: <String, Object?>{
                'customerId': snapshot.customerId,
                'suggestedReason': 'revenue_drop',
              },
            ),
            InsightAction(
              type: InsightActionType.viewOrderHistory,
              label: 'Ver historico de pedidos',
              route: '/orders?customerId=${snapshot.customerId}',
              customerId: snapshot.customerId,
            ),
          ],
          organizationId: snapshot.organizationId,
          companyId: snapshot.companyId,
          recipientUserId: snapshot.recipientUserId,
          customerId: snapshot.customerId,
          generatedAt: context.asOf,
          expiresAt: expiresAt,
          status: InsightStatus.fresh,
        ),
      );
    }
    return insights;
  }

  InsightSeverity _severityFor(double drop) {
    if (drop >= 0.60) {
      return InsightSeverity.critical;
    }
    if (drop >= 0.45) {
      return InsightSeverity.high;
    }
    if (drop >= 0.30) {
      return InsightSeverity.medium;
    }
    return InsightSeverity.low;
  }
}
