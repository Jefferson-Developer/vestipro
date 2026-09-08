import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import { formatDayKey } from '../aggregations/aggregation-shared';
import {
  assertCanAccessDailyRepSummary,
  dailyRepSummaryRef,
} from './daily-rep-summary-shared';
import type {
  DailyRepSummaryReference,
  DailyRepSummaryStatus,
} from './daily-rep-summary-types';

export interface GetDailyRepSummaryRequest extends RequestWithMeta {
  organizationId?: string;
  sellerId?: string;
  /** `YYYY-MM-DD`; defaults to today (`America/Sao_Paulo`, the same fixed
   * schedule timezone `generateDailyRepSummary` runs on) when omitted —
   * `tasks.md`/TASK-188's own "consulta posterior no mesmo dia" history
   * requirement is what this parameter is for. */
  dateKey?: string;
}

export interface GetDailyRepSummaryResponse {
  /** `not_generated_yet` when `generateDailyRepSummary` has not (yet, or
   * ever, for this exact seller/day) produced an entry — a normal, expected
   * state before the daily schedule runs, never surfaced as an error
   * (`tasks.md`/TASK-188: "a ausência do resumo é um estado tratado"). */
  status: DailyRepSummaryStatus | 'not_generated_yet';
  summaryText: string | null;
  references: DailyRepSummaryReference[];
  dateKey: string;
  generatedAt: string | null;
  correlationId: string;
}

/**
 * Reads (never generates) TASK-188's "resumo diário do vendedor" for
 * [sellerId]/[dateKey] — the daily summary is always produced by the
 * `generateDailyRepSummary` schedule, never on demand by a client, so this
 * callable is a pure, cheap read of the persisted cache/history document
 * (`organizations/{organizationId}/dailyRepSummaries/{sellerId}_{dateKey}`),
 * gated by the same RBAC `generateWalletSummary`/`suggestApproach` already
 * establish (self, OWNER/ADMIN, or a SALES_MANAGER sharing a team with
 * [sellerId]).
 */
export const getDailyRepSummary = onCall<
  GetDailyRepSummaryRequest,
  Promise<GetDailyRepSummaryResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para consultar o resumo diário.',
    );
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const sellerId = requireNonEmptyString(request.data?.sellerId, 'sellerId');
  const dateKey = request.data?.dateKey?.trim() || formatDayKey(new Date());

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  await assertCanAccessDailyRepSummary({
    db,
    organizationId,
    requesterUid: uid,
    requesterRoleName: membership.roleName,
    sellerId,
  });

  const docSnapshot = await dailyRepSummaryRef(db, organizationId, sellerId, dateKey).get();
  const data = docSnapshot.data();
  if (!docSnapshot.exists || !data) {
    return {
      status: 'not_generated_yet',
      summaryText: null,
      references: [],
      dateKey,
      generatedAt: null,
      correlationId,
    };
  }

  logger.info('getDailyRepSummary served', {
    correlationId,
    organizationId,
    sellerId,
    dateKey,
    status: data.status,
  });

  return {
    status: data.status as DailyRepSummaryStatus,
    summaryText: (data.summaryText as string | null) ?? null,
    references: (data.references as DailyRepSummaryReference[] | null) ?? [],
    dateKey,
    generatedAt: toIso(data.generatedAt),
    correlationId,
  };
});

function toIso(value: unknown): string | null {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  return null;
}
