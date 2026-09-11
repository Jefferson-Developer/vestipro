import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';
import {
  BUYER_COLLABORATION_SELLER_ROLES,
  assertBuyerCanAct,
  buyerDeepLink,
  commentVisibilityFields,
  effectiveStatus,
  findPortalRecipientUids,
  loadSessionOrThrow,
  notificationPayload,
  requireAttachments,
  requireComment,
  sellerDeepLink,
} from './buyer-collaboration-shared';

const COMMENTABLE_STATUSES = new Set([
  'seller_draft',
  'buyer_review',
  'changes_requested',
  'buyer_approved',
]);

/**
 * Adds one comment (general or scoped to a single item) to a collaboration
 * session's history — usable by the seller/internal team (who may also mark
 * a comment `internal`, visible only to their own organization, and mention
 * teammates) or by the buyer's own CUSTOMER_PORTAL membership (always
 * `shared`, only ever notifying the seller). Every comment carries authorship
 * and a timestamp; nothing is ever edited/removed after being written — the
 * subcollection itself is the audit trail (`tasks.md`: "trilha de autoria,
 * timestamp e visibilidade").
 */
export const addBuyerCollaborationComment = onCall<
  RequestWithMeta & Record<string, unknown>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const uid = request.auth.uid;
  const organizationId = requireNonEmptyString(request.data.organizationId, 'organizationId');
  const sessionId = requireNonEmptyString(request.data.sessionId, 'sessionId');
  const body = requireComment(request.data.body, true)!;
  const itemId =
    typeof request.data.itemId === 'string' && request.data.itemId.trim().length > 0
      ? request.data.itemId.trim()
      : null;
  const attachments = requireAttachments(request.data.attachments);
  const requestedVisibility = request.data.visibility === 'internal' ? 'internal' : 'shared';
  const mentionedMemberIds = Array.isArray(request.data.mentionedMemberIds)
    ? request.data.mentionedMemberIds.filter(
        (value): value is string => typeof value === 'string' && value.trim().length > 0,
      )
    : [];

  const db = getFirestore();
  const organizationRef = db.collection('organizations').doc(organizationId);
  const { ref, data } = await loadSessionOrThrow(organizationRef, sessionId);
  const now = Timestamp.now();
  const status = effectiveStatus(data, now);
  if (!COMMENTABLE_STATUSES.has(status)) {
    throw new HttpsError(
      'failed-precondition',
      'Esta sessão de colaboração não aceita novos comentários.',
    );
  }
  if (itemId && !(data.items as { itemId: string }[]).some((item) => item.itemId === itemId)) {
    throw new HttpsError('invalid-argument', 'itemId não pertence a esta sessão.');
  }

  let membership: { roleName: string } | null = null;
  try {
    membership = await loadActiveMembership(db, organizationId, uid);
  } catch {
    membership = null;
  }
  const isInternal = membership !== null && BUYER_COLLABORATION_SELLER_ROLES.has(membership.roleName);
  let authorType: 'seller' | 'buyer';
  let visibility: 'shared' | 'internal';
  let notifyRecipientUids: string[];
  let deepLink: string;
  if (isInternal) {
    if (status === 'seller_draft' && data.sellerId !== uid && membership!.roleName === 'SALES_REP') {
      throw new HttpsError('permission-denied', 'Apenas o vendedor responsável pode comentar.');
    }
    authorType = 'seller';
    visibility = requestedVisibility;
    notifyRecipientUids =
      visibility === 'shared'
        ? await findPortalRecipientUids(db, organizationId, data.customerId as string)
        : [];
    deepLink = buyerDeepLink(organizationId, sessionId);
  } else {
    if (status === 'seller_draft') {
      throw new HttpsError(
        'failed-precondition',
        'Esta seleção ainda não foi compartilhada com você.',
      );
    }
    await assertBuyerCanAct(organizationId, uid, data);
    authorType = 'buyer';
    visibility = 'shared';
    notifyRecipientUids = [data.sellerId as string];
    deepLink = sellerDeepLink(organizationId, sessionId);
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const batch = db.batch();
  batch.create(ref.collection('comments').doc(), {
    ...commentVisibilityFields(data),
    authorId: uid,
    authorType,
    authorName: actorName,
    visibility,
    itemId,
    kind: 'comment',
    body,
    attachments,
    mentionedMemberIds: isInternal ? mentionedMemberIds : [],
    proposedChanges: null,
    createdAt: now,
  });
  batch.set(ref, { lastActivityAt: now, updatedAt: now }, { merge: true });
  const notificationsRef = organizationRef.collection('notifications');
  notifyRecipientUids.forEach((recipientUid) => {
    batch.create(
      notificationsRef.doc(),
      notificationPayload({
        organizationId,
        userId: recipientUid,
        title: authorType === 'buyer' ? 'Novo comentário do comprador' : 'Novo comentário na seleção',
        body,
        deepLink,
        entityId: sessionId,
        createdAt: now,
      }),
    );
  });
  await batch.commit();

  return { visibility, correlationId };
});
