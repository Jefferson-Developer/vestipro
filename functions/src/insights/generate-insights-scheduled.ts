import {
  Timestamp,
  getFirestore,
  type DocumentData,
  type DocumentReference,
} from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import {
  DEFAULT_INSIGHT_SETTINGS,
  evaluateInsights,
  type Insight,
  type InsightAbandonedOrderSnapshot,
  type InsightChurnRiskSnapshot,
  type InsightContext,
  type InsightCrossSellSnapshot,
  type InsightCustomerGrowthSnapshot,
  type InsightCustomerSnapshot,
  type InsightDataset,
  type InsightInsufficientMixSnapshot,
  type InsightOrganizationSettings,
  type InsightRevenueComparisonMode,
  type InsightRevenueComparisonSnapshot,
  type InsightStockPositionSnapshot,
  type InsightUpSellSnapshot,
} from './insight-engine';
import { AbandonedOrderInsightRule } from './abandoned-order-insight-rule';
import { ChurnRiskInsightRule } from './churn-risk-insight-rule';
import { CrossSellInsightRule } from './cross-sell-insight-rule';
import { GrowingCustomerInsightRule } from './growing-customer-insight-rule';
import { HighStockLowTurnoverInsightRule } from './high-stock-low-turnover-insight-rule';
import { InactiveCustomerInsightRule } from './inactive-customer-insight-rule';
import { InsufficientMixInsightRule } from './insufficient-mix-insight-rule';
import { ReplenishmentSuggestionInsightRule } from './replenishment-suggestion-insight-rule';
import { RevenueDropInsightRule } from './revenue-drop-insight-rule';
import { UpSellInsightRule } from './up-sell-insight-rule';

const defaultRules = [
  new InactiveCustomerInsightRule(),
  new RevenueDropInsightRule(),
  new GrowingCustomerInsightRule(),
  new CrossSellInsightRule(),
  new UpSellInsightRule(),
  new InsufficientMixInsightRule(),
  new HighStockLowTurnoverInsightRule(),
  new ReplenishmentSuggestionInsightRule(),
  new ChurnRiskInsightRule(),
  new AbandonedOrderInsightRule(),
] as const;

export const generateInsightsScheduled = onSchedule(
  {
    schedule: 'every day 05:00',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',
  },
  async () => {
    await generateInsightsScheduledHandler();
  },
);

export async function generateInsightsScheduledHandler(
  now = new Date(),
): Promise<void> {
  const db = getFirestore();
  const organizations = await db.collection('organizations').get();

  for (const organization of organizations.docs) {
    const data = organization.data();
    if (data.status !== 'active' || data.deletedAt != null) {
      continue;
    }

    const settings = resolveSettings(
      (
        await organization.ref.collection('insightSettings').doc('default').get()
      ).data(),
    );
    const customerSnapshots = await loadCustomerSnapshots(organization.ref);
    const revenueComparisons = await loadRevenueComparisons(organization.ref);
    const customerGrowthSnapshots = await loadCustomerGrowthSnapshots(
      organization.ref,
    );
    const crossSellSnapshots = await loadCrossSellSnapshots(organization.ref);
    const upSellSnapshots = await loadUpSellSnapshots(organization.ref);
    const insufficientMixSnapshots = await loadInsufficientMixSnapshots(
      organization.ref,
    );
    const stockPositionSnapshots = await loadStockPositionSnapshots(
      organization.ref,
    );
    const churnRiskSnapshots = await loadChurnRiskSnapshots(organization.ref);
    const abandonedOrderSnapshots = await loadAbandonedOrderSnapshots(
      organization.ref,
    );
    for (const insights of buildInsightsForOrganization({
      organizationId: organization.id,
      asOf: now,
      settings,
      customerSnapshots,
      revenueComparisons,
      customerGrowthSnapshots,
      crossSellSnapshots,
      upSellSnapshots,
      insufficientMixSnapshots,
      stockPositionSnapshots,
      churnRiskSnapshots,
      abandonedOrderSnapshots,
    })) {
      await persistInsights(organization.ref, insights);
      logger.info('generateInsightsScheduled processed company', {
        organizationId: organization.id,
        companyId: insights[0]?.companyId ?? 'n/a',
        generatedInsights: insights.length,
      });
    }
  }
}

