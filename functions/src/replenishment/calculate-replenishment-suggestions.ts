import {
  Timestamp,
  getFirestore,
  type DocumentData,
} from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import {
  asStockTurnoverDailyFact,
  buildMetricSnapshot,
  type StockTurnoverDailyFact,
} from '../inventory/stock-turnover-shared';
import {
  DEFAULT_REPLENISHMENT_PARAMETERS,
  DEFAULT_TURNOVER_LOOKBACK_DAYS,
  FROZEN_REPLENISHMENT_STATUSES,
  asReplenishmentVariantStockBalance,
  calculateReplenishmentSuggestion,
  sellableQuantityOf,
  type ReplenishmentParameters,
  type ReplenishmentSuggestionStatus,
  type ReplenishmentVariantStockBalance,
} from './replenishment-calculation-shared';

const MS_PER_DAY = 24 * 60 * 60 * 1000;

/**
 * Injectable persistence port for the weekly replenishment calculation —
 * same "port + Firestore adapter + in-memory fake for unit tests" shape
 * already used by `../inventory/sync-stock-alerts.ts`'s
 * `StockAlertPersistence` (TASK-093). Letting
 * `functions/test/replenishment/calculate-replenishment-suggestions.test.ts`
 * exercise idempotency/multi-tenant isolation/frozen-status protection with
 * an in-memory fake, entirely without the Firestore Emulator (which this
 * sandbox cannot run — no Java, same limitation already documented in
 * TASK-094/TASK-133's own CONCLUIDA docs).
 */
export interface ReplenishmentPersistence {
  listActiveOrganizationIds(): Promise<ReadonlyArray<string>>;
  loadSettings(organizationId: string): Promise<ReplenishmentParameters>;
  listVariantStockBalances(
    organizationId: string,
  ): Promise<ReadonlyArray<ReplenishmentVariantStockBalance>>;
  listStockTurnoverDailyFacts(
    organizationId: string,
    periodStart: Date,
    periodEnd: Date,
  ): Promise<ReadonlyArray<StockTurnoverDailyFact>>;
  loadExistingSuggestionStatus(
    organizationId: string,
    documentId: string,
  ): Promise<string | null>;
  saveSuggestion(
    organizationId: string,
    documentId: string,
    data: DocumentData,
  ): Promise<void>;
}

export interface ReplenishmentCalculationOutcome {
  generatedCount: number;
  /** Suggestions skipped because a human already decided them
   * (`FROZEN_REPLENISHMENT_STATUSES`) for this exact `periodEnd` — the
   * concrete evidence of "idempotência em reexecução no mesmo período"
   * (`tasks.md`/TASK-184's own "Testes obrigatórios"). */
  skippedFrozenCount: number;
}

/**
 * Calculates (and idempotently persists) one `ReplenishmentSuggestion` per
 * variant/warehouse combination with a stock balance in [organizationId],
 * for the period ending on [now]. Exported separately from the
 * `onSchedule` trigger so both a real weekly run and a unit test can call it
 * directly with an explicit [now]/[persistence].
 */
