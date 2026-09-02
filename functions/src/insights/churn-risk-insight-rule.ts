import {
  type Insight,
  type InsightContext,
  type InsightEvidence,
  type InsightOrganizationSettings,
  type InsightRule,
  type InsightSeverity,
} from './insight-engine';

interface ChurnRiskBand {
  label: string;
  severity: InsightSeverity;
}

/**
 * Combines three independent churn signals — decline in purchase frequency,
 * decline in revenue, and the customer health score (TASK-062) — into a
 * single, explainable churn-risk score, prioritized for display by the
 * customer's financial impact rather than by the risk score alone.
 */
export class ChurnRiskInsightRule implements InsightRule {
  evaluate(context: InsightContext): Insight[] {
    const settings = context.dataset.settings;
    return context.dataset.churnRiskSnapshots.flatMap((snapshot) => {
      if (
        snapshot.organizationId !== context.organizationId ||
        snapshot.companyId !== context.companyId
      ) {
        return [];
      }

      // Customers with too little purchase history do not yield a reliable
      // churn-risk signal (e.g. a brand-new customer naturally has low
      // frequency) — skip rather than raise a false positive.
      if (snapshot.historicalOrderCount < settings.churnRiskMinimumHistoricalOrders) {
        return [];
      }

      const frequencySignal = declineRatio(
        snapshot.recentPurchaseFrequency,
        snapshot.historicalPurchaseFrequency,
      );
      const valueSignal = declineRatio(
        snapshot.recentRevenue,
        snapshot.historicalRevenue,
      );
      const healthSignal = healthScoreRiskRatio(snapshot.healthScore);
      const riskScore = composeRiskScore(settings, {
        frequencySignal,
        valueSignal,
        healthSignal,
      });

      const band = bandFor(riskScore, settings);
      if (!band) {
        // "Baixo" risk: nothing actionable yet, avoid alert noise.
        return [];
      }

      const financialImpactBase =
        snapshot.historicalRevenue > 0
          ? snapshot.historicalRevenue
          : (snapshot.averageTicket ?? 0);
      const financialImpact = financialImpactBase * riskScore;
      const expiresAt = new Date(
        context.asOf.getTime() + settings.lifetimeDays * 24 * 60 * 60 * 1000,
      );

      const evidence: InsightEvidence[] = [
        {
          code: 'frequency_decline_ratio',
          label: 'Queda de frequencia de compra',
          value: (frequencySignal * 100).toFixed(1),
          numericValue: frequencySignal * 100,
          unit: 'percent',
        },
        {
          code: 'frequency_signal_weight',
          label: 'Peso do sinal de frequencia',
          value: (settings.churnRiskFrequencyWeight * 100).toFixed(0),
          numericValue: settings.churnRiskFrequencyWeight * 100,
          unit: 'percent',
        },
        {
          code: 'value_decline_ratio',
          label: 'Queda de faturamento',
          value: (valueSignal * 100).toFixed(1),
          numericValue: valueSignal * 100,
          unit: 'percent',
        },
        {
          code: 'value_signal_weight',
          label: 'Peso do sinal de faturamento',
          value: (settings.churnRiskValueWeight * 100).toFixed(0),
          numericValue: settings.churnRiskValueWeight * 100,
          unit: 'percent',
        },
        {
          code: 'health_score',
          label: 'Health score do cliente',
          value: `${snapshot.healthScore}`,
          numericValue: snapshot.healthScore,
          unit: 'score',
        },
        {
          code: 'health_score_signal_weight',
          label: 'Peso do sinal de health score',
          value: (settings.churnRiskHealthScoreWeight * 100).toFixed(0),
          numericValue: settings.churnRiskHealthScoreWeight * 100,
          unit: 'percent',
        },
        {
          code: 'churn_risk_score',
          label: 'Score de risco de churn',
          value: (riskScore * 100).toFixed(1),
          numericValue: riskScore * 100,
          unit: 'percent',
        },
        {
          code: 'churn_risk_band',
          label: 'Faixa de risco',
          value: band.label,
        },
      ];

      return [
        {
          id: `churn_risk:${snapshot.recipientUserId}:${snapshot.customerId}`,
          type: 'churnRisk',
          title: `Risco de churn: ${snapshot.customerName}`,
          description:
            `${snapshot.customerName} apresenta risco de churn ${band.label.toLowerCase()} ` +
            `(score ${(riskScore * 100).toFixed(0)}/100), combinando queda de frequencia de ` +
            'compra, queda de faturamento e health score do cliente.',
          evidence,
          estimatedImpact: {
            amount: financialImpact,
            percentage: riskScore,
            currencyCode: 'BRL',
          },
          severity: band.severity,
          confidenceScore: 0.8,
          recommendation:
            'Priorize um contato comercial com o cliente e revise o historico de pedidos ' +
            'para entender a causa da queda antes que o relacionamento se perca.',
          quickAction: {
            type: 'scheduleContact',
            label: 'Agendar contato prioritario',
            customerId: snapshot.customerId,
            payload: {
              customerId: snapshot.customerId,
              suggestedReason: 'churn_risk',
            },
          },
          secondaryActions: [
            {
              type: 'openCustomer',
              label: 'Abrir cliente 360',
              route: `/customers/${snapshot.customerId}`,
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

function declineRatio(recent: number, historical: number): number {
  if (historical <= 0) {
    return 0;
  }
  const ratio = (historical - recent) / historical;
  return Math.min(1, Math.max(0, ratio));
}

function healthScoreRiskRatio(healthScore: number): number {
  const normalized = Math.min(100, Math.max(0, healthScore));
  return (100 - normalized) / 100;
}

function composeRiskScore(
  settings: InsightOrganizationSettings,
  signals: {
    frequencySignal: number;
    valueSignal: number;
    healthSignal: number;
  },
): number {
  const totalWeight =
    settings.churnRiskFrequencyWeight +
    settings.churnRiskValueWeight +
    settings.churnRiskHealthScoreWeight;
  if (totalWeight <= 0) {
    return 0;
  }
  const weighted =
    signals.frequencySignal * settings.churnRiskFrequencyWeight +
    signals.valueSignal * settings.churnRiskValueWeight +
    signals.healthSignal * settings.churnRiskHealthScoreWeight;
  return Math.min(1, Math.max(0, weighted / totalWeight));
}

function bandFor(
  score: number,
  settings: InsightOrganizationSettings,
): ChurnRiskBand | null {
  if (score >= settings.churnRiskCriticalThreshold) {
    return { label: 'Critico', severity: 'critical' };
  }
  if (score >= settings.churnRiskHighThreshold) {
    return { label: 'Alto', severity: 'high' };
  }
  if (score >= settings.churnRiskMediumThreshold) {
    return { label: 'Medio', severity: 'medium' };
  }
  return null;
}
