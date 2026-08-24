export const CUSTOMER_SCORING_FORMULA_VERSION = 'customer_score_v1_2026_08_24';

export type CustomerHealthScoreBand = 'healthy' | 'attention' | 'risk';
export type CustomerScoreDataCoverage =
  | 'ordersAndCrm'
  | 'crmOnly'
  | 'registrationOnly';

export interface CustomerScoringCustomer {
  id: string;
  organizationId: string;
  registeredAt: Date;
  lastPurchaseAt?: Date | null;
  potential?: string | null;
  status?: string | null;
}

export interface CustomerScoringActivitySignal {
  organizationId: string;
  customerId: string;
  occurredAt: Date;
}

export interface CustomerScoringInput {
  customer: CustomerScoringCustomer;
  now: Date;
  crmActivities?: CustomerScoringActivitySignal[];
  purchaseCountLast12Months?: number;
  revenueLast12Months?: number;
  currentPeriodRevenue?: number;
  previousPeriodRevenue?: number;
  overdueFollowUps?: number;
}

export interface CustomerScoringResult {
  commercialScore: number;
  healthScore: number;
  healthScoreBand: CustomerHealthScoreBand;
  scoreUpdatedAt: Date;
  scoreFormulaVersion: typeof CUSTOMER_SCORING_FORMULA_VERSION;
  scoreDataCoverage: CustomerScoreDataCoverage;
}

/**
 * Formula v1 (daily scheduled Function source of truth):
 *
 * Commercial score with order signals:
 * `40% purchase recency + 30% purchase frequency 12m + 30% revenue 12m`.
 * Revenue is normalized against BRL 50k until org-specific percentiles exist.
 *
 * Commercial score without order signals:
 * `50% CRM/registration recency + 25% CRM frequency 90d + 25% registration
 * freshness`, capped at 60 and tagged as degraded coverage so TASK-063 does
 * not treat it as strong buying evidence.
 *
 * Health score with order signals:
 * `45% purchase recency + 25% revenue trend + 20% CRM recency + 10% overdue
 * follow-up hygiene`.
 *
 * Health score without order signals:
 * `55% CRM/registration recency + 25% registration/status freshness + 20%
 * overdue follow-up hygiene`.
 *
 * Bands: healthy >= 75, attention 50..74, risk < 50.
 */
export function calculateCustomerScore(
  input: CustomerScoringInput,
): CustomerScoringResult {
  const activities = (input.crmActivities ?? []).filter(
    (activity) =>
      activity.organizationId === input.customer.organizationId &&
      activity.customerId === input.customer.id,
  );
  const hasOrderSignals = customerHasOrderSignals(input);
  const scoreDataCoverage = hasOrderSignals
    ? 'ordersAndCrm'
    : activities.length === 0
      ? 'registrationOnly'
      : 'crmOnly';
  const commercialScore = hasOrderSignals
    ? commercialScoreWithOrders(input, activities)
    : commercialScoreWithoutOrders(input, activities);
  const healthScore = hasOrderSignals
    ? healthScoreWithOrders(input, activities)
    : healthScoreWithoutOrders(input, activities);

  return {
    commercialScore,
    healthScore,
    healthScoreBand: classifyHealthScore(healthScore),
    scoreUpdatedAt: input.now,
    scoreFormulaVersion: CUSTOMER_SCORING_FORMULA_VERSION,
    scoreDataCoverage,
  };
}

export function classifyHealthScore(score: number): CustomerHealthScoreBand {
  const normalized = clamp(score, 0, 100);
  if (normalized >= 75) {
    return 'healthy';
  }
  if (normalized >= 50) {
    return 'attention';
  }
  return 'risk';
}

function customerHasOrderSignals(input: CustomerScoringInput): boolean {
  return (
    input.customer.lastPurchaseAt != null ||
    input.purchaseCountLast12Months != null ||
    input.revenueLast12Months != null ||
    input.currentPeriodRevenue != null ||
    input.previousPeriodRevenue != null
  );
}

function commercialScoreWithOrders(
  input: CustomerScoringInput,
  activities: CustomerScoringActivitySignal[],
): number {
  const purchaseRecency = purchaseRecencyScore(
    ageDays(input.customer.lastPurchaseAt ?? latestActivityAt(activities), input.now),
  );
  const frequency = purchaseFrequencyScore(
    input.purchaseCountLast12Months,
    input.customer.lastPurchaseAt,
  );
  const value = revenueScore(input.revenueLast12Months, input.customer.potential);
  return weightedScore([
    { score: purchaseRecency, weight: 0.40 },
    { score: frequency, weight: 0.30 },
    { score: value, weight: 0.30 },
  ]);
}

function commercialScoreWithoutOrders(
  input: CustomerScoringInput,
  activities: CustomerScoringActivitySignal[],
): number {
  const recency = crmRecencyScore(
    ageDays(latestActivityAt(activities) ?? input.customer.registeredAt, input.now),
    activities.length > 0,
  );
  const frequency = crmFrequencyScore(
    activityCountSince(
      activities,
      new Date(input.now.getTime() - 90 * 24 * 60 * 60 * 1000),
    ),
  );
  const freshness = registrationFreshnessScore(
    ageDays(input.customer.registeredAt, input.now),
    input.customer.status,
  );
  return Math.min(
    60,
    weightedScore([
      { score: recency, weight: 0.50 },
      { score: frequency, weight: 0.25 },
      { score: freshness, weight: 0.25 },
    ]),
  );
}

