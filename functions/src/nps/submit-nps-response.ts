import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';

import { hashSecureToken } from '../shared/secure-token';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { formatMonthKey } from '../aggregations/aggregation-shared';
import {
  findNpsSurveyByTokenHash,
  npsCategoryOf,
  optionalComment,
  requireNonEmptyString,
  requireScore,
  resolveNpsSurveyOutcome,
} from './nps-shared';

export interface SubmitNpsResponseRequest extends RequestWithMeta {
  token?: string;
  score?: number;
  comment?: string;
}

export type SubmitNpsResponseOutcome =
  | 'accepted'
  | 'alreadyAnswered'
  | 'expired'
  | 'notFound';

export interface SubmitNpsResponseResponse {
  correlationId: string;
  outcome: SubmitNpsResponseOutcome;
}

/**
 * Public, unauthenticated submission of an NPS response (TASK-202, EPIC-30)
 * — same "sem exigir login complexo do cliente" contract as
 * `getNpsSurveyByToken`. A `pending` survey is answered exactly once: the
 * resulting `NpsResponse` document reuses the very same id as its
 * `NpsSurveyRequest` (1:1, `lookup.ref.id`), so a resubmission of the same
 * token after it was already answered can never create a second response —
 * it is instead rejected with `outcome: 'alreadyAnswered'` before any write
 * happens (checked *inside* the same transaction that would otherwise write
 * it, closing the same race a double-tap/retry could otherwise open).
 *
 * `NpsResponse.periodKey` (`YYYY-MM`, {@link formatMonthKey}) is stamped at
 * write time so `recomputeNpsMonthlyAggregates` can later query every
 * response of one company/month with a single equality-only query — no
 * date-range query, no composite index required (same "igualdade + igualdade
 * não precisa de índice novo" conclusion already documented by TASK-133's own
 * `listByPeriod`).
 */
export const submitNpsResponse = onCall<
  SubmitNpsResponseRequest,
  Promise<SubmitNpsResponseResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  const token = requireNonEmptyString(request.data?.token, 'token');
  const score = requireScore(request.data?.score);
  const comment = optionalComment(request.data?.comment);
  const tokenHash = hashSecureToken(token);

  const db = getFirestore();
  const now = Timestamp.now();

  const outcome = await db.runTransaction<SubmitNpsResponseOutcome>(async (transaction) => {
    const lookup = await findNpsSurveyByTokenHash(db, tokenHash, transaction);
    if (!lookup) return 'notFound';

    const surveyOutcome = resolveNpsSurveyOutcome(lookup.data, now);
    if (surveyOutcome === 'answered') return 'alreadyAnswered';
    if (surveyOutcome === 'expired') return 'expired';

    const periodKey = formatMonthKey(now.toDate());
    const responseRef = lookup.organizationRef
      .collection('npsResponses')
      .doc(lookup.ref.id);

    transaction.set(responseRef, {
      organizationId: lookup.data.organizationId,
      companyId: lookup.data.companyId,
      orderId: lookup.data.orderId,
      customerId: lookup.data.customerId,
      sellerId: lookup.data.sellerId,
      surveyRequestId: lookup.ref.id,
      score,
      comment,
      category: npsCategoryOf(score),
      periodKey,
      respondedAt: now,
    });
    transaction.update(lookup.ref, { status: 'answered', respondedAt: now });

    return 'accepted';
  });

  logger.info('submitNpsResponse completed', { correlationId, outcome });

  return { correlationId, outcome };
});
