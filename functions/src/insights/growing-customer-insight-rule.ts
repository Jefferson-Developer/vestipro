import {
  type Insight,
  type InsightContext,
  type InsightCustomerGrowthPeriod,
  type InsightRule,
  type InsightSeverity,
} from './insight-engine';

/**
 * Revenue used to compute the growth trend for a period: when the period
 * carries an atypical order, the outlier-adjusted revenue is used instead of
 * the raw revenue, so a single atypical order cannot manufacture a false
 * growth trend for the customer.
 */
function trendRevenue(period: InsightCustomerGrowthPeriod): number {
  return period.hasOutlierOrder
    ? (period.outlierAdjustedRevenue ?? period.revenue)
    : period.revenue;
}

/**
 * Returns the period-over-period growth rates for `periods` (using each
 * period's outlier-adjusted trend revenue) when every consecutive transition
 * is strictly positive, or `null` when growth is not consistent across the
 * whole window (e.g. a drop in an intermediate period, or a single atypical
 * order manufacturing an isolated spike).
 */
function consistentGrowthRates(
  periods: readonly InsightCustomerGrowthPeriod[],
): number[] | null {
  const rates: number[] = [];
  for (let i = 1; i < periods.length; i += 1) {
    const previous = trendRevenue(periods[i - 1]);
    const current = trendRevenue(periods[i]);
    if (previous <= 0) {
      return null;
    }
    const rate = (current - previous) / previous;
    if (rate <= 0) {
      return null;
    }
    rates.push(rate);
  }
  return rates;
}

/**
 * Identifies customers with a consistent, sustained revenue growth trend
 * across multiple consecutive periods, signalling an opportunity to deepen
 * the relationship and expand the assortment sold to that customer.
 */
export class GrowingCustomerInsightRule implements InsightRule {
  evaluate(context: InsightContext): Insight[] {
    const settings = context.dataset.settings;
    const minConsecutivePeriods = Math.max(
      1,
      settings.customerGrowthMinConsecutivePeriods,
    );

    return context.dataset.customerGrowthSnapshots.flatMap((snapshot) => {
      if (
        snapshot.organizationId !== context.organizationId ||
        snapshot.companyId !== context.companyId ||
        snapshot.periods.length < minConsecutivePeriods + 1
      ) {
        return [];
      }

      const recentPeriods = snapshot.periods.slice(
        snapshot.periods.length - (minConsecutivePeriods + 1),
      );

      const growthRates = consistentGrowthRates(recentPeriods);
      if (growthRates == null || growthRates.length < minConsecutivePeriods) {
        return [];
      }

      const averageRate =
        growthRates.reduce((sum, rate) => sum + rate, 0) / growthRates.length;
      if (averageRate < settings.customerGrowthMinimumAverageRate) {
        return [];
      }

      const lastPeriod = recentPeriods[recentPeriods.length - 1];
      // Simple linear extrapolation: projects the incremental revenue for
      // the next period if the observed average growth rate holds. This is
      // an estimate, never a guarantee, and is stated as such below.
      const projectedIncrementalRevenue = lastPeriod.revenue * averageRate;
      const expiresAt = new Date(
        context.asOf.getTime() + settings.lifetimeDays * 24 * 60 * 60 * 1000,
      );

      return [
        {
          id: `customer_growth:${snapshot.recipientUserId}:${snapshot.customerId}:${lastPeriod.periodKey}`,
          type: 'customerGrowth',
          title: `Cliente em crescimento: ${snapshot.customerName}`,
          description:
            `${snapshot.customerName} cresceu em media ` +
            `${(averageRate * 100).toFixed(1)}% ao periodo nos ultimos ` +
            `${growthRates.length} periodos consecutivos. Estimativa: se a ` +
            `tendencia se mantiver, o proximo periodo pode somar cerca de ` +
            `R$ ${projectedIncrementalRevenue.toFixed(2)} a mais (projecao ` +
            `simples, nao garantida).`,
          evidence: [
            ...recentPeriods.map((period) => ({
              code: `period_revenue:${period.periodKey}`,
              label: `Faturamento ${period.periodKey}`,
              value: period.revenue.toFixed(2),
              numericValue: period.revenue,
              unit: 'BRL',
            })),
            {
              code: 'average_growth_rate',
              label: 'Taxa media de crescimento',
              value: (averageRate * 100).toFixed(1),
              numericValue: averageRate * 100,
              unit: 'percent',
            },
            {
              code: 'projected_incremental_revenue',
              label: 'Projecao de faturamento incremental (estimativa)',
              value: projectedIncrementalRevenue.toFixed(2),
              numericValue: projectedIncrementalRevenue,
              unit: 'BRL',
            },
            ...(snapshot.topGrowingCategoryName == null
              ? []
              : [
                  {
                    code: 'top_growing_category',
                    label: 'Categoria que mais cresceu no intervalo',
                    value: snapshot.topGrowingCategoryName,
                    numericValue:
                      snapshot.topGrowingCategoryRevenueGrowthAmount ??
                      undefined,
                    unit: 'BRL',
                  },
                ]),
          ],
          estimatedImpact: {
            amount: projectedIncrementalRevenue,
            percentage: averageRate,
            currencyCode: 'BRL',
          },
          severity: severityFor(averageRate),
          confidenceScore: 0.75,
          recommendation:
            'Aproveite o momento de crescimento para ampliar o mix vendido ' +
            'e agendar uma visita de relacionamento com o cliente.',
          quickAction: {
            type: 'viewOpportunities',
            label: 'Sugerir ampliacao de mix',
            route: `/opportunities?customerId=${snapshot.customerId}`,
            customerId: snapshot.customerId,
            payload: {
              customerId: snapshot.customerId,
              suggestedReason: 'customer_growth',
            },
          },
          secondaryActions: [
            {
              type: 'scheduleContact',
              label: 'Agendar visita de relacionamento',
              customerId: snapshot.customerId,
              payload: {
                customerId: snapshot.customerId,
                suggestedReason: 'customer_growth_relationship_visit',
              },
            },
          ],
          organizationId: snapshot.organizationId,
          companyId: snapshot.companyId,
          recipientUserId: snapshot.recipientUserId,
          customerId: snapshot.customerId,
          generatedAt: context.asOf,
          expiresAt,
          status: 'fresh',
        },
      ];
    });
  }
}

function severityFor(averageRate: number): InsightSeverity {
  if (averageRate >= 0.45) {
    return 'high';
  }
  if (averageRate >= 0.25) {
    return 'medium';
  }
  return 'low';
}