async function persistInsights(
  organizationRef: DocumentReference,
  insights: readonly Insight[],
): Promise<void> {
  if (insights.length === 0) {
    return;
  }

  const db = getFirestore();
  let batch = db.batch();
  let writes = 0;
  for (const insight of insights) {
    batch.set(
      organizationRef.collection('insights').doc(insight.id),
      serializeInsight(insight),
      { merge: true },
    );
    writes += 1;
    if (writes >= 450) {
      await batch.commit();
      batch = db.batch();
      writes = 0;
    }
  }

  if (writes > 0) {
    await batch.commit();
  }
}

async function loadCustomerSnapshots(
  organizationRef: DocumentReference,
): Promise<InsightCustomerSnapshot[]> {
  const snapshot = await organizationRef
    .collection('insightCustomerSnapshots')
    .get();
  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      customerId: doc.id,
      organizationId: data.organizationId as string,
      companyId: data.companyId as string,
      recipientUserId: data.recipientUserId as string,
      customerName: data.customerName as string,
      customerStatus: data.customerStatus as string,
      segment: (data.segment as string | null | undefined) ?? null,
      lastOrderAt:
        (data.lastOrderAt as Timestamp | null | undefined)?.toDate() ?? null,
      lastOrderValue:
        (data.lastOrderValue as number | null | undefined) ?? null,
      averageTicket: (data.averageTicket as number | null | undefined) ?? null,
      responsibleSellerId:
        (data.responsibleSellerId as string | null | undefined) ?? null,
    };
  });
}

async function loadRevenueComparisons(
  organizationRef: DocumentReference,
): Promise<InsightRevenueComparisonSnapshot[]> {
  const snapshot = await organizationRef
    .collection('insightRevenueComparisons')
    .get();
  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      customerId: data.customerId as string,
      organizationId: data.organizationId as string,
      companyId: data.companyId as string,
      recipientUserId: data.recipientUserId as string,
      customerName: data.customerName as string,
      mode: data.mode as InsightRevenueComparisonMode,
      currentPeriodRevenue: data.currentPeriodRevenue as number,
      previousEquivalentRevenue: data.previousEquivalentRevenue as number,
      currentPeriodKey: data.currentPeriodKey as string,
      previousPeriodKey: data.previousPeriodKey as string,
      currentSeasonCode:
        (data.currentSeasonCode as string | null | undefined) ?? null,
      previousSeasonCode:
        (data.previousSeasonCode as string | null | undefined) ?? null,
      topCategoryId: (data.topCategoryId as string | null | undefined) ?? null,
      topCategoryName:
        (data.topCategoryName as string | null | undefined) ?? null,
      topCategoryRevenueDropAmount:
        (data.topCategoryRevenueDropAmount as number | null | undefined) ??
        null,
    };
  });
}

async function loadCustomerGrowthSnapshots(
  organizationRef: DocumentReference,
): Promise<InsightCustomerGrowthSnapshot[]> {
  const snapshot = await organizationRef
    .collection('insightCustomerGrowthSnapshots')
    .get();
  return snapshot.docs.map((doc) => {
    const data = doc.data();
    const periods = Array.isArray(data.periods) ? data.periods : [];
    return {
      customerId: data.customerId as string,
      organizationId: data.organizationId as string,
      companyId: data.companyId as string,
      recipientUserId: data.recipientUserId as string,
      customerName: data.customerName as string,
      periods: periods.map((period: DocumentData) => ({
        periodKey: period.periodKey as string,
        revenue: period.revenue as number,
        hasOutlierOrder: Boolean(period.hasOutlierOrder),
        outlierAdjustedRevenue:
          (period.outlierAdjustedRevenue as number | null | undefined) ??
          null,
      })),
      topGrowingCategoryId:
        (data.topGrowingCategoryId as string | null | undefined) ?? null,
      topGrowingCategoryName:
        (data.topGrowingCategoryName as string | null | undefined) ?? null,
      topGrowingCategoryRevenueGrowthAmount:
        (data.topGrowingCategoryRevenueGrowthAmount as
          | number
          | null
          | undefined) ?? null,
    };
  });
}

