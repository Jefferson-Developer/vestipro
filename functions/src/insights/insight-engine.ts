export type InsightType = 'inactiveCustomer' | 'revenueDrop';
export type InsightStatus =
  | 'fresh'
  | 'viewed'
  | 'inProgress'
  | 'dismissed'
  | 'resolved';
export type InsightSeverity = 'low' | 'medium' | 'high' | 'critical';
export type InsightActionType =
  | 'openCustomer'
  | 'startOrder'
  | 'scheduleContact'
  | 'viewCategory'
  | 'viewOrderHistory';
export type InsightRevenueComparisonMode =
  | 'monthOverMonth'
  | 'yearOverYear';

export interface InsightEvidence {
  code: string;
  label: string;
  value: string;
  numericValue?: number;
  unit?: string;
}

export interface InsightEstimatedImpact {
  amount?: number;
  percentage?: number;
  currencyCode?: string;
}

export interface InsightAction {
  type: InsightActionType;
  label: string;
  route?: string;
  customerId?: string;
  productId?: string;
  sellerId?: string;
  payload?: Record<string, unknown>;
}

export interface Insight {
  id: string;
  type: InsightType;
  title: string;
  description: string;
  evidence: InsightEvidence[];
  estimatedImpact: InsightEstimatedImpact;
  severity: InsightSeverity;
  confidenceScore: number;
  recommendation: string;
  quickAction: InsightAction;
  secondaryActions: InsightAction[];
  organizationId: string;
  companyId: string;
  recipientUserId: string;
  customerId?: string;
  productId?: string;
  sellerId?: string;
  generatedAt: Date;
  expiresAt: Date;
  status: InsightStatus;
}

export interface InsightCustomerSnapshot {
  customerId: string;
  organizationId: string;
  companyId: string;
  recipientUserId: string;
  customerName: string;
  customerStatus: string;
  segment?: string | null;
  lastOrderAt?: Date | null;
  lastOrderValue?: number | null;
  averageTicket?: number | null;
  responsibleSellerId?: string | null;
}

export interface InsightRevenueComparisonSnapshot {
  customerId: string;
  organizationId: string;
  companyId: string;
  recipientUserId: string;
  customerName: string;
  mode: InsightRevenueComparisonMode;
  currentPeriodRevenue: number;
  previousEquivalentRevenue: number;
  currentPeriodKey: string;
  previousPeriodKey: string;
  currentSeasonCode?: string | null;
  previousSeasonCode?: string | null;
  topCategoryId?: string | null;
  topCategoryName?: string | null;
  topCategoryRevenueDropAmount?: number | null;
}

export interface InsightOrganizationSettings {
  inactivityThresholdDays: number;
  inactivityThresholdDaysBySegment: Record<string, number>;
  revenueDropThreshold: number;
  revenueDropMinimumBaselineAmount: number;
  revenueComparisonMode: InsightRevenueComparisonMode;
  lifetimeDays: number;
}

export interface InsightDataset {
  settings: InsightOrganizationSettings;
  customerSnapshots: InsightCustomerSnapshot[];
  revenueComparisons: InsightRevenueComparisonSnapshot[];
}

export interface InsightContext {
  organizationId: string;
  companyId: string;
  asOf: Date;
  dataset: InsightDataset;
}

export interface InsightRule {
  evaluate(context: InsightContext): Insight[];
}

export const DEFAULT_INSIGHT_SETTINGS: InsightOrganizationSettings = {
  inactivityThresholdDays: 45,
  inactivityThresholdDaysBySegment: {},
  revenueDropThreshold: 0.3,
  revenueDropMinimumBaselineAmount: 1000,
  revenueComparisonMode: 'yearOverYear',
  lifetimeDays: 7,
};

export function evaluateInsights(
  context: InsightContext,
  rules: readonly InsightRule[],
): Insight[] {
  const all = rules.flatMap((rule) => rule.evaluate(context));
  all.forEach(assertValidInsight);
  const deduped = new Map<string, Insight>();
  all.forEach((insight) => {
    const key = deduplicationKey(insight);
    const current = deduped.get(key);
    if (!current || impactScore(insight) >= impactScore(current)) {
      deduped.set(key, insight);
    }
  });
  return [...deduped.values()].sort((left, right) => {
    const byImpact = impactScore(right) - impactScore(left);
    if (byImpact !== 0) {
      return byImpact;
    }
    return right.generatedAt.getTime() - left.generatedAt.getTime();
  });
}

export function assertValidInsight(insight: Insight): void {
  if (insight.evidence.length === 0) {
    throw new Error('insight_missing_evidence');
  }
  if (
    insight.estimatedImpact.amount == null &&
    insight.estimatedImpact.percentage == null
  ) {
    throw new Error('insight_missing_estimated_impact');
  }
  if (insight.recommendation.trim().length === 0) {
    throw new Error('insight_missing_recommendation');
  }
}

export function deduplicationKey(insight: Insight): string {
  return `${insight.type}:${insight.customerId ?? insight.productId ?? insight.sellerId ?? 'global'}`;
}

function impactScore(insight: Insight): number {
  return (
    (insight.estimatedImpact.amount ?? 0) +
    (insight.estimatedImpact.percentage ?? 0) * 1000
  );
}
