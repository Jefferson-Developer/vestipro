export type InsightType =
  | 'inactiveCustomer'
  | 'revenueDrop'
  | 'customerGrowth'
  | 'crossSell'
  | 'upSell'
  | 'insufficientMix'
  | 'highStockLowTurnover'
  | 'replenishmentSuggestion'
  | 'churnRisk'
  | 'abandonedOrder'
  | 'sellerBelowTarget';
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
  | 'viewOrderHistory'
  | 'viewOpportunities'
  | 'expandGrid'
  | 'suggestCampaign'
  | 'notifyReplenishment'
  | 'resumeOrder'
  | 'viewSellerDetail';
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

export interface InsightCustomerGrowthPeriod {
  periodKey: string;
  revenue: number;
  hasOutlierOrder?: boolean;
  outlierAdjustedRevenue?: number | null;
}

export interface InsightCustomerGrowthSnapshot {
  customerId: string;
  organizationId: string;
  companyId: string;
  recipientUserId: string;
  customerName: string;
  /** Ordered chronologically, oldest first, most recent period last. */
  periods: InsightCustomerGrowthPeriod[];
  topGrowingCategoryId?: string | null;
  topGrowingCategoryName?: string | null;
  topGrowingCategoryRevenueGrowthAmount?: number | null;
}

export interface InsightCrossSellCategoryCandidate {
  categoryId: string;
  categoryName: string;
  /** Fraction (0..1) of the similar-customers group that buys this category. */
  peerAdoptionRate: number;
  peerAverageTicket: number;
  alreadyPurchasedByCustomer?: boolean;
  isAvailableInCustomerPriceList?: boolean;
  isActiveCollection?: boolean;
}

export interface InsightCrossSellSnapshot {
  customerId: string;
  organizationId: string;
  companyId: string;
  recipientUserId: string;
  customerName: string;
  /**
   * Human-readable description of the criterion used to select the
   * "similar customers" comparison group (e.g. same segment and region).
   * Always exposed in the insight evidence — never a black box.
   */
  similarityGroupLabel: string;
  similarityGroupSize: number;
  candidates: InsightCrossSellCategoryCandidate[];
}

export interface InsightUpSellVariantCandidate {
  variantId: string;
  variantLabel: string;
  /** Additional quantity that would close the gap, before checking stock. */
  desiredAdditionalQuantity: number;
  /** Real stock balance available for this variant at evaluation time. */
  availableStock: number;
}

export interface InsightUpSellCategoryCandidate {
  categoryId: string;
  categoryName: string;
  customerAverageTicket: number;
  customerAverageQuantity: number;
  peerAverageTicket: number;
  peerAverageQuantity: number;
  variantCandidates?: InsightUpSellVariantCandidate[];
}

export interface InsightUpSellSnapshot {
  customerId: string;
  organizationId: string;
  companyId: string;
  recipientUserId: string;
  customerName: string;
  /**
   * Human-readable description of the criterion used to select the
   * higher-volume similar-customers comparison group (same basis used by
   * cross-sell). Always exposed in the insight evidence — never a black box.
   */
  comparisonGroupLabel: string;
  comparisonGroupSize: number;
  candidates: InsightUpSellCategoryCandidate[];
}

export interface InsightInsufficientMixCategoryCandidate {
  categoryId: string;
  categoryName: string;
  /**
   * Fraction (0..1) of the comparison group that buys this category. By
   * linearity of expectation, the sum of this value across the whole
   * category universe equals the group's average number of distinct
   * categories purchased per customer (the mix benchmark).
   */
  peerAdoptionRate: number;
  purchasedByCustomer?: boolean;
}

export interface InsightInsufficientMixSnapshot {
  customerId: string;
  organizationId: string;
  companyId: string;
  recipientUserId: string;
  customerName: string;
  /**
   * Human-readable description of the criterion used to select the
   * benchmark comparison group (segment, region, porte, or a combination),
   * configurable by the organization. Always exposed in the insight
   * evidence — never a black box.
   */
  comparisonGroupLabel: string;
  comparisonGroupSize: number;
  /**
   * Segment used to resolve organization-configured category exclusions for
   * this customer's profile.
   */
  segment?: string | null;
  candidates: InsightInsufficientMixCategoryCandidate[];
}