async function loadCrossSellSnapshots(
  organizationRef: DocumentReference,
): Promise<InsightCrossSellSnapshot[]> {
  const snapshot = await organizationRef
    .collection('insightCrossSellSnapshots')
    .get();
  return snapshot.docs.map((doc) => {
    const data = doc.data();
    const candidates = Array.isArray(data.candidates) ? data.candidates : [];
    return {
      customerId: data.customerId as string,
      organizationId: data.organizationId as string,
      companyId: data.companyId as string,
      recipientUserId: data.recipientUserId as string,
      customerName: data.customerName as string,
      similarityGroupLabel: data.similarityGroupLabel as string,
      similarityGroupSize: (data.similarityGroupSize as number) ?? 0,
      candidates: candidates.map((candidate: DocumentData) => ({
        categoryId: candidate.categoryId as string,
        categoryName: candidate.categoryName as string,
        peerAdoptionRate: candidate.peerAdoptionRate as number,
        peerAverageTicket: candidate.peerAverageTicket as number,
        alreadyPurchasedByCustomer: Boolean(
          candidate.alreadyPurchasedByCustomer,
        ),
        isAvailableInCustomerPriceList:
          candidate.isAvailableInCustomerPriceList !== false,
        isActiveCollection: candidate.isActiveCollection !== false,
      })),
    };
  });
}

async function loadUpSellSnapshots(
  organizationRef: DocumentReference,
): Promise<InsightUpSellSnapshot[]> {
  const snapshot = await organizationRef
    .collection('insightUpSellSnapshots')
    .get();
  return snapshot.docs.map((doc) => {
    const data = doc.data();
    const candidates = Array.isArray(data.candidates) ? data.candidates : [];
    return {
      customerId: data.customerId as string,
      organizationId: data.organizationId as string,
      companyId: data.companyId as string,
      recipientUserId: data.recipientUserId as string,
      customerName: data.customerName as string,
      comparisonGroupLabel: data.comparisonGroupLabel as string,
      comparisonGroupSize: (data.comparisonGroupSize as number) ?? 0,
      candidates: candidates.map((candidate: DocumentData) => {
        const variantCandidates = Array.isArray(candidate.variantCandidates)
          ? candidate.variantCandidates
          : [];
        return {
          categoryId: candidate.categoryId as string,
          categoryName: candidate.categoryName as string,
          customerAverageTicket: candidate.customerAverageTicket as number,
          customerAverageQuantity:
            candidate.customerAverageQuantity as number,
          peerAverageTicket: candidate.peerAverageTicket as number,
          peerAverageQuantity: candidate.peerAverageQuantity as number,
          variantCandidates: variantCandidates.map(
            (variant: DocumentData) => ({
              variantId: variant.variantId as string,
              variantLabel: variant.variantLabel as string,
              desiredAdditionalQuantity:
                variant.desiredAdditionalQuantity as number,
              availableStock: variant.availableStock as number,
            }),
          ),
        };
      }),
    };
  });
}

async function loadInsufficientMixSnapshots(
  organizationRef: DocumentReference,
): Promise<InsightInsufficientMixSnapshot[]> {
  const snapshot = await organizationRef
    .collection('insightInsufficientMixSnapshots')
    .get();
  return snapshot.docs.map((doc) => {
    const data = doc.data();
    const candidates = Array.isArray(data.candidates) ? data.candidates : [];
    return {
      customerId: data.customerId as string,
      organizationId: data.organizationId as string,
      companyId: data.companyId as string,
      recipientUserId: data.recipientUserId as string,
      customerName: data.customerName as string,
      comparisonGroupLabel: data.comparisonGroupLabel as string,
      comparisonGroupSize: (data.comparisonGroupSize as number) ?? 0,
      segment: (data.segment as string | null | undefined) ?? null,
      candidates: candidates.map((candidate: DocumentData) => ({
        categoryId: candidate.categoryId as string,
        categoryName: candidate.categoryName as string,
        peerAdoptionRate: candidate.peerAdoptionRate as number,
        purchasedByCustomer: Boolean(candidate.purchasedByCustomer),
      })),
    };
  });
}

