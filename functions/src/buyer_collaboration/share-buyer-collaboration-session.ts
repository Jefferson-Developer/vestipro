import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import {
  assertSellerCanAct,
  buyerDeepLink,
  commentVisibilityFields,
  computeItemsTotal,
  effectiveStatus,
  findPortalRecipientUids,
  loadSessionOrThrow,
  notificationPayload,
  requireComment,
  requireSessionItems,
  sessionExpiresAt,
} from './buyer-collaboration-shared';

const SHAREABLE_STATUSES = new Set(['seller_draft', 'changes_requested']);

/**
 * Seller-only: hands a `seller_draft` session to the buyer for the first
 * time, or re-shares one that is `changes_requested` after revising items —
 * both transition to `buyer_review`. Optionally replaces the item snapshot
 * (`items`), so the same call covers "share as-is" and "share the revised
 * selection".
 */
export const shareBuyerCollaborationSession = onCall<
  RequestWithMeta & Record<string, unknown>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const uid = request.auth.uid;
  const organizationId = requireNonEmptyString(request.data.organizationId, 'organizationId');
  const sessionId = requireNonEmptyString(request.data.sessionId, 'sessionId');
  const note = requireComment(request.data.note, false);
  const rawItems = request.data.items;
  const items = rawItems === undefined ? null : requireSessionItems(rawItems);

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const { ref, data } = await loadSessionOrThrow(organizationRef, sessionId);
  assertSellerCanAct(membership.roleName, data, uid);

  const now = Timestamp.now();
  const status = effectiveStatus(data, now);
  if (!SHAREABLE_STATUSES.has(status)) {
    throw new HttpsError(
      'failed-precondition',
      'Esta sessão não está pronta para ser compartilhada com o comprador.',
    );
  }
  const isRevision = status === 'changes_requested';

  const update: Record<string, unknown> = {
    status: 'buyer_review',
    updatedAt: now,
    lastActivityAt: now,
    expiresAt: sessionExpiresAt(now),
  };
  if (items) {
    update.items = items;
    update.currentTotal = computeItemsTotal(items);
  }

  const batch = db.batch();
  batch.set(ref, update, { merge: true });
  if (note || isRevision) {
    batch.create(ref.collection('comments').doc(), {
      ...commentVisibilityFields(data),
      authorId: uid,
      authorType: 'seller',
      authorName: null,
      visibility: 'shared',
      itemId: null,
      kind: isRevision ? 'change_request' : 'comment',
      body: note ?? 'O vendedor revisou a seleção com base no que você pediu.',
      attachments: [],
      mentionedMemberIds: [],
      proposedChanges: null,
      createdAt: now,
    });
  }
  const recipientUids = await findPortalRecipientUids(db, organizationId, data.customerId as string);
  const notificationsRef = organizationRef.collection('notifications');
  recipientUids.forEach((recipientUid) => {
    batch.create(
      notificationsRef.doc(),
      notificationPayload({
        organizationId,
        userId: recipientUid,
        title: isRevision ? 'Seleção revisada disponível' : 'Nova seleção para revisar',
        body: note ?? 'O vendedor compartilhou itens para você revisar e aprovar.',
        deepLink: buyerDeepLink(organizationId, sessionId),
        entityId: sessionId,
        createdAt: now,
      }),
    );
  });
  await batch.commit();

  return { status: 'buyer_review', correlationId };
});