export async function calculateReplenishmentSuggestionsForOrganization(params: {
  organizationId: string;
  now: Date;
  persistence: ReplenishmentPersistence;
}): Promise<ReplenishmentCalculationOutcome> {
  const { organizationId, now, persistence } = params;

  const balances = await persistence.listVariantStockBalances(organizationId);
  if (balances.length === 0) {
    return { generatedCount: 0, skippedFrozenCount: 0 };
  }

  const parameters = await persistence.loadSettings(organizationId);

  const periodEndKey = formatDateKey(now);
  const periodStartDate = new Date(
    now.getTime() - DEFAULT_TURNOVER_LOOKBACK_DAYS * MS_PER_DAY,
  );
  const periodStartKey = formatDateKey(periodStartDate);

  const facts = await persistence.listStockTurnoverDailyFacts(
    organizationId,
    periodStartDate,
    now,
  );
  const factsByVariantId = groupFactsByVariantId(facts);
  const generatedAt = Timestamp.fromDate(now);
  const parametersSnapshot = { ...parameters, calculatedAt: generatedAt };

  let generatedCount = 0;
  let skippedFrozenCount = 0;

  for (const balance of balances) {
    const variantFacts = factsByVariantId.get(balance.variantId);
    // TASK-094's own `'variant'` scope aggregates a variant's turnover
    // across every warehouse (see `recompute-stock-turnover-metrics.ts`'s
    // `buildSnapshotsForScope`, keyed only by `fact.variantId`) — this
    // mirrors that exactly, since `stockTurnoverDailyFacts` is not reliably
    // split finely enough to compute a *per-warehouse* turnover rate today.
    // The suggestion is still generated per warehouse: only the sales
    // velocity input is org-wide, `currentSellableQuantity` below remains
    // this specific `balance`'s own warehouse.
    const turnoverMetric = variantFacts
      ? buildMetricSnapshot({
          organizationId,
          scopeType: 'variant',
          scopeId: balance.variantId,
          periodStart: periodStartKey,
          periodEnd: periodEndKey,
          facts: variantFacts,
          generatedAt,
        })
      : null;

    const currentSellableQuantity = sellableQuantityOf(balance);
    const result = calculateReplenishmentSuggestion({
      turnover: turnoverMetric,
      currentSellableQuantity,
      // See `replenishment-calculation-shared.ts`'s own doc comment on
      // `ReplenishmentCalculationInput.futureStockQuantity`: `FutureStockEntry`
      // (TASK-091) has no synced Firestore collection today, so a Cloud
      // Function has no server-side source to read it from yet.
      futureStockQuantity: 0,
      parameters,
    });

    const documentId = `${balance.warehouseId}_${balance.variantId}_${periodEndKey}`;
    const existingStatus = await persistence.loadExistingSuggestionStatus(
      organizationId,
      documentId,
    );
    if (
      existingStatus &&
      FROZEN_REPLENISHMENT_STATUSES.has(
        existingStatus as ReplenishmentSuggestionStatus,
      )
    ) {
      skippedFrozenCount += 1;
      continue;
    }

    await persistence.saveSuggestion(organizationId, documentId, {
      organizationId,
      companyId: balance.companyId,
      warehouseId: balance.warehouseId,
      variantId: balance.variantId,
      productId: balance.productId,
      periodStart: periodStartKey,
      periodEnd: periodEndKey,
      status: result.insufficientData ? 'insufficientData' : 'suggested',
      insufficientDataReason: result.insufficientDataReason,
      suggestedQuantity: result.suggestedQuantity,
      targetStockQuantity: result.targetStockQuantity,
      finalQuantity: null,
      currentSellableQuantity,
      futureStockQuantity: 0,
      turnoverEvidence: turnoverMetric
        ? {
            averageDailySalesQuantity: turnoverMetric.averageDailySalesQuantity,
            stockCoverageDays: turnoverMetric.stockCoverageDays,
            turnoverRate: turnoverMetric.turnoverRate,
            coverageStatus: turnoverMetric.coverageStatus,
          }
        : null,
      parametersSnapshot,
      decidedBy: null,
      decidedByName: null,
      decidedAt: null,
      decisionAudit: [],
      generatedAt,
      updatedAt: generatedAt,
      version: 1,
    });
    generatedCount += 1;
  }

  return { generatedCount, skippedFrozenCount };
}

/**
 * Loops every active organization, isolating failures per organization
 * (same "one tenant's failure never aborts the batch" contract as
 * `../insights/generate-insights-scheduled.ts`/
 * `../aggregations/recompute-monthly-aggregates.ts`).
 */
export async function calculateReplenishmentSuggestionsScheduledHandler(
  now: Date = new Date(),
  persistence?: ReplenishmentPersistence,
): Promise<void> {
  const adapter = persistence ?? createFirestorePersistence();
  const organizationIds = await adapter.listActiveOrganizationIds();

  for (const organizationId of organizationIds) {
    try {
      const outcome = await calculateReplenishmentSuggestionsForOrganization({
        organizationId,
        now,
        persistence: adapter,
      });
      logger.info('calculateReplenishmentSuggestions processed organization', {
        organizationId,
        generatedCount: outcome.generatedCount,
        skippedFrozenCount: outcome.skippedFrozenCount,
      });
    } catch (error) {
      logger.error('calculateReplenishmentSuggestions failed for organization', {
        organizationId,
        error,
      });
    }
  }
}

function groupFactsByVariantId(
  facts: ReadonlyArray<StockTurnoverDailyFact>,
): Map<string, StockTurnoverDailyFact[]> {
  const grouped = new Map<string, StockTurnoverDailyFact[]>();
  for (const fact of facts) {
    if (!fact.variantId) continue;
    const current = grouped.get(fact.variantId) ?? [];
    current.push(fact);
    grouped.set(fact.variantId, current);
  }
  return grouped;
}

function formatDateKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function parseReplenishmentParameters(
  data: DocumentData | undefined,
): ReplenishmentParameters {
  return {
    coverageTargetDays:
      positiveNumber(data?.coverageTargetDays) ??
      DEFAULT_REPLENISHMENT_PARAMETERS.coverageTargetDays,
    safetyStockQuantity:
      nonNegativeNumber(data?.safetyStockQuantity) ??
      DEFAULT_REPLENISHMENT_PARAMETERS.safetyStockQuantity,
    seasonalityFactor:
      positiveNumber(data?.seasonalityFactor) ??
      DEFAULT_REPLENISHMENT_PARAMETERS.seasonalityFactor,
  };
}

function positiveNumber(value: unknown): number | undefined {
  return typeof value === 'number' && value > 0 ? value : undefined;
}

function nonNegativeNumber(value: unknown): number | undefined {
  return typeof value === 'number' && value >= 0 ? value : undefined;
}

function createFirestorePersistence(): ReplenishmentPersistence {
  const db = getFirestore();

  return {
    async listActiveOrganizationIds(): Promise<ReadonlyArray<string>> {
      const snapshot = await db.collection('organizations').get();
      return snapshot.docs
        .filter((doc) => {
          const data = doc.data();
          return data.status === 'active' && data.deletedAt == null;
        })
        .map((doc) => doc.id);
    },

    async loadSettings(organizationId: string): Promise<ReplenishmentParameters> {
      const ref = db
        .collection('organizations')
        .doc(organizationId)
        .collection('replenishmentSettings')
        .doc('default');
      const snapshot = await ref.get();
      if (snapshot.exists) {
        return parseReplenishmentParameters(snapshot.data());
      }
      // First run for this organization: seed sensible defaults so the
      // settings screen (Flutter) has something real to read/edit, instead
      // of silently defaulting forever with nothing ever persisted.
      const now = Timestamp.now();
      await ref.set({
        ...DEFAULT_REPLENISHMENT_PARAMETERS,
        organizationId,
        createdAt: now,
        createdBy: 'system',
        updatedAt: now,
        updatedBy: 'system',
      });
      return DEFAULT_REPLENISHMENT_PARAMETERS;
    },

    async listVariantStockBalances(
      organizationId: string,
    ): Promise<ReadonlyArray<ReplenishmentVariantStockBalance>> {
      const snapshot = await db
        .collection('organizations')
        .doc(organizationId)
        .collection('inventory')
        .get();
      return snapshot.docs
        .map((doc) => asReplenishmentVariantStockBalance(doc.id, doc.data()))
        .filter(
          (balance): balance is ReplenishmentVariantStockBalance =>
            balance != null,
        );
    },

    async listStockTurnoverDailyFacts(
      organizationId: string,
      periodStart: Date,
      periodEnd: Date,
    ): Promise<ReadonlyArray<StockTurnoverDailyFact>> {
      const snapshot = await db
        .collection('organizations')
        .doc(organizationId)
        .collection('stockTurnoverDailyFacts')
        .where('dateAt', '>=', Timestamp.fromDate(periodStart))
        .where('dateAt', '<=', Timestamp.fromDate(periodEnd))
        .get();
      return snapshot.docs
        .map((doc) => asStockTurnoverDailyFact(doc.id, doc.data()))
        .filter((fact): fact is StockTurnoverDailyFact => fact != null);
    },

    async loadExistingSuggestionStatus(
      organizationId: string,
      documentId: string,
    ): Promise<string | null> {
      const snapshot = await db
        .collection('organizations')
        .doc(organizationId)
        .collection('replenishmentSuggestions')
        .doc(documentId)
        .get();
      if (!snapshot.exists) return null;
      return (snapshot.data()?.status as string | undefined) ?? null;
    },

    async saveSuggestion(
      organizationId: string,
      documentId: string,
      data: DocumentData,
    ): Promise<void> {
      await db
        .collection('organizations')
        .doc(organizationId)
        .collection('replenishmentSuggestions')
        .doc(documentId)
        .set(data);
    },
  };
}

/**
 * Weekly replenishment calculation (TASK-184, EPIC-27) — deliberately less
 * frequent than `../insights/generate-insights-scheduled.ts`'s daily cadence:
 * a purchasing decision does not need to be recomputed every day, and a
 * weekly cadence keeps `stockTurnoverDailyFacts` reads bounded per run.
 */
export const calculateReplenishmentSuggestions = onSchedule(
  {
    schedule: 'every monday 04:00',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',
  },
  async () => {
    await calculateReplenishmentSuggestionsScheduledHandler();
  },
);
