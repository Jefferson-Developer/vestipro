import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import {
  asStockTurnoverDailyFact,
  buildMetricDocumentId,
  buildMetricSnapshot,
  type StockTurnoverDailyFact,
  type StockTurnoverScopeType,
} from './stock-turnover-shared';

export interface RecomputeStockTurnoverMetricsRequest extends RequestWithMeta {
  organizationId?: string;
  periodStart?: string;
  periodEnd?: string;
}

export interface RecomputeStockTurnoverMetricsResponse {
  organizationId: string;
  periodStart: string;
  periodEnd: string;
  generatedSnapshots: number;
  generatedAt: string;
  correlationId: string;
}

const ROLES_ALLOWED_TO_RECOMPUTE: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
]);

export const recomputeStockTurnoverMetrics = onCall<
  RecomputeStockTurnoverMetricsRequest,
  Promise<RecomputeStockTurnoverMetricsResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para recalcular métricas de estoque.',
    );
  }

  const organizationId = requireNonEmptyString(
    request.data?.organizationId,
    'organizationId',
  );
  const periodStart = parseDateInput(request.data?.periodStart, 'periodStart');
  const periodEnd = parseDateInput(request.data?.periodEnd, 'periodEnd');

  if (periodEnd < periodStart) {
    throw new HttpsError(
      'invalid-argument',
      'periodEnd deve ser igual ou posterior a periodStart.',
    );
  }

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, request.auth.uid);
  if (!ROLES_ALLOWED_TO_RECOMPUTE.has(membership.roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Apenas OWNER/ADMIN/SALES_MANAGER podem recalcular métricas de giro.',
    );
  }

  const organizationRef = db.collection('organizations').doc(organizationId);
  const factsSnapshot = await organizationRef
    .collection('stockTurnoverDailyFacts')
    .where('dateAt', '>=', Timestamp.fromDate(periodStart))
    .where('dateAt', '<=', Timestamp.fromDate(periodEnd))
    .get();

  const facts = factsSnapshot.docs
    .map((doc) => asStockTurnoverDailyFact(doc.id, doc.data()))
    .filter((fact): fact is StockTurnoverDailyFact => fact != null);

  const generatedAt = Timestamp.now();
  const snapshots = buildSnapshotsForAllScopes(
    organizationId,
    facts,
    periodStart,
    periodEnd,
    generatedAt,
  );

  let batch = db.batch();
  let pendingWrites = 0;
  for (const snapshot of snapshots) {
    const id = buildMetricDocumentId(
      snapshot.scopeType,
      snapshot.scopeId,
      snapshot.periodStart,
      snapshot.periodEnd,
    );
    batch.set(organizationRef.collection('stockTurnoverMetrics').doc(id), snapshot);
    pendingWrites += 1;
    if (pendingWrites >= 450) {
      await batch.commit();
      batch = db.batch();
      pendingWrites = 0;
    }
  }
  if (pendingWrites > 0) {
    await batch.commit();
  }

  logger.info('recomputeStockTurnoverMetrics completed', {
    correlationId,
    organizationId,
    periodStart: formatDateKey(periodStart),
    periodEnd: formatDateKey(periodEnd),
    generatedSnapshots: snapshots.length,
  });

  return {
    organizationId,
    periodStart: formatDateKey(periodStart),
    periodEnd: formatDateKey(periodEnd),
    generatedSnapshots: snapshots.length,
    generatedAt: generatedAt.toDate().toISOString(),
    correlationId,
  };
});

function buildSnapshotsForAllScopes(
  organizationId: string,
  facts: ReadonlyArray<StockTurnoverDailyFact>,
  periodStart: Date,
  periodEnd: Date,
  generatedAt: Timestamp,
) {
  const periodStartKey = formatDateKey(periodStart);
  const periodEndKey = formatDateKey(periodEnd);
  return [
    ...buildSnapshotsForScope(
      organizationId,
      facts,
      'product',
      (fact) => fact.productId,
      periodStartKey,
      periodEndKey,
      generatedAt,
    ),
    ...buildSnapshotsForScope(
      organizationId,
      facts,
      'variant',
      (fact) => fact.variantId,
      periodStartKey,
      periodEndKey,
      generatedAt,
    ),
    ...buildSnapshotsForScope(
      organizationId,
      facts,
      'collection',
      (fact) => fact.collectionId,
      periodStartKey,
      periodEndKey,
      generatedAt,
    ),
    ...buildSnapshotsForScope(
      organizationId,
      facts,
      'warehouse',
      (fact) => fact.warehouseId,
      periodStartKey,
      periodEndKey,
      generatedAt,
    ),
  ];
}

function buildSnapshotsForScope(
  organizationId: string,
  facts: ReadonlyArray<StockTurnoverDailyFact>,
  scopeType: StockTurnoverScopeType,
  scopeIdBuilder: (fact: StockTurnoverDailyFact) => string | null,
  periodStart: string,
  periodEnd: string,
  generatedAt: Timestamp,
) {
  const grouped = new Map<string, StockTurnoverDailyFact[]>();
  for (const fact of facts) {
    const scopeId = scopeIdBuilder(fact);
    if (!scopeId) {
      continue;
    }
    const current = grouped.get(scopeId) ?? [];
    current.push(fact);
    grouped.set(scopeId, current);
  }
  return [...grouped.entries()].map(([scopeId, scopeFacts]) =>
    buildMetricSnapshot({
      organizationId,
      scopeType,
      scopeId,
      periodStart,
      periodEnd,
      facts: scopeFacts,
      generatedAt,
    }),
  );
}

function parseDateInput(value: unknown, field: string): Date {
  const raw = requireNonEmptyString(value, field);
  const parsed = new Date(`${raw}T00:00:00.000Z`);
  if (Number.isNaN(parsed.getTime()) || formatDateKey(parsed) !== raw) {
    throw new HttpsError(
      'invalid-argument',
      `${field} deve estar no formato YYYY-MM-DD.`,
    );
  }
  return parsed;
}

function formatDateKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}