async function loadStockPositionSnapshots(
  organizationRef: DocumentReference,
): Promise<InsightStockPositionSnapshot[]> {
  const snapshot = await organizationRef
    .collection('insightStockPositionSnapshots')
    .get();
  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      productId: data.productId as string,
      variantId: (data.variantId as string | null | undefined) ?? null,
      organizationId: data.organizationId as string,
      companyId: data.companyId as string,
      recipientUserId: data.recipientUserId as string,
      productName: data.productName as string,
      variantLabel: (data.variantLabel as string | null | undefined) ?? null,
      categoryId: data.categoryId as string,
      categoryName: data.categoryName as string,
      currentStockQuantity: (data.currentStockQuantity as number) ?? 0,
      coverageDays: (data.coverageDays as number) ?? 0,
      turnoverIndex: (data.turnoverIndex as number) ?? 0,
      daysWithoutRelevantSale:
        (data.daysWithoutRelevantSale as number) ?? 0,
      averageDailyConsumption:
        (data.averageDailyConsumption as number) ?? 0,
      suggestedReorderPointQuantity:
        (data.suggestedReorderPointQuantity as number) ?? 0,
      isDiscontinued: Boolean(data.isDiscontinued),
    };
  });
}

async function loadChurnRiskSnapshots(
  organizationRef: DocumentReference,
): Promise<InsightChurnRiskSnapshot[]> {
  const snapshot = await organizationRef
    .collection('insightChurnRiskSnapshots')
    .get();
  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      customerId: data.customerId as string,
      organizationId: data.organizationId as string,
      companyId: data.companyId as string,
      recipientUserId: data.recipientUserId as string,
      customerName: data.customerName as string,
      historicalOrderCount: (data.historicalOrderCount as number) ?? 0,
      recentPurchaseFrequency: (data.recentPurchaseFrequency as number) ?? 0,
      historicalPurchaseFrequency:
        (data.historicalPurchaseFrequency as number) ?? 0,
      recentRevenue: (data.recentRevenue as number) ?? 0,
      historicalRevenue: (data.historicalRevenue as number) ?? 0,
      healthScore: (data.healthScore as number) ?? 0,
      averageTicket: (data.averageTicket as number | null | undefined) ?? null,
    };
  });
}

async function loadAbandonedOrderSnapshots(
  organizationRef: DocumentReference,
): Promise<InsightAbandonedOrderSnapshot[]> {
  const snapshot = await organizationRef
    .collection('insightAbandonedOrderSnapshots')
    .get();
  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      orderId: (data.orderId as string) ?? doc.id,
      organizationId: data.organizationId as string,
      companyId: data.companyId as string,
      recipientUserId: data.recipientUserId as string,
      customerId: data.customerId as string,
      customerName: data.customerName as string,
      lastContentChangeAt: (
        data.lastContentChangeAt as Timestamp
      ).toDate(),
      itemCount: (data.itemCount as number) ?? 0,
      estimatedValue: (data.estimatedValue as number) ?? 0,
      hasPendingOutboxSync: Boolean(data.hasPendingOutboxSync),
      startedInServiceContext: Boolean(data.startedInServiceContext),
      hasInvalidReference: Boolean(data.hasInvalidReference),
      invalidReferenceReason:
        (data.invalidReferenceReason as string | null | undefined) ?? null,
    };
  });
}

