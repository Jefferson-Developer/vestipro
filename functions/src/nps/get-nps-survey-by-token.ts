import { onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';

import { hashSecureToken } from '../shared/secure-token';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  findNpsSurveyByTokenHash,
  requireNonEmptyString,
  resolveNpsSurveyOutcome,
  type NpsSurveyOutcome,
} from './nps-shared';

export interface GetNpsSurveyByTokenRequest extends RequestWithMeta {
  token?: string;
}

export interface GetNpsSurveyByTokenResponse {
  correlationId: string;
  outcome: NpsSurveyOutcome;
  organizationName: string | null;
  orderNumber: string | null;
  expiresAt: string | null;
}

/**
 * Public, unauthenticated preview of an NPS survey link (TASK-202, EPIC-30)
 * — same "sem exigir login complexo do cliente" contract TASK-081's
 * `getCatalogShareLink` already established, reusing the exact same
 * token/hash lookup shape (`findNpsSurveyByTokenHash`). Never throws for an
 * unknown/expired/answered token — always resolves to an [outcome] the
 * caller (`NpsResponsePage`) renders as a clear, friendly message, never a
 * raw technical error (same "nunca erro técnico cru" contract).
 *
 * Deliberately never exposes `organizationId`/`customerId`/`sellerId`/
 * `tokenHash`/internal ids — only what a customer answering their own
 * pesquisa needs to see: which organization it is from, which pedido it
 * refers to (by its human-readable number, never its id) and whether the
 * link can still be answered.
 */
export const getNpsSurveyByToken = onCall<
  GetNpsSurveyByTokenRequest,
  Promise<GetNpsSurveyByTokenResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  const token = requireNonEmptyString(request.data?.token, 'token');
  const tokenHash = hashSecureToken(token);

  const db = getFirestore();
  const lookup = await findNpsSurveyByTokenHash(db, tokenHash);
  if (!lookup) {
    return {
      correlationId,
      outcome: 'notFound',
      organizationName: null,
      orderNumber: null,
      expiresAt: null,
    };
  }

  const now = Timestamp.now();
  const outcome = resolveNpsSurveyOutcome(lookup.data, now);
  const organizationSnapshot = await lookup.organizationRef.get();
  const organizationName =
    typeof organizationSnapshot.data()?.name === 'string'
      ? (organizationSnapshot.data()?.name as string)
      : null;
  const expiresAt = lookup.data.expiresAt as Timestamp;
  const orderNumber =
    typeof lookup.data.orderNumber === 'string' ? lookup.data.orderNumber : null;

  return {
    correlationId,
    outcome,
    organizationName,
    orderNumber,
    expiresAt: expiresAt.toDate().toISOString(),
  };
});
