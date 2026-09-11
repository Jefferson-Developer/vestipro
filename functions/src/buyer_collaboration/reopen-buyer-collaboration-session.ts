import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import {
  assertSellerCanAct,
  buyerDeepLink,
  commentVisibilityFields,
  effectiveStatus,
  findPortalRecipientUids,
  loadSessionOrThrow,
  notificationPayload,
  sessionExpiresAt,
} from './buyer-collaboration-shared';

/**
 * Seller-only: reabre uma sessão `expired`, devolvendo-a a `buyer_review`
 * com um novo prazo. `tasks.md`: "sessão expirada fica somente leitura e não
 * pode ser convertida sem reabertura autorizada" — a reabertura é sempre uma
 * ação explícita e auditável, nunca implícita.
 */
export const reopenBuyerCollaborationSession = onCall<
  RequestWithMeta & Record<string, unknown>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const uid = request.auth.uid;
  const organizationId = requireNonEmptyString(request.data.organizationId, 'organizationId');
  const sessionId = requireNonEmptyString(request.data.sessionId, 'sessionId');

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const { ref, data } = await loadSessionOrThrow(organizationRef, sessionId);
  assertSellerCanAct(membership.roleName, data, uid);

  const now = Timestamp.now();
  if (effectiveStatus(data, now) !== 'expired') {
    throw new HttpsError('failed-precondition', 'Esta sessão não está expirada.');
  }

  const batch = db.batch();
  batch.set(
    ref,
    {
      status: 'buyer_review',
      expiresAt: sessionExpiresAt(now),
      updatedAt: now,
      lastActivityAt: now,
    },
    { merge: true },
  );
  batch.create(ref.collection('comments').doc(), {
    ...commentVisibilityFields(data),
    authorId: uid,
    authorType: 'seller',
    authorName: null,
    visibility: 'shared',
    itemId: null,
    kind: 'system',
    body: 'O vendedor reabriu esta sessão de colaboração.',
    attachments: [],
    mentionedMemberIds: [],
    proposedChanges: null,
    createdAt: now,
  });
  const recipientUids = await findPortalRecipientUids(db, organizationId, data.customerId as string);
  const notificationsRef = organizationRef.collection('notifications');
  recipientUids.forEach((recipientUid) => {
    batch.create(
      notificationsRef.doc(),
      notificationPayload({
        organizationId,
        userId: recipientUid,
        title: 'Seleção reaberta para revisão',
        body: 'O vendedor reabriu esta seleção — dê uma olhada novamente.',
        deepLink: buyerDeepLink(organizationId, sessionId),
        entityId: sessionId,
        createdAt: now,
      }),
    );
  });
  await batch.commit();

  return { status: 'buyer_review', correlationId };
});
