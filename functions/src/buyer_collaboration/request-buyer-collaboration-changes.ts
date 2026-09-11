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
  requireProposedChanges,
  sellerDeepLink,
} from './buyer-collaboration-shared';

/**
 * Buyer-only: moves a `buyer_review` session to `changes_requested`,
 * recording the request as a `change_request` comment (free-text plus an
 * optional structured `proposedChanges` list the seller's UI can render as
 * quantity/removal/addition suggestions). Never mutates `items` itself —
 * only the seller, via `shareBuyerCollaborationSession`, applies a revision
 * and hands it back (`tasks.md`: "a conversão em pedido continua passando
 * pelo vendedor/fluxo de aprovação").
 */
export const requestBuyerCollaborationChanges = onCall<
  RequestWithMeta & Record<string, unknown>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const uid = request.auth.uid;
  const organizationId = requireNonEmptyString(request.data.organizationId, 'organizationId');
  const sessionId = requireNonEmptyString(request.data.sessionId, 'sessionId');
  const comment = requireComment(request.data.comment, true)!;
  const proposedChanges = requireProposedChanges(request.data.proposedChanges);

  const db = getFirestore();
  const organizationRef = db.collection('organizations').doc(organizationId);
  const { ref, data } = await loadSessionOrThrow(organizationRef, sessionId);
  await assertBuyerCanAct(organizationId, uid, data);

  const now = Timestamp.now();
  if (effectiveStatus(data, now) !== 'buyer_review') {
    throw new HttpsError(
      'failed-precondition',
      'Esta sessão não está disponível para solicitar alterações.',
    );
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const batch = db.batch();
  batch.set(
    ref,
    { status: 'changes_requested', updatedAt: now, lastActivityAt: now },
    { merge: true },
  );
  batch.create(ref.collection('comments').doc(), {
    ...commentVisibilityFields(data),
    authorId: uid,
    authorType: 'buyer',
    authorName: actorName,
    visibility: 'shared',
    itemId: null,
    kind: 'change_request',
    body: comment,
    attachments: [],
    mentionedMemberIds: [],
    proposedChanges: proposedChanges.length > 0 ? proposedChanges : null,
    createdAt: now,
  });
  batch.create(organizationRef.collection('notifications').doc(), notificationPayload({
    organizationId,
    userId: data.sellerId as string,
    title: 'Comprador solicitou alterações',
    body: comment,
    deepLink: sellerDeepLink(organizationId, sessionId),
    entityId: sessionId,
    createdAt: now,
  }));
  await batch.commit();

  return { status: 'changes_requested', correlationId };
});