function resolveSettings(
  settingsData: DocumentData | undefined,
): InsightOrganizationSettings {
  const lifetimeDays = settingsData?.lifetimeDays;
  return {
    inactivityThresholdDays:
      positiveNumber(settingsData?.inactivityThresholdDays) ??
      DEFAULT_INSIGHT_SETTINGS.inactivityThresholdDays,
    inactivityThresholdDaysBySegment:
      normalizeSegmentThresholds(
        settingsData?.inactivityThresholdDaysBySegment,
      ) ?? DEFAULT_INSIGHT_SETTINGS.inactivityThresholdDaysBySegment,
    revenueDropThreshold:
      positiveNumber(settingsData?.revenueDropThreshold) ??
      DEFAULT_INSIGHT_SETTINGS.revenueDropThreshold,
    revenueDropMinimumBaselineAmount:
      positiveNumber(settingsData?.revenueDropMinimumBaselineAmount) ??
      DEFAULT_INSIGHT_SETTINGS.revenueDropMinimumBaselineAmount,
    revenueComparisonMode:
      settingsData?.revenueComparisonMode === 'monthOverMonth'
        ? 'monthOverMonth'
        : DEFAULT_INSIGHT_SETTINGS.revenueComparisonMode,
    customerGrowthMinConsecutivePeriods:
      positiveNumber(settingsData?.customerGrowthMinConsecutivePeriods) ??
      DEFAULT_INSIGHT_SETTINGS.customerGrowthMinConsecutivePeriods,
    customerGrowthMinimumAverageRate:
      positiveNumber(settingsData?.customerGrowthMinimumAverageRate) ??
      DEFAULT_INSIGHT_SETTINGS.customerGrowthMinimumAverageRate,
    upSellMinimumTicketGapPercentage:
      positiveNumber(settingsData?.upSellMinimumTicketGapPercentage) ??
      DEFAULT_INSIGHT_SETTINGS.upSellMinimumTicketGapPercentage,
    insufficientMixThresholdPercentage:
      positiveNumber(settingsData?.insufficientMixThresholdPercentage) ??
      DEFAULT_INSIGHT_SETTINGS.insufficientMixThresholdPercentage,
    insufficientMixExcludedCategoryIds:
      normalizeStringArray(settingsData?.insufficientMixExcludedCategoryIds) ??
      DEFAULT_INSIGHT_SETTINGS.insufficientMixExcludedCategoryIds,
    insufficientMixExcludedCategoryIdsBySegment:
      normalizeSegmentCategoryIds(
        settingsData?.insufficientMixExcludedCategoryIdsBySegment,
      ) ?? DEFAULT_INSIGHT_SETTINGS.insufficientMixExcludedCategoryIdsBySegment,
    highStockCoverageDaysThreshold:
      positiveNumber(settingsData?.highStockCoverageDaysThreshold) ??
      DEFAULT_INSIGHT_SETTINGS.highStockCoverageDaysThreshold,
    highStockCoverageDaysThresholdByCategory:
      normalizeCategoryThresholds(
        settingsData?.highStockCoverageDaysThresholdByCategory,
      ) ?? DEFAULT_INSIGHT_SETTINGS.highStockCoverageDaysThresholdByCategory,
    lowTurnoverIndexThreshold:
      positiveNumber(settingsData?.lowTurnoverIndexThreshold) ??
      DEFAULT_INSIGHT_SETTINGS.lowTurnoverIndexThreshold,
    lowTurnoverIndexThresholdByCategory:
      normalizeCategoryThresholds(
        settingsData?.lowTurnoverIndexThresholdByCategory,
      ) ?? DEFAULT_INSIGHT_SETTINGS.lowTurnoverIndexThresholdByCategory,
    replenishmentLowCoverageDaysThreshold:
      positiveNumber(settingsData?.replenishmentLowCoverageDaysThreshold) ??
      DEFAULT_INSIGHT_SETTINGS.replenishmentLowCoverageDaysThreshold,
    replenishmentLowCoverageDaysThresholdByCategory:
      normalizeCategoryThresholds(
        settingsData?.replenishmentLowCoverageDaysThresholdByCategory,
      ) ??
      DEFAULT_INSIGHT_SETTINGS.replenishmentLowCoverageDaysThresholdByCategory,
    replenishmentHighTurnoverIndexThreshold:
      positiveNumber(
        settingsData?.replenishmentHighTurnoverIndexThreshold,
      ) ?? DEFAULT_INSIGHT_SETTINGS.replenishmentHighTurnoverIndexThreshold,
    replenishmentHighTurnoverIndexThresholdByCategory:
      normalizeCategoryThresholds(
        settingsData?.replenishmentHighTurnoverIndexThresholdByCategory,
      ) ??
      DEFAULT_INSIGHT_SETTINGS.replenishmentHighTurnoverIndexThresholdByCategory,
    churnRiskFrequencyWeight:
      positiveNumber(settingsData?.churnRiskFrequencyWeight) ??
      DEFAULT_INSIGHT_SETTINGS.churnRiskFrequencyWeight,
    churnRiskValueWeight:
      positiveNumber(settingsData?.churnRiskValueWeight) ??
      DEFAULT_INSIGHT_SETTINGS.churnRiskValueWeight,
    churnRiskHealthScoreWeight:
      positiveNumber(settingsData?.churnRiskHealthScoreWeight) ??
      DEFAULT_INSIGHT_SETTINGS.churnRiskHealthScoreWeight,
    churnRiskMinimumHistoricalOrders:
      positiveNumber(settingsData?.churnRiskMinimumHistoricalOrders) ??
      DEFAULT_INSIGHT_SETTINGS.churnRiskMinimumHistoricalOrders,
    churnRiskMediumThreshold:
      positiveNumber(settingsData?.churnRiskMediumThreshold) ??
      DEFAULT_INSIGHT_SETTINGS.churnRiskMediumThreshold,
    churnRiskHighThreshold:
      positiveNumber(settingsData?.churnRiskHighThreshold) ??
      DEFAULT_INSIGHT_SETTINGS.churnRiskHighThreshold,
    churnRiskCriticalThreshold:
      positiveNumber(settingsData?.churnRiskCriticalThreshold) ??
      DEFAULT_INSIGHT_SETTINGS.churnRiskCriticalThreshold,
    abandonedOrderSavedCartThresholdHours:
      positiveNumber(settingsData?.abandonedOrderSavedCartThresholdHours) ??
      DEFAULT_INSIGHT_SETTINGS.abandonedOrderSavedCartThresholdHours,
    abandonedOrderAbandonedThresholdHours:
      positiveNumber(settingsData?.abandonedOrderAbandonedThresholdHours) ??
      DEFAULT_INSIGHT_SETTINGS.abandonedOrderAbandonedThresholdHours,
    lifetimeDays:
      typeof lifetimeDays === 'number' && lifetimeDays > 0
        ? lifetimeDays
        : DEFAULT_INSIGHT_SETTINGS.lifetimeDays,
  };
}

