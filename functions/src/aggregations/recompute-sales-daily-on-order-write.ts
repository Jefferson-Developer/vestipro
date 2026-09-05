import { logger } from 'firebase-functions/v2';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { Timestamp, type DocumentData } from 'firebase-admin/firestore';

import {
  buildSalesDailySnapshots,
  buildSellerDailySnapshots,
} from './aggregation-builders';
import {
  createFirestoreAggregationDataSource,
  type AggregationDataSource,
} from './aggregation-data-source';
import { dayRange, formatDayKey } from './aggregation-shared';

export interface AffectedSalesDay {
  organizationId: string;
  companyId: string;
  dayKey: string;
}

/**
 * Reads the `organizationId`/`companyId`/`createdAt` that identify the
 * `salesDaily` bucket a write to `organizations/{orgId}/orders/{orderId}`
 * belongs to. Prefers `after` (create/update); falls back to `before` so a
 * hard delete of an order still triggers a recompute of the day it used to
 * belong to (its removal must disappear from that day's snapshot too).
 * Returns `null` for malformed documents — nothing to recompute.
 */
export function resolveAffectedSalesDay(
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): AffectedSalesDay | null {
  const data = after ?? before;
  if (
    !data ||
    typeof data.organizationId !== 'string' ||
    typeof data.companyId !== 'string' ||
    !(data.createdAt instanceof Timestamp)
  ) {
    return null;
  }
  return {
    organizationId: data.organizationId,
    companyId: data.companyId,
    dayKey: formatDayKey(data.createdAt.toDate()),
  };
}

/**
 * Near-real-time strategy (documented trade-off, `tasks.md`/TASK-133): on
 * every write to an order, fully recompute — never incrementally patch —
 * the single `salesDaily` snapshot for the day that order belongs to. A
 * targeted, single-day recompute is cheap (a handful of orders in the
 * common case) and self-healing/idempotent (re-running it for the same day
 * always reproduces the exact same totals from the orders that exist right
 * now), at the cost of one Firestore read of that day's orders per order
 * write — acceptable because `salesDaily` is the one dimension a live
 * "today" widget needs to feel instantaneous. `customerMonthly`/
 * `productMonthly`/`sellerMonthly`/`regionMonthly` intentionally do **not**
 * follow this per-write strategy (see `recompute-monthly-aggregates.ts`):
 * recomputing a full month on every single order write would grow
 * unboundedly expensive as the month fills up, so those four are batch/
 * scheduled instead, trading a bit of staleness (up to the schedule's
 * interval) for bounded cost.
 */
export async function recomputeSalesDailyForOrderChange(
  affected: AffectedSalesDay,
  dataSource: AggregationDataSource,
  generatedAt: Timestamp = Timestamp.now(),
): Promise<void> {
  const { start, end } = dayRange(affected.dayKey);
  const facts = await dataSource.loadOrderFacts({
    organizationId: affected.organizationId,
    companyId: affected.companyId,
    start,
    end,
  });
  const snapshots = buildSalesDailySnapshots({
    organizationId: affected.organizationId,
    dayKey: affected.dayKey,
    facts,
    generatedAt,
  });
  const sellerSnapshots = buildSellerDailySnapshots({
    organizationId: affected.organizationId,
    dayKey: affected.dayKey,
    facts,
    generatedAt,
  });
  await Promise.all([
    dataSource.upsertAggregates(
      affected.organizationId,
      'salesDaily',
      snapshots,
    ),
    dataSource.upsertAggregates(
      affected.organizationId,
      'sellerDaily',
      sellerSnapshots,
    ),
  ]);
}

export const recomputeSalesDailyOnOrderWrite = onDocumentWritten(
  'organizations/{organizationId}/orders/{orderId}',
  async (event) => {
    const affected = resolveAffectedSalesDay(
      event.data?.before.data(),
      event.data?.after.data(),
    );
    if (!affected) {
      return;
    }
    const startedAt = Date.now();
    try {
      await recomputeSalesDailyForOrderChange(
        affected,
        createFirestoreAggregationDataSource(),
      );
      logger.info('recomputeSalesDailyOnOrderWrite completed', {
        organizationId: affected.organizationId,
        companyId: affected.companyId,
        dayKey: affected.dayKey,
        durationMs: Date.now() - startedAt,
      });
    } catch (error) {
      // A failure recomputing salesDaily must never block the order write
      // itself (already committed) nor any other aggregation job — logged
      // and swallowed, same isolation-by-job guarantee `tasks.md`/TASK-133
      // requires ("Falha em uma função de agregação não pode travar as
      // demais").
      logger.error('recomputeSalesDailyOnOrderWrite failed', {
        organizationId: affected.organizationId,
        companyId: affected.companyId,
        dayKey: affected.dayKey,
        durationMs: Date.now() - startedAt,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  },
);
