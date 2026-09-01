import {
  type Insight,
  type InsightContext,
  type InsightRule,
  type InsightSeverity,
} from './insight-engine';

export class RevenueDropInsightRule implements InsightRule {
  evaluate(context: InsightContext): Insight[] {
    const settings = context.dataset.settings;
    return context.dataset.revenueComparisons.flatMap((snapshot) => {
      const seasonsComparable =
        !snapshot.currentSeasonCode ||
        !snapshot.previousSeasonCode ||
        snapshot.currentSeasonCode === snapshot.previousSeasonCode;
      if (
        snapshot.organizationId !== context.organizationId ||
        snapshot.companyId !== context.companyId ||
        snapshot.mode !== settings.revenueComparisonMode ||
        !seasonsComparable ||
        snapshot.previousEquivalentRevenue <
          settings.revenueDropMinimumBaselineAmount
      ) {
        return [];
      }

      const absoluteDrop =
        snapshot.previousEquivalentRevenue - snapshot.currentPeriodRevenue;
      if (absoluteDrop <= 0) {
        return [];
      }
      const dropPercentage =
        absoluteDrop / snapshot.previousEquivalentRevenue;
      if (dropPercentage < settings.revenueDropThreshold) {
        return [];
      }

      const expiresAt = new Date(
        context.asOf.getTime() + settings.lifetimeDays * 24 * 60 * 60 * 1000,
      );

      return [
        {
          id: `revenue_drop:${snapshot.recipientUserId}:${snapshot.customerId}:${snapshot.currentPeriodKey}`,
          type: 'revenueDrop',
          title: `Queda de faturamento: ${snapshot.customerName}`,
          description: `${snapshot.customerName} recuou ${(dropPercentage * 100).toFixed(1)}% no periodo ${snapshot.currentPeriodKey}.`,
          evidence: [
            {
              code: 'current_period_revenue',
              label: 'Faturamento periodo atual',
              value: snapshot.currentPeriodRevenue.toFixed(2),
              numericValue: snapshot.currentPeriodRevenue,
              unit: 'BRL',
            },
            {
              code: 'previous_period_revenue',
              label: 'Faturamento periodo equivalente anterior',
              value: snapshot.previousEquivalentRevenue.toFixed(2),
              numericValue: snapshot.previousEquivalentRevenue,
              unit: 'BRL',
            },
            {
              code: 'revenue_drop_percentage',
              label: 'Percentual de queda',
              value: (dropPercentage * 100).toFixed(1),
              numericValue: dropPercentage * 100,
              unit: 'percent',
            },
            ...(snapshot.topCategoryName == null
              ? []
              : [
                  {
                    code: 'top_category_drop',
                    label: 'Categoria com maior retracao',
                    value: snapshot.topCategoryName,
                    numericValue:
                      snapshot.topCategoryRevenueDropAmount ?? undefined,
                    unit: 'BRL',
                  },
                ]),
          ],
          estimatedImpact: {
            amount: absoluteDrop,
            percentage: dropPercentage,
            currencyCode: 'BRL',
          },
          severity: severityFor(dropPercentage),
          confidenceScore: 0.88,
          recommendation:
            'Revise o historico recente do cliente e acione um follow-up comercial para recuperar o faturamento.',
          quickAction: {
            type: 'openCustomer',
            label: 'Abrir cliente',
            route: `/customers/${snapshot.customerId}`,
            customerId: snapshot.customerId,
          },
          secondaryActions: [
            {
              type: 'scheduleContact',
              label: 'Agendar contato',
              customerId: snapshot.customerId,
              payload: {
                customerId: snapshot.customerId,
                suggestedReason: 'revenue_drop',
              },
            },
            {
              type: 'viewOrderHistory',
              label: 'Ver historico de pedidos',
              route: `/orders?customerId=${snapshot.customerId}`,
              customerId: snapshot.customerId,
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

function severityFor(dropPercentage: number): InsightSeverity {
  if (dropPercentage >= 0.6) {
    return 'critical';
  }
  if (dropPercentage >= 0.45) {
    return 'high';
  }
  if (dropPercentage >= 0.3) {
    return 'medium';
  }
  return 'low';
}
