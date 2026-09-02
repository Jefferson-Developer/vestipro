import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import {
  buildCustomerMonthlySnapshots,
  buildProductMonthlySnapshots,
  buildRegionMonthlySnapshots,
  buildSellerMonthlySnapshots,
} from './aggregation-builders';
import {
  createFirestoreAggregationDataSource,
  type AggregationDataSource,
} from './aggregation-data-source';
import { formatMonthKey, monthRange } from './aggregation-shared';

/**
 * Same allow-list already used by `recomputeStockTurnoverMetrics`
 * (`functions/src/inventory/recompute-stock-turnover-metrics.ts`) — manual
 * reprocessing of commercial aggregates is an operational/management action,
 * never available to SALES_ASSISTANT/FINANCE/READ_ONLY.
 */
const ROLES_ALLOWED_TO_RECOMPUTE: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
]);

/**
 * Batch strategy (documented trade-off, `tasks.md`/TASK-133): unlike
 * `salesDaily` (recomputed per-write, see
 * `recompute-sales-daily-on-order-write.ts`), the four "by dimension"
 * monthly aggregates join orders against customers/sellers/products and
 * fan out per line item — too expensive to redo on every single order
 * write as the month accumulates orders. They are instead fully recomputed
 * — never incrementally patched — for one company/month at a time, either
 * by the nightly schedule (current + previous month, every active
 * organization/company) or by this same function invoked as a callable for
 * manual/historical reprocessing (e.g. a data correction for a closed
 * month). Recompute is always a full overwrite keyed by
 * `${companyId}_${scopeId}_${periodKey}`, so re-running it for the same
 * month never duplicates or corrupts a snapshot — the idempotency this
 * task's own acceptance criteria requires.
 */
export async function recomputeMonthlyAggregatesForCompany(params: {
  organizationId: string;
  companyId: string;
  monthKey: string;
  dataSource: AggregationDataSource;
  generatedAt?: Timestamp;
}): Promise<{ generatedSnapshots: number }> {
  const generatedAt = params.generatedAt ?? Timestamp.now();
  const { start, end } = monthRange(params.monthKey);
  const facts = await params.dataSource.loadOrderFacts({
    organizationId: params.organizationId,
    companyId: params.companyId,
    start,
    end,
  });

  const customerIds = [...new Set(facts.map((fact) => fact.customerId))];
  const sellerIds = [...new Set(facts.map((fact) => fact.sellerId))];
  const productIds = [
    ...new Set(facts.flatMap((fact) => fact.items.map((item) => item.productId))),
  ];

  const [customerLabels, sellerLabels, productLabels] = await Promise.all([
    params.dataSource.loadCustomerLabels(params.organizationId, customerIds),
    params.dataSource.loadSellerLabels(params.organizationId, sellerIds),
    params.dataSource.loadProductLabels(params.organizationId, productIds),
  ]);

  const customerMonthly = buildCustomerMonthlySnapshots({
    organizationId: params.organizationId,
    monthKey: params.monthKey,
    facts,
    customerLabels,
    generatedAt,
  });
  const sellerMonthly = buildSellerMonthlySnapshots({
    organizationId: params.organizationId,
    monthKey: params.monthKey,
    facts,
    sellerLabels,
    generatedAt,
  });
  const regionMonthly = buildRegionMonthlySnapshots({
    organizationId: params.organizationId,
    monthKey: params.monthKey,
    facts,
    generatedAt,
  });
  const productMonthly = buildProductMonthlySnapshots({
    organizationId: params.organizationId,
    monthKey: params.monthKey,
    facts,
    productLabels,
    generatedAt,
  });

  await Promise.all([
    params.dataSource.upsertAggregates(
      params.organizationId,
      'customerMonthly',
      customerMonthly,
    ),
    params.dataSource.upsertAggregates(
      params.organizationId,
      'sellerMonthly',
      sellerMonthly,
    ),
    params.dataSource.upsertAggregates(
      params.organizationId,
      'regionMonthly',
      regionMonthly,
    ),
    params.dataSource.upsertAggregates(
      params.organizationId,
      'productMonthly',
      productMonthly,
    ),
  ]);

  return {
    generatedSnapshots:
      customerMonthly.length +
      sellerMonthly.length +
      regionMonthly.length +
      productMonthly.length,
  };
}

export interface RecomputeMonthlyAggregatesRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  monthKey?: string;
}

export interface RecomputeMonthlyAggregatesResponse {
  organizationId: string;
  monthKey: string;
  processedCompanyIds: string[];
  generatedSnapshots: number;
  generatedAt: string;
  correlationId: string;
}

export const recomputeMonthlyAggregates = onCall<
  RecomputeMonthlyAggregatesRequest,
  Promise<RecomputeMonthlyAggregatesResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para recalcular agregações comerciais.',
    );
  }

  const organizationId = requireNonEmptyString(
    request.data?.organizationId,
    'organizationId',
  );
  const monthKey = parseMonthKey(request.data?.monthKey);
  const requestedCompanyId =
    typeof request.data?.companyId === 'string' && request.data.companyId.trim()
      ? request.data.companyId.trim()
      : null;

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, request.auth.uid);
  if (!ROLES_ALLOWED_TO_RECOMPUTE.has(membership.roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Apenas OWNER/ADMIN/SALES_MANAGER podem recalcular agregações comerciais.',
    );
  }

  const dataSource = createFirestoreAggregationDataSource(db);
  const companyIds = requestedCompanyId
    ? [requestedCompanyId]
    : await dataSource.listActiveCompanyIds(organizationId);

  const generatedAt = Timestamp.now();
  let generatedSnapshots = 0;
  for (const companyId of companyIds) {
    const result = await recomputeMonthlyAggregatesForCompany({
      organizationId,
      companyId,
      monthKey,
      dataSource,
      generatedAt,
    });
    generatedSnapshots += result.generatedSnapshots;
  }

  logger.info('recomputeMonthlyAggregates completed', {
    correlationId,
    organizationId,
    monthKey,
    companyIds,
    generatedSnapshots,
  });

  return {
    organizationId,
    monthKey,
    processedCompanyIds: companyIds,
    generatedSnapshots,
    generatedAt: generatedAt.toDate().toISOString(),
    correlationId,
  };
});

export const recomputeMonthlyAggregatesScheduled = onSchedule(
  {
    schedule: 'every day 03:00',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',
  },
  async () => {
    await recomputeMonthlyAggregatesScheduledHandler();
  },
);

/**
 * Recomputes the current month and the previous month (never just the
 * current one) for every active organization/company, every night. The
 * one-month lookback exists because a seller in the field can
 * offline-submit an order that only syncs — and only then gets its
 * `createdAt`/status finalized server-side — a day or two after the
 * calendar month it commercially belongs to has already turned over; this
 * guarantees last month's totals still settle even after that late sync.
 */
export async function recomputeMonthlyAggregatesScheduledHandler(
  now: Date = new Date(),
): Promise<void> {
  const dataSource = createFirestoreAggregationDataSource();
  const organizationIds = await dataSource.listActiveOrganizationIds();
  const currentMonthKey = formatMonthKey(now);
  const previousMonthKey = formatMonthKey(
    new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 1, 1)),
  );

  for (const organizationId of organizationIds) {
    const companyIds = await dataSource.listActiveCompanyIds(organizationId);
    for (const companyId of companyIds) {
      for (const monthKey of [previousMonthKey, currentMonthKey]) {
        try {
          const result = await recomputeMonthlyAggregatesForCompany({
            organizationId,
            companyId,
            monthKey,
            dataSource,
          });
          logger.info('recomputeMonthlyAggregatesScheduled processed company', {
            organizationId,
            companyId,
            monthKey,
            generatedSnapshots: result.generatedSnapshots,
          });
        } catch (error) {
          // Isolation by job (`tasks.md`/TASK-133): one company/month
          // failing must never stop the loop for the rest of the tenant
          // base.
          logger.error('recomputeMonthlyAggregatesScheduled failed for company', {
            organizationId,
            companyId,
            monthKey,
            error: error instanceof Error ? error.message : String(error),
          });
        }
      }
    }
  }
}

function parseMonthKey(value: unknown): string {
  const raw = requireNonEmptyString(value, 'monthKey');
  if (!/^\d{4}-\d{2}$/.test(raw)) {
    throw new HttpsError('invalid-argument', 'monthKey deve estar no formato YYYY-MM.');
  }
  return raw;
}