/**
 * Per-product/variant stock position dataset, used by both
 * `HighStockLowTurnoverInsightRule` and `ReplenishmentSuggestionInsightRule`
 * to detect opposite risk signals from the same underlying stock indicators
 * (TASK-090 saldo por variante, TASK-094 indicadores de giro de estoque):
 * excess stock parked with low turnover on one side, and high-turnover
 * items at risk of stockout on the other.
 */
export interface InsightStockPositionSnapshot {
  productId: string;
  /** Variant identifier, when tracked at variant level (color/size). */
  variantId?: string | null;
  organizationId: string;
  companyId: string;
  recipientUserId: string;
  productName: string;
  variantLabel?: string | null;
  categoryId: string;
  categoryName: string;
  /** Current stock balance (units), per TASK-090. */
  currentStockQuantity: number;
  /** Estimated coverage, in days, at the recent average consumption rate. */
  coverageDays: number;
  /** Turnover index for the evaluated period (per TASK-094). */
  turnoverIndex: number;
  /** Days elapsed since the last sale considered relevant. */
  daysWithoutRelevantSale: number;
  /** Average daily consumption (units/day) behind the suggested reorder point. */
  averageDailyConsumption: number;
  /**
   * Suggested reorder point (units), computed upstream from the recent
   * average consumption (TASK-133 aggregation layer).
   */
  suggestedReorderPointQuantity: number;
  /**
   * Whether the product/variant is discontinued or outside the current
   * active collection.
   */
  isDiscontinued?: boolean;
}

/**
 * Per-customer dataset used by `ChurnRiskInsightRule` (TASK-129) to combine
 * three independent signals — decline in purchase frequency, decline in
 * revenue and the customer health score (TASK-062) — into a single,
 * explainable churn-risk score.
 */
export interface InsightChurnRiskSnapshot {
  customerId: string;
  organizationId: string;
  companyId: string;
  recipientUserId: string;
  customerName: string;
  /**
   * Total number of orders observed within the historical lookback window.
   * Gates whether the churn-risk score is reliable enough to be raised — a
   * customer with too little history must not produce a false positive.
   */
  historicalOrderCount: number;
  /** Recent purchase frequency (orders per period, e.g. orders/month). */
  recentPurchaseFrequency: number;
  /** Baseline purchase frequency over the historical comparison window. */
  historicalPurchaseFrequency: number;
  /** Revenue recorded in the recent observation window. */
  recentRevenue: number;
  /**
   * Baseline revenue recorded in the historical comparison window. Also
   * used, together with `averageTicket`, as the customer's financial impact
   * base for churn-risk prioritization.
   */
  historicalRevenue: number;
  /** Customer health score (0..100, higher is healthier), from TASK-062. */
  healthScore: number;
  /**
   * Optional historical average ticket, used as a financial-impact
   * fallback when `historicalRevenue` is not available.
   */
  averageTicket?: number | null;
}

/**
 * Per-draft-order dataset used by `AbandonedOrderInsightRule` (TASK-130) to
 * detect order drafts (`draft`/`pendingSync`) left untouched for too long,
 * distinguishing a recently-parked "carrinho salvo" from a truly stale
 * "pedido abandonado".
 */
export interface InsightAbandonedOrderSnapshot {
  orderId: string;
  organizationId: string;
  companyId: string;
  recipientUserId: string;
  customerId: string;
  customerName: string;
  /**
   * Timestamp of the last time the draft's content (items/quantities) was
   * changed — never the last Outbox sync attempt. This is the only signal
   * the rule uses to detect staleness.
   */
  lastContentChangeAt: Date;
  itemCount: number;
  /** Sum of the items already included in the draft. */
  estimatedValue: number;
  /**
   * Purely informational: whether this draft still has a pending Outbox
   * mutation. Intentionally never read by the rule's staleness gate — only
   * `lastContentChangeAt` decides abandonment.
   */
  hasPendingOutboxSync?: boolean;
  /**
   * Whether the draft was started while the seller was actively assisting
   * this customer, which makes "Contatar cliente" a relevant secondary
   * action alongside "Retomar pedido".
   */
  startedInServiceContext?: boolean;
  /**
   * Whether the draft references a customer/product that has since been
   * deleted, or a price list that has since expired — resuming it must
   * surface an explicit warning, never reopen silently.
   */
  hasInvalidReference?: boolean;
  invalidReferenceReason?: string | null;
}

