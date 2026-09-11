import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import {
  BUYER_COLLABORATION_SELLER_ROLES,
  BUYER_COLLABORATION_SOURCE_TYPES,
  computeItemsTotal,
  requireSessionItems,
  sessionExpiresAt,
  type BuyerCollaborationSourceType,
} from './buyer-collaboration-shared';

/**
 * Seller-only: opens a new collaboration session (`seller_draft`) wrapping a
 * snapshot of items taken from a cart draft, quote, pre-book draft or order
 * draft (`sourceType`/`sourceId`). Nothing is visible to the buyer yet —
 * `shareBuyerCollaborationSession` is the action that hands it over.
 */
export const createBuyerCollaborationSession = onCall<
  RequestWithMeta & Record<string, unknown>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const uid = request.auth.uid;
  const organizationId = requireNonEmptyString(request.data.organizationId, 'organizationId');
  const companyId = requireNonEmptyString(request.data.companyId, 'companyId');
  const customerId = requireNonEmptyString(request.data.customerId, 'customerId');
  const priceListId = requireNonEmptyString(request.data.priceListId, 'priceListId');
  const sourceType = request.data.sourceType;
  if (
    typeof sourceType !== 'string' ||
    !BUYER_COLLABORATION_SOURCE_TYPES.has(sourceType)
  ) {
    throw new HttpsError('invalid-argument', 'sourceType é inválido.');
  }
  const sourceId = requireNonEmptyString(request.data.sourceId, 'sourceId');
  const showPrices = request.data.showPrices !== false;
  const items = requireSessionItems(request.data.items);

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!BUYER_COLLABORATION_SELLER_ROLES.has(membership.roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil não pode iniciar uma colaboração com comprador.',
    );
  }

  const organizationRef = db.collection('organizations').doc(organizationId);
  const customerSnapshot = await organizationRef.collection('customers').doc(customerId).get();
  const customerData = customerSnapshot.data();
  if (!customerSnapshot.exists || !customerData) {
    throw new HttpsError('failed-precondition', 'Cliente não encontrado.');
  }
  if (customerData.companyId && customerData.companyId !== companyId) {
    throw new HttpsError(
      'failed-precondition',
      'Cliente não pertence à empresa informada.',
    );
  }

  const now = Timestamp.now();
  const ref = organizationRef.collection('buyerCollaborationSessions').doc();
  await ref.set({
    organizationId,
    companyId,
    sellerId: uid,
    customerId,
    sourceType: sourceType as BuyerCollaborationSourceType,
    sourceId,
    priceListId,
    status: 'seller_draft',
    items,
    showPrices,
    currentTotal: computeItemsTotal(items),
    convertedOrderId: null,
    createdBy: uid,
    createdAt: now,
    updatedAt: now,
    lastActivityAt: now,
    expiresAt: sessionExpiresAt(now),
    deletedAt: null,
  });

  return {
    sessionId: ref.id,
    status: 'seller_draft',
    correlationId,
  };
});
