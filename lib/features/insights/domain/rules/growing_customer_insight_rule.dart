import 'package:injectable/injectable.dart';

import '../entities/insight.dart';
import '../entities/insight_action.dart';
import '../entities/insight_context.dart';
import '../entities/insight_customer_growth_period.dart';
import '../entities/insight_estimated_impact.dart';
import '../entities/insight_evidence.dart';
import '../services/insight_rule.dart';
import '../value_objects/insight_action_type.dart';
import '../value_objects/insight_severity.dart';
import '../value_objects/insight_status.dart';
import '../value_objects/insight_type.dart';

/// Identifies customers with a consistent, sustained revenue growth trend
/// across multiple consecutive periods, signalling an opportunity to deepen
/// the relationship and expand the assortment sold to that customer.
@lazySingleton
final class GrowingCustomerInsightRule implements InsightRule {
  const GrowingCustomerInsightRule();

  @override
  List<Insight> evaluate(InsightContext context) {
    final insights = <Insight>[];
    final settings = context.dataset.settings;
    final minConsecutivePeriods =
        settings.customerGrowthMinConsecutivePeriods < 1
        ? 1
        : settings.customerGrowthMinConsecutivePeriods;

    for (final snapshot in context.dataset.customerGrowthSnapshots) {
      if (snapshot.organizationId != context.organizationId ||
          snapshot.companyId != context.companyId) {
        continue;
      }
      if (snapshot.periods.length < minConsecutivePeriods + 1) {
        continue;
      }

      final recentPeriods = snapshot.periods.sublist(
        snapshot.periods.length - (minConsecutivePeriods + 1),
      );

      final growthRates = _consistentGrowthRates(recentPeriods);
      if (growthRates == null || growthRates.length < minConsecutivePeriods) {
        continue;
      }

      final averageRate =
          growthRates.reduce((a, b) => a + b) / growthRates.length;
      if (averageRate < settings.customerGrowthMinimumAverageRate) {
        continue;
      }

      final lastPeriod = recentPeriods.last;
      // Simple linear extrapolation: projects the incremental revenue for
      // the next period if the observed average growth rate holds. This is
      // an estimate, never a guarantee, and is stated as such below.
      final projectedIncrementalRevenue = lastPeriod.revenue * averageRate;
      final expiresAt = context.asOf.add(settings.defaultLifetime);

      insights.add(
        Insight(
          id: 'customer_growth:${snapshot.recipientUserId}:${snapshot.customerId}:${lastPeriod.periodKey}',
          type: InsightType.customerGrowth,
          title: 'Cliente em crescimento: ${snapshot.customerName}',
          description:
              '${snapshot.customerName} cresceu em media '
              '${(averageRate * 100).toStringAsFixed(1)}% ao periodo nos '
              'ultimos ${growthRates.length} periodos consecutivos. '
              'Estimativa: se a tendencia se mantiver, o proximo periodo '
              'pode somar cerca de R\$ '
              '${projectedIncrementalRevenue.toStringAsFixed(2)} a mais '
              '(projecao simples, nao garantida).',
          evidence: <InsightEvidence>[
            for (final period in recentPeriods)
              InsightEvidence(
                code: 'period_revenue:${period.periodKey}',
                label: 'Faturamento ${period.periodKey}',
                value: period.revenue.toStringAsFixed(2),
                numericValue: period.revenue,
                unit: 'BRL',
              ),
            InsightEvidence(
              code: 'average_growth_rate',
              label: 'Taxa media de crescimento',
              value: (averageRate * 100).toStringAsFixed(1),
              numericValue: averageRate * 100,
              unit: 'percent',
            ),
            InsightEvidence(
              code: 'projected_incremental_revenue',
              label: 'Projecao de faturamento incremental (estimativa)',
              value: projectedIncrementalRevenue.toStringAsFixed(2),
              numericValue: projectedIncrementalRevenue,
              unit: 'BRL',
            ),
            if (snapshot.topGrowingCategoryName != null)
              InsightEvidence(
                code: 'top_growing_category',
                label: 'Categoria que mais cresceu no intervalo',
                value: snapshot.topGrowingCategoryName!,
                numericValue: snapshot.topGrowingCategoryRevenueGrowthAmount,
                unit: 'BRL',
              ),
          ],
          estimatedImpact: InsightEstimatedImpact(
            amount: projectedIncrementalRevenue,
            percentage: averageRate,
          ),
          severity: _severityFor(averageRate),
          confidenceScore: 0.75,
          recommendation:
              'Aproveite o momento de crescimento para ampliar o mix vendido '
              'e agendar uma visita de relacionamento com o cliente.',
          quickAction: InsightAction(
            type: InsightActionType.viewOpportunities,
            label: 'Sugerir ampliacao de mix',
            route: '/opportunities?customerId=${snapshot.customerId}',
            customerId: snapshot.customerId,
            payload: <String, Object?>{
              'customerId': snapshot.customerId,
              'suggestedReason': 'customer_growth',
            },
          ),
          secondaryActions: <InsightAction>[
            InsightAction(
              type: InsightActionType.scheduleContact,
              label: 'Agendar visita de relacionamento',
              customerId: snapshot.customerId,
              payload: <String, Object?>{
                'customerId': snapshot.customerId,
                'suggestedReason': 'customer_growth_relationship_visit',
              },
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

  /// Returns the period-over-period growth rates for [periods] (using each
  /// period's outlier-adjusted trend revenue) when every consecutive
  /// transition is strictly positive, or `null` when growth is not
  /// consistent across the whole window (e.g. a drop in an intermediate
  /// period, or a single atypical order manufacturing an isolated spike).
  List<double>? _consistentGrowthRates(
    List<InsightCustomerGrowthPeriod> periods,
  ) {
    final rates = <double>[];
    for (var i = 1; i < periods.length; i++) {
      final previous = periods[i - 1].trendRevenue;
      final current = periods[i].trendRevenue;
      if (previous <= 0) {
        return null;
      }
      final rate = (current - previous) / previous;
      if (rate <= 0) {
        return null;
      }
      rates.add(rate);
    }
    return rates;
  }

  InsightSeverity _severityFor(double averageRate) {
    if (averageRate >= 0.45) {
      return InsightSeverity.high;
    }
    if (averageRate >= 0.25) {
      return InsightSeverity.medium;
    }
    return InsightSeverity.low;
  }
}