/**
 * Per-seller dataset used by `SalesRepBelowTargetInsightRule` (TASK-131) to
 * detect a sales representative whose pace, extrapolated linearly to the end
 * of the target's period (TASK-115, EPIC-15), would not reach the goal
 * cadastrado.
 *
 * `elapsedRelevantDays`/`totalRelevantDays` are already resolved upstream
 * (TASK-133 aggregation layer) to whichever counting convention the
 * organization configured — calendar days or business days only.
 *
 * `recipientUserId` must always be resolved server-side to the seller's
 * *current sales manager* (never the seller themselves): this is what
 * restricts this insight's visibility to `SALES_MANAGER`/`ADMIN` and
 * guarantees a manager only ever receives insights about their own team.
 */
export interface InsightSalesRepBelowTargetSnapshot {
  sellerId: string;
  organizationId: string;
  companyId: string;
  recipientUserId: string;
  sellerName: string;
  /** Human-readable label for the target's period (e.g. "Setembro/2026"). */
  periodLabel: string;
  periodStartDate: Date;
  periodEndDate: Date;
  /** Goal cadastrado (TASK-115) for this seller in this period. */
  targetValue: number;
  /** Realized value so far in this period, as of the aggregation cutoff. */
  realizedValue: number;
  /** Relevant days already elapsed in the period. */
  elapsedRelevantDays: number;
  /** Total relevant days in the whole period. */
  totalRelevantDays: number;
}

export interface InsightOrganizationSettings {
  inactivityThresholdDays: number;
  inactivityThresholdDaysBySegment: Record<string, number>;
  revenueDropThreshold: number;
  revenueDropMinimumBaselineAmount: number;
  revenueComparisonMode: InsightRevenueComparisonMode;
  customerGrowthMinConsecutivePeriods: number;
  customerGrowthMinimumAverageRate: number;
  upSellMinimumTicketGapPercentage: number;
  insufficientMixThresholdPercentage: number;
  insufficientMixExcludedCategoryIds: string[];
  insufficientMixExcludedCategoryIdsBySegment: Record<string, string[]>;
  /** Minimum coverage (days) above which stock is considered "high". */
  highStockCoverageDaysThreshold: number;
  highStockCoverageDaysThresholdByCategory: Record<string, number>;
  /** Maximum turnover index below which turnover is considered "low". */
  lowTurnoverIndexThreshold: number;
  lowTurnoverIndexThresholdByCategory: Record<string, number>;
  /** Maximum coverage (days) below which a stockout risk is raised. */
  replenishmentLowCoverageDaysThreshold: number;
  replenishmentLowCoverageDaysThresholdByCategory: Record<string, number>;
  /** Minimum turnover index above which a product is "high-turnover". */
  replenishmentHighTurnoverIndexThreshold: number;
  replenishmentHighTurnoverIndexThresholdByCategory: Record<string, number>;
  /** Weight (0..1) of the purchase-frequency-decline signal in the
   * churn-risk composition score. */
  churnRiskFrequencyWeight: number;
  /** Weight (0..1) of the revenue-decline signal in the churn-risk
   * composition score. */
  churnRiskValueWeight: number;
  /** Weight (0..1) of the customer health-score signal (TASK-062) in the
   * churn-risk composition score. */
  churnRiskHealthScoreWeight: number;
  /** Minimum number of historical orders required for a reliable
   * churn-risk score. */
  churnRiskMinimumHistoricalOrders: number;
  /** Minimum composed risk score (0..1) to classify a customer as "medio"
   * risk and raise a churn-risk insight. */
  churnRiskMediumThreshold: number;
  /** Minimum composed risk score (0..1) to classify a customer as "alto"
   * risk. */
  churnRiskHighThreshold: number;
  /** Minimum composed risk score (0..1) to classify a customer as
   * "critico" risk. */
  churnRiskCriticalThreshold: number;
  /** Minimum hours since a draft order's content was last changed before it
   * is raised as a "carrinho salvo" (saved cart) insight. */
  abandonedOrderSavedCartThresholdHours: number;
  /** Minimum hours since a draft order's content was last changed before it
   * is raised as a "pedido abandonado" (abandoned order) insight instead of
   * the lower "carrinho salvo" severity. */
  abandonedOrderAbandonedThresholdHours: number;
  /** Minimum number of relevant days elapsed in the target's period before
   * `SalesRepBelowTargetInsightRule` is allowed to raise an insight for a
   * seller (e.g. "so a partir do 5o dia util"). */
  sellerBelowTargetMinimumElapsedDays: number;
  /** Minimum under-achievement ratio (0..1) required to raise a "medio"
   * risk insight — also the rule's gate (e.g. `0.10` = projection under 90%
   * of the goal). */
  sellerBelowTargetMediumThreshold: number;
  /** Minimum under-achievement ratio required to classify a seller as
   * "alto" risk. */
  sellerBelowTargetHighThreshold: number;
  /** Minimum under-achievement ratio required to classify a seller as
   * "critico" risk. */
  sellerBelowTargetCriticalThreshold: number;
  lifetimeDays: number;
}

