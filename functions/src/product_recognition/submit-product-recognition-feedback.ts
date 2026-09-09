import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { requireNonEmptyString } from '../invites/invite-shared';
import { createFirestoreProductRecognitionDataSource } from './product-recognition-data-source';

export interface SubmitProductRecognitionFeedbackRequest extends RequestWithMeta {
  organizationId?: string;
  attemptId?: string;
  outcome?: string;
  matchedProductId?: string;
}

export interface SubmitProductRecognitionFeedbackResponse {
  success: true;
  correlationId: string;
}

/**
 * Records whether a `recognizeProductImage` attempt (TASK-191, EPIC-28)
 * actually matched what the seller was looking for — "era este"/"não era
 * nenhum" — the quality-tracking signal `tasks.md`/TASK-191 requires. Only
 * the same user who made the original attempt may answer it
 * ([attemptId]'s own `requestedBy`, re-checked here, never trusted from the
 * client), and only once: a second call for an already-answered attempt is
 * rejected instead of silently overwriting the first response, so quality
 * metrics are never double-counted or retroactively changed.
 */
export const submitProductRecognitionFeedback = onCall<
  SubmitProductRecognitionFeedbackRequest,
  Promise<SubmitProductRecognitionFeedbackResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para registrar este feedback.',
    );
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const attemptId = requireNonEmptyString(request.data?.attemptId, 'attemptId');
  const outcome = requireNonEmptyString(request.data?.outcome, 'outcome');
  if (outcome !== 'matched' && outcome !== 'noneMatched') {
    throw new HttpsError('invalid-argument', 'outcome deve ser "matched" ou "noneMatched".');
  }
  const matchedProductId =
    typeof request.data?.matchedProductId === 'string' &&
    request.data.matchedProductId.trim().length > 0
      ? request.data.matchedProductId.trim()
      : null;
  if (outcome === 'matched' && !matchedProductId) {
    throw new HttpsError(
      'invalid-argument',
      'matchedProductId é obrigatório quando outcome é "matched".',
    );
  }

  const db = getFirestore();
  const persistence = createFirestoreProductRecognitionDataSource(db);
  const attempt = await persistence.loadAttempt(organizationId, attemptId);
  if (!attempt || attempt.organizationId !== organizationId) {
    throw new HttpsError('not-found', 'Tentativa de reconhecimento não encontrada.');
  }
  if (attempt.requestedBy !== uid) {
    throw new HttpsError(
      'permission-denied',
      'Você só pode responder ao feedback da sua própria tentativa.',
    );
  }
  if (attempt.feedback != null) {
    throw new HttpsError(
      'failed-precondition',
      'O feedback desta tentativa já foi registrado anteriormente.',
    );
  }
  // Never accept a `matchedProductId` disconnected from what was actually
  // shown to the user — only one of the attempt's own candidates qualifies.
  if (
    matchedProductId &&
    !attempt.candidates.some((candidate) => candidate.productId === matchedProductId)
  ) {
    throw new HttpsError(
      'invalid-argument',
      'matchedProductId não corresponde a nenhum candidato apresentado nesta tentativa.',
    );
  }

  const respondedAt = Timestamp.now();
  await persistence.saveAttemptFeedback(organizationId, attemptId, {
    outcome,
    matchedProductId,
    respondedAt,
  });

  logger.info('submitProductRecognitionFeedback succeeded', {
    correlationId,
    organizationId,
    attemptId,
    outcome,
  });

  return { success: true, correlationId };
});