function healthScoreWithOrders(
  input: CustomerScoringInput,
  activities: CustomerScoringActivitySignal[],
): number {
  const purchaseRecency = purchaseRecencyScore(
    ageDays(input.customer.lastPurchaseAt ?? latestActivityAt(activities), input.now),
  );
  const trend = revenueTrendScore(
    input.currentPeriodRevenue,
    input.previousPeriodRevenue,
  );
  const crmRecency = crmRecencyScore(
    ageDays(latestActivityAt(activities) ?? input.customer.registeredAt, input.now),
    activities.length > 0,
  );
  const followUps = followUpHygieneScore(input.overdueFollowUps ?? 0);
  return weightedScore([
    { score: purchaseRecency, weight: 0.45 },
    { score: trend, weight: 0.25 },
    { score: crmRecency, weight: 0.20 },
    { score: followUps, weight: 0.10 },
  ]);
}

function healthScoreWithoutOrders(
  input: CustomerScoringInput,
  activities: CustomerScoringActivitySignal[],
): number {
  const recency = crmRecencyScore(
    ageDays(latestActivityAt(activities) ?? input.customer.registeredAt, input.now),
    activities.length > 0,
  );
  const freshness = registrationFreshnessScore(
    ageDays(input.customer.registeredAt, input.now),
    input.customer.status,
  );
  const followUps = followUpHygieneScore(input.overdueFollowUps ?? 0);
  return weightedScore([
    { score: recency, weight: 0.55 },
    { score: freshness, weight: 0.25 },
    { score: followUps, weight: 0.20 },
  ]);
}

function ageDays(date: Date | null | undefined, now: Date): number | undefined {
  if (!date) {
    return undefined;
  }
  return Math.floor((now.getTime() - date.getTime()) / (24 * 60 * 60 * 1000));
}

function latestActivityAt(
  activities: CustomerScoringActivitySignal[],
): Date | undefined {
  let latest: Date | undefined;
  activities.forEach((activity) => {
    if (!latest || activity.occurredAt > latest) {
      latest = activity.occurredAt;
    }
  });
  return latest;
}

function activityCountSince(
  activities: CustomerScoringActivitySignal[],
  threshold: Date,
): number {
  return activities.filter((activity) => activity.occurredAt >= threshold).length;
}

function purchaseRecencyScore(days: number | undefined): number {
  if (days == null) {
    return 15;
  }
  if (days <= 30) {
    return 100;
  }
  if (days <= 90) {
    return 80;
  }
  if (days <= 180) {
    return 55;
  }
  if (days <= 365) {
    return 30;
  }
  return 15;
}

function crmRecencyScore(
  days: number | undefined,
  hasActualCrmActivity: boolean,
): number {
  if (days == null) {
    return 10;
  }
  if (!hasActualCrmActivity) {
    return Math.min(55, registrationFreshnessScore(days, 'active'));
  }
  if (days <= 7) {
    return 100;
  }
  if (days <= 30) {
    return 80;
  }
  if (days <= 60) {
    return 60;
  }
  if (days <= 90) {
    return 45;
  }
  if (days <= 180) {
    return 25;
  }
  return 10;
}

function registrationFreshnessScore(
  days: number | undefined,
  status: string | null | undefined,
): number {
  const statusPenalty = status === 'blocked' || status === 'inactive' ? 20 : 0;
  const base =
    days == null
      ? 15
      : days <= 30
        ? 70
        : days <= 90
          ? 55
          : days <= 180
            ? 35
            : 15;
  return clamp(base - statusPenalty, 0, 100);
}

function crmFrequencyScore(count: number): number {
  if (count <= 0) {
    return 10;
  }
  if (count === 1) {
    return 45;
  }
  if (count <= 3) {
    return 65;
  }
  return 85;
}

function purchaseFrequencyScore(
  count: number | undefined,
  lastPurchaseAt: Date | null | undefined,
): number {
  if (count == null) {
    return lastPurchaseAt == null ? 0 : 35;
  }
  if (count <= 0) {
    return 0;
  }
  return (clamp(count, 0, 6) / 6) * 100;
}

function revenueScore(
  revenue: number | undefined,
  fallbackPotential: string | null | undefined,
): number {
  if (revenue != null) {
    if (revenue <= 0) {
      return 0;
    }
    return clamp((revenue / 50000) * 100, 0, 100);
  }
  const potential = fallbackPotential?.trim().toLowerCase();
  switch (potential) {
    case 'alto':
    case 'high':
    case 'a':
    case 'tier-a':
      return 70;
    case 'medio':
    case 'medium':
    case 'b':
    case 'tier-b':
      return 50;
    case 'baixo':
    case 'low':
    case 'c':
    case 'tier-c':
      return 30;
    default:
      return 25;
  }
}

function revenueTrendScore(
  current: number | undefined,
  previous: number | undefined,
): number {
  if (current == null || previous == null || previous <= 0) {
    return 50;
  }
  const dropRatio = (previous - current) / previous;
  if (dropRatio <= 0) {
    return 100;
  }
  if (dropRatio <= 0.20) {
    return 70;
  }
  if (dropRatio <= 0.50) {
    return 40;
  }
  return 15;
}

function followUpHygieneScore(overdueFollowUps: number): number {
  if (overdueFollowUps <= 0) {
    return 100;
  }
  if (overdueFollowUps === 1) {
    return 70;
  }
  if (overdueFollowUps === 2) {
    return 45;
  }
  return 10;
}

function weightedScore(
  scores: Array<{ readonly score: number; readonly weight: number }>,
): number {
  const total = scores.reduce(
    (sum, item) => sum + clamp(item.score, 0, 100) * item.weight,
    0,
  );
  return Math.round(clamp(total, 0, 100));
}

function clamp(value: number, lower: number, upper: number): number {
  return Math.min(upper, Math.max(lower, value));
}