export interface InsightDataset {
  settings: InsightOrganizationSettings;
  customerSnapshots: InsightCustomerSnapshot[];
  revenueComparisons: InsightRevenueComparisonSnapshot[];
  customerGrowthSnapshots: InsightCustomerGrowthSnapshot[];
  crossSellSnapshots: InsightCrossSellSnapshot[];
  upSellSnapshots: InsightUpSellSnapshot[];
  insufficientMixSnapshots: InsightInsufficientMixSnapshot[];
  stockPositionSnapshots: InsightStockPositionSnapshot[];
  churnRiskSnapshots: InsightChurnRiskSnapshot[];
  abandonedOrderSnapshots: InsightAbandonedOrderSnapshot[];
  salesRepBelowTargetSnapshots: InsightSalesRepBelowTargetSnapshot[];
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
  customerGrowthMinConsecutivePeriods: 3,
  customerGrowthMinimumAverageRate: 0.15,
  upSellMinimumTicketGapPercentage: 0.15,
  insufficientMixThresholdPercentage: 0.7,
  insufficientMixExcludedCategoryIds: [],
  insufficientMixExcludedCategoryIdsBySegment: {},
  highStockCoverageDaysThreshold: 60,
  highStockCoverageDaysThresholdByCategory: {},
  lowTurnoverIndexThreshold: 0.5,
  lowTurnoverIndexThresholdByCategory: {},
  replenishmentLowCoverageDaysThreshold: 10,
  replenishmentLowCoverageDaysThresholdByCategory: {},
  replenishmentHighTurnoverIndexThreshold: 1.5,
  replenishmentHighTurnoverIndexThresholdByCategory: {},
  churnRiskFrequencyWeight: 0.35,
  churnRiskValueWeight: 0.35,
  churnRiskHealthScoreWeight: 0.3,
  churnRiskMinimumHistoricalOrders: 3,
  churnRiskMediumThreshold: 0.35,
  churnRiskHighThreshold: 0.55,
  churnRiskCriticalThreshold: 0.75,
  abandonedOrderSavedCartThresholdHours: 24,
  abandonedOrderAbandonedThresholdHours: 72,
  sellerBelowTargetMinimumElapsedDays: 5,
  sellerBelowTargetMediumThreshold: 0.1,
  sellerBelowTargetHighThreshold: 0.3,
  sellerBelowTargetCriticalThreshold: 0.5,
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
