import {
  type Insight,
  type InsightAction,
  type InsightContext,
  type InsightEvidence,
  type InsightOrganizationSettings,
  type InsightRule,
  type InsightSeverity,
} from './insight-engine';

interface SalesRepBelowTargetBand {
  label: string;
  severity: InsightSeverity;
}

/**
 * Guards the band comparisons below against floating-point drift from the
 * chained division/multiplication used to compute the under-achievement
 * ratio (e.g. a seller landing on an exact 90% projection must never be
 * missed just because `9000 / 10000 * 100` resolves to `89.99999999999999`).
 */
const THRESHOLD_EPSILON = 1e-9;

/**
 * Detects a sales representative whose pace, extrapolated linearly to the
 * end of the target's period (TASK-115, EPIC-15), would not reach the goal
 * cadastrado — surfaced only to that seller's sales manager/admin (never to
 * the seller themselves), so the manager can act before the period closes.
 *
 * This rule intentionally never re-fetches or re-derives "meta"/"realizado"
 * on its own: both numbers, and the relevant-day counts used to pace them,
 * come straight from `InsightSalesRepBelowTargetSnapshot` (TASK-133
 * aggregation layer).
 */
export class SalesRepBelowTargetInsightRule implements InsightRule {
  evaluate(context: InsightContext): Insight[] {
    const settings = context.dataset.settings;
    return context.dataset.salesRepBelowTargetSnapshots.flatMap(
      (snapshot) => {
        if (
          snapshot.organizationId !== context.organizationId ||
          snapshot.companyId !== context.companyId
        ) {
          return [];
        }

        if (snapshot.totalRelevantDays <= 0 || snapshot.targetValue <= 0) {
          return [];
        }

        if (
          snapshot.elapsedRelevantDays <
          settings.sellerBelowTargetMinimumElapsedDays
        ) {
          return [];
        }

        const currentDailyPace =
          snapshot.elapsedRelevantDays <= 0
            ? 0
            : snapshot.realizedValue / snapshot.elapsedRelevantDays;
        const projectedValue = currentDailyPace * snapshot.totalRelevantDays;
        const projectedAchievementPercentage =
          (projectedValue / snapshot.targetValue) * 100;
        const underAchievementRatio = clamp(
          1 - projectedAchievementPercentage / 100,
          0,
          1,
        );

        const band = bandFor(underAchievementRatio, settings);
        if (!band) {
          return [];
        }

        const remainingRelevantDays = Math.max(
          0,
          snapshot.totalRelevantDays - snapshot.elapsedRelevantDays,
        );
        const gap = snapshot.targetValue - snapshot.realizedValue;
        const requiredDailyPace =
          gap <= 0
            ? 0
            : remainingRelevantDays <= 0
              ? Infinity
              : gap / remainingRelevantDays;
        const shortfallAmount = clamp(
          snapshot.targetValue - projectedValue,
          0,
          snapshot.targetValue,
        );
        const expiresAt = new Date(
          context.asOf.getTime() + settings.lifetimeDays * 24 * 60 * 60 * 1000,
        );

        const evidence: InsightEvidence[] = [
          { code: 'period_label', label: 'Periodo', value: snapshot.periodLabel },
          {
            code: 'target_value',
            label: 'Meta do periodo',
            value: snapshot.targetValue.toFixed(2),
            numericValue: snapshot.targetValue,
            unit: 'BRL',
          },
          {
            code: 'realized_value',
            label: 'Realizado ate o momento',
            value: snapshot.realizedValue.toFixed(2),
            numericValue: snapshot.realizedValue,
            unit: 'BRL',
          },
          {
            code: 'elapsed_relevant_days',
            label: 'Dias decorridos no periodo',
            value: `${snapshot.elapsedRelevantDays}`,
            numericValue: snapshot.elapsedRelevantDays,
            unit: 'days',
          },
          {
            code: 'remaining_relevant_days',
            label: 'Dias restantes no periodo',
            value: `${remainingRelevantDays}`,
            numericValue: remainingRelevantDays,
            unit: 'days',
          },
          {
            code: 'current_daily_pace',
            label: 'Ritmo medio atual',
            value: currentDailyPace.toFixed(2),
            numericValue: currentDailyPace,
            unit: 'BRL/day',
          },
          {
            code: 'required_daily_pace',
            label: 'Ritmo necessario nos dias restantes',
            value: formatDailyPace(requiredDailyPace),
            numericValue: Number.isFinite(requiredDailyPace)
              ? requiredDailyPace
              : undefined,
            unit: 'BRL/day',
          },
          {
            code: 'projected_achievement_percentage',
            label: 'Percentual de atingimento projetado',
            value: projectedAchievementPercentage.toFixed(1),
            numericValue: projectedAchievementPercentage,
            unit: 'percent',
          },
          {
            code: 'seller_below_target_band',
            label: 'Faixa de risco',
            value: band.label,
          },
        ];

        const quickAction: InsightAction = {
          type: 'viewSellerDetail',
          label: 'Ver detalhe do vendedor',
          route: `/team/sellers/${snapshot.sellerId}`,
          sellerId: snapshot.sellerId,
          payload: {
            sellerId: snapshot.sellerId,
            periodStartDate: snapshot.periodStartDate.toISOString(),
            periodEndDate: snapshot.periodEndDate.toISOString(),
            targetValue: snapshot.targetValue,
            realizedValue: snapshot.realizedValue,
          },
        };

        const secondaryActions: InsightAction[] = [
          {
            type: 'viewOpportunities',
            label: 'Sugerir plano de acao',
            route: `/opportunities?sellerId=${snapshot.sellerId}`,
            sellerId: snapshot.sellerId,
            payload: {
              sellerId: snapshot.sellerId,
              suggestedReason: 'seller_below_target',
            },
          },
        ];

        return [
          {
            id: `seller_below_target:${snapshot.recipientUserId}:${snapshot.sellerId}`,
            type: 'sellerBelowTarget',
            title: `${band.label}: ${snapshot.sellerName}`,
            description:
              `${snapshot.sellerName} esta projetado a atingir ` +
              `${projectedAchievementPercentage.toFixed(0)}% da meta de ` +
              `${snapshot.periodLabel}, no ritmo atual de R$ ` +
              `${currentDailyPace.toFixed(2)}/dia contra os ` +
              `${formatDailyPace(requiredDailyPace)} necessarios nos ` +
              `${remainingRelevantDays} dia(s) uteis restantes.`,
            evidence,
            estimatedImpact: {
              amount: shortfallAmount,
              percentage: underAchievementRatio,
              currencyCode: 'BRL',
            },
            severity: band.severity,
            confidenceScore: 0.8,
            recommendation:
              'Reveja com o vendedor as contas prioritarias da carteira e ' +
              'monte um plano de acao para os dias restantes do periodo.',
            quickAction,
            secondaryActions,
            organizationId: snapshot.organizationId,
            companyId: snapshot.companyId,
            recipientUserId: snapshot.recipientUserId,
            sellerId: snapshot.sellerId,
            generatedAt: context.asOf,
            expiresAt,
            status: 'fresh',
          },
        ];
      },
    );
  }
}

function formatDailyPace(dailyPace: number): string {
  if (!Number.isFinite(dailyPace)) {
    return 'meta inalcancavel no periodo restante';
  }
  return `R$ ${dailyPace.toFixed(2)}/dia`;
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

function bandFor(
  underAchievementRatio: number,
  settings: InsightOrganizationSettings,
): SalesRepBelowTargetBand | null {
  if (
    underAchievementRatio + THRESHOLD_EPSILON >=
    settings.sellerBelowTargetCriticalThreshold
  ) {
    return { label: 'Risco critico de meta', severity: 'critical' };
  }
  if (
    underAchievementRatio + THRESHOLD_EPSILON >=
    settings.sellerBelowTargetHighThreshold
  ) {
    return { label: 'Risco alto de meta', severity: 'high' };
  }
  if (
    underAchievementRatio + THRESHOLD_EPSILON >=
    settings.sellerBelowTargetMediumThreshold
  ) {
    return { label: 'Risco moderado de meta', severity: 'medium' };
  }
  return null;
}
