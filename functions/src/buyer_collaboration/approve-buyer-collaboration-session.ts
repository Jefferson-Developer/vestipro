import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { requireNonEmptyString, resolveActorName } from '../invites/invite-shared';
import {
  assertBuyerCanAct,
  commentVisibilityFields,
  effectiveStatus,
  loadSessionOrThrow,
  notificationPayload,
  requireComment,
  sellerDeepLink,
} from './buyer-collaboration-shared';

/**
 * Buyer-only: moves a `buyer_review` session to `buyer_approved`. This is a
 * commercial "de acordo" from the buyer, not an authorization — it never
 * substitutes internal discount/credit/policy approvals
 * (`tasks.md`: "aprovação do comprador não substitui aprovação comercial
 * interna"), which keep running on the pedido itself once
 * `convertBuyerCollaborationSession` creates it.
 */
export const approveBuyerCollaborationSession = onCall<
  RequestWithMeta & Record<string, unknown>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const uid = request.auth.uid;
  const organizationId = requireNonEmptyString(request.data.organizationId, 'organizationId');
  const sessionId = requireNonEmptyString(request.data.sessionId, 'sessionId');
  const comment = requireComment(request.data.comment, false);

  const db = getFirestore();
  const organizationRef = db.collection('organizations').doc(organizationId);
  const { ref, data } = await loadSessionOrThrow(organizationRef, sessionId);
  await assertBuyerCanAct(organizationId, uid, data);

  const now = Timestamp.now();
  if (effectiveStatus(data, now) !== 'buyer_review') {
    throw new HttpsError(
      'failed-precondition',
      'Esta sessão não está disponível para aprovação.',
    );
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const batch = db.batch();
  batch.set(
    ref,
    { status: 'buyer_approved', updatedAt: now, lastActivityAt: now },
    { merge: true },
  );
  batch.create(ref.collection('comments').doc(), {
    ...commentVisibilityFields(data),
    authorId: uid,
    authorType: 'buyer',
    authorName: actorName,
    visibility: 'shared',
    itemId: null,
    kind: 'system',
    body: comment ?? 'Comprador aprovou a seleção.',
    attachments: [],
    mentionedMemberIds: [],
    proposedChanges: null,
    createdAt: now,
  });
  batch.create(organizationRef.collection('notifications').doc(), notificationPayload({
    organizationId,
    userId: data.sellerId as string,
    title: 'Comprador aprovou a seleção',
    body: comment ?? 'A seleção foi aprovada e está pronta para virar pedido.',
    deepLink: sellerDeepLink(organizationId, sessionId),
    entityId: sessionId,
    createdAt: now,
  }));
  await batch.commit();

  return { status: 'buyer_approved', correlationId };
});
