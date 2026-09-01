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
  type InsightContext,
  type InsightCrossSellSnapshot,
  type InsightCustomerGrowthSnapshot,
  type InsightCustomerSnapshot,
  type InsightDataset,
  type InsightOrganizationSettings,
  type InsightRevenueComparisonMode,
  type InsightRevenueComparisonSnapshot,
} from './insight-engine';
import { CrossSellInsightRule } from './cross-sell-insight-rule';
import { GrowingCustomerInsightRule } from './growing-customer-insight-rule';
import { InactiveCustomerInsightRule } from './inactive-customer-insight-rule';
import { RevenueDropInsightRule } from './revenue-drop-insight-rule';

const defaultRules = [
  new InactiveCustomerInsightRule(),
  new RevenueDropInsightRule(),
  new GrowingCustomerInsightRule(),
  new CrossSellInsightRule(),
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
    for (const insights of buildInsightsForOrganization({
      organizationId: organization.id,
      asOf: now,
      settings,
      customerSnapshots,
      revenueComparisons,
      customerGrowthSnapshots,
      crossSellSnapshots,
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
}): Insight[][] {
  const customerGrowthSnapshots = params.customerGrowthSnapshots ?? [];
  const crossSellSnapshots = params.crossSellSnapshots ?? [];
  const companyIds = new Set<string>([
    ...params.customerSnapshots.map((item) => item.companyId),
    ...params.revenueComparisons.map((item) => item.companyId),
    ...customerGrowthSnapshots.map((item) => item.companyId),
    ...crossSellSnapshots.map((item) => item.companyId),
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

function positiveNumber(value: unknown): number | undefined {
  return typeof value === 'number' && value > 0 ? value : undefined;
}

function serializeInsight(insight: Insight): DocumentData {
  return {
    ...insight,
    generatedAt: Timestamp.fromDate(insight.generatedAt),
    expiresAt: Timestamp.fromDate(insight.expiresAt),
  };
}