export function buildInsightsForOrganization(params: {
  organizationId: string;
  asOf: Date;
  settings: InsightOrganizationSettings;
  customerSnapshots: readonly InsightCustomerSnapshot[];
  revenueComparisons: readonly InsightRevenueComparisonSnapshot[];
  customerGrowthSnapshots?: readonly InsightCustomerGrowthSnapshot[];
  crossSellSnapshots?: readonly InsightCrossSellSnapshot[];
  upSellSnapshots?: readonly InsightUpSellSnapshot[];
  insufficientMixSnapshots?: readonly InsightInsufficientMixSnapshot[];
  stockPositionSnapshots?: readonly InsightStockPositionSnapshot[];
  churnRiskSnapshots?: readonly InsightChurnRiskSnapshot[];
  abandonedOrderSnapshots?: readonly InsightAbandonedOrderSnapshot[];
}): Insight[][] {
  const customerGrowthSnapshots = params.customerGrowthSnapshots ?? [];
  const crossSellSnapshots = params.crossSellSnapshots ?? [];
  const upSellSnapshots = params.upSellSnapshots ?? [];
  const insufficientMixSnapshots = params.insufficientMixSnapshots ?? [];
  const stockPositionSnapshots = params.stockPositionSnapshots ?? [];
  const churnRiskSnapshots = params.churnRiskSnapshots ?? [];
  const abandonedOrderSnapshots = params.abandonedOrderSnapshots ?? [];
  const companyIds = new Set<string>([
    ...params.customerSnapshots.map((item) => item.companyId),
    ...params.revenueComparisons.map((item) => item.companyId),
    ...customerGrowthSnapshots.map((item) => item.companyId),
    ...crossSellSnapshots.map((item) => item.companyId),
    ...upSellSnapshots.map((item) => item.companyId),
    ...insufficientMixSnapshots.map((item) => item.companyId),
    ...stockPositionSnapshots.map((item) => item.companyId),
    ...churnRiskSnapshots.map((item) => item.companyId),
    ...abandonedOrderSnapshots.map((item) => item.companyId),
  ]);
  const results: Insight[][] = [];
  for (const companyId of companyIds) {
    const dataset: InsightDataset = {
      settings: params.settings,
      customerSnapshots: params.customerSnapshots.filter(
        (item) => item.companyId === companyId,
      ),
      revenueComparisons: params.revenueComparisons.filter(
        (item) => item.companyId === companyId,
      ),
      customerGrowthSnapshots: customerGrowthSnapshots.filter(
        (item) => item.companyId === companyId,
      ),
      crossSellSnapshots: crossSellSnapshots.filter(
        (item) => item.companyId === companyId,
      ),
      upSellSnapshots: upSellSnapshots.filter(
        (item) => item.companyId === companyId,
      ),
      insufficientMixSnapshots: insufficientMixSnapshots.filter(
        (item) => item.companyId === companyId,
      ),
      stockPositionSnapshots: stockPositionSnapshots.filter(
        (item) => item.companyId === companyId,
      ),
      churnRiskSnapshots: churnRiskSnapshots.filter(
        (item) => item.companyId === companyId,
      ),
      abandonedOrderSnapshots: abandonedOrderSnapshots.filter(
        (item) => item.companyId === companyId,
      ),
    };
    const context: InsightContext = {
      organizationId: params.organizationId,
      companyId,
      asOf: params.asOf,
      dataset,
    };
    results.push(evaluateInsights(context, defaultRules));
  }
  return results;
}

