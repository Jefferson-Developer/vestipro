import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { hashSecureToken } from '../shared/secure-token';
import { findCartShare, outcome, requiredString, type CartReviewDecision } from './cart-share-shared';

export const reviewCartShare = onCall<RequestWithMeta & Record<string, unknown>>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  const tokenHash = hashSecureToken(requiredString(request.data?.token, 'token'));
  const decision = request.data?.decision;
  if (decision !== 'approved' && decision !== 'changesRequested') {
    throw new HttpsError('invalid-argument', 'decision is invalid.');
  }
  const comment = typeof request.data.comment === 'string' ? request.data.comment.trim() : '';
  if (comment.length > 1000 || (decision === 'changesRequested' && comment.length === 0)) {
    throw new HttpsError('invalid-argument', 'A comment up to 1000 characters is required for changes.');
  }
  const rejectedItemIds = Array.isArray(request.data.rejectedItemIds)
    ? request.data.rejectedItemIds.map((id) => requiredString(id, 'rejectedItemIds[]')) : [];
  const db = getFirestore();
  const found = await findCartShare(db, tokenHash);
  if (!found || outcome(found.data, Timestamp.now()) !== 'valid') {
    throw new HttpsError('failed-precondition', 'This cart share is not available.');
  }
  const validItemIds = new Set(((found.data.items as Record<string, unknown>[]) ?? []).map((item) => item.itemId));
  if (rejectedItemIds.some((id) => !validItemIds.has(id))) {
    throw new HttpsError('invalid-argument', 'A rejected item is outside this shared cart.');
  }
  const reviewedAt = Timestamp.now();
  const review = { decision: decision as CartReviewDecision, comment: comment || null, rejectedItemIds, reviewedAt };
  const notificationRef = found.organizationRef.collection('notifications').doc();
  const batch = db.batch();
  batch.update(found.ref, { review, updatedAt: reviewedAt });
  batch.create(notificationRef, {
    organizationId: found.organizationRef.id,
    userId: found.data.createdBy,
    category: 'commercial',
    priority: 'informative',
    title: decision === 'approved' ? 'Carrinho aprovado pelo cliente' : 'Cliente sugeriu alterações',
    body: comment || 'A seleção compartilhada foi revisada.',
    deepLink: `/org/${found.organizationRef.id}/orders/draft?draftId=${found.data.sourceCartId}`,
    entityId: found.ref.id,
    createdAt: reviewedAt,
    readAt: null,
    deliverAt: null,
  });
  await batch.commit();
  // Deliberately does not create/update any `orders` document. The seller remains
  // responsible for final submission and server-side stock/pricing validation.
  return { reviewed: true, decision, correlationId };
});