function normalizeSegmentThresholds(
  value: unknown,
): Record<string, number> | undefined {
  if (!value || typeof value !== 'object') {
    return undefined;
  }
  const entries = Object.entries(value as Record<string, unknown>)
    .filter(([, threshold]) => typeof threshold === 'number' && threshold > 0)
    .map(([segment, threshold]) => [
      segment.trim().toLowerCase(),
      threshold as number,
    ]);
  return Object.fromEntries(entries);
}

/**
 * Normalizes a category-id-keyed threshold map. Unlike segment names,
 * category ids are opaque identifiers, so keys are trimmed but never
 * lowercased.
 */
function normalizeCategoryThresholds(
  value: unknown,
): Record<string, number> | undefined {
  if (!value || typeof value !== 'object') {
    return undefined;
  }
  const entries = Object.entries(value as Record<string, unknown>)
    .filter(([, threshold]) => typeof threshold === 'number' && threshold > 0)
    .map(([categoryId, threshold]) => [
      categoryId.trim(),
      threshold as number,
    ]);
  return Object.fromEntries(entries);
}

function positiveNumber(value: unknown): number | undefined {
  return typeof value === 'number' && value > 0 ? value : undefined;
}

function normalizeStringArray(value: unknown): string[] | undefined {
  if (!Array.isArray(value)) {
    return undefined;
  }
  return value.filter((item): item is string => typeof item === 'string');
}

function normalizeSegmentCategoryIds(
  value: unknown,
): Record<string, string[]> | undefined {
  if (!value || typeof value !== 'object') {
    return undefined;
  }
  const entries = Object.entries(value as Record<string, unknown>)
    .map(([segment, categoryIds]) => [
      segment.trim().toLowerCase(),
      normalizeStringArray(categoryIds) ?? [],
    ] as const)
    .filter(([, categoryIds]) => categoryIds.length > 0);
  return Object.fromEntries(entries);
}

function serializeInsight(insight: Insight): DocumentData {
  return {
    ...insight,
    generatedAt: Timestamp.fromDate(insight.generatedAt),
    expiresAt: Timestamp.fromDate(insight.expiresAt),
  };
}
