import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore, Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';
import { mapPriceListItem } from '../pricing/calculate-pricing';
import {
  assertSellerCanAct,
  buyerDeepLink,
  commentVisibilityFields,
  effectiveStatus,
  findPortalRecipientUids,
  loadSessionOrThrow,
  notificationPayload,
  type BuyerCollaborationItem,
} from './buyer-collaboration-shared';

export interface PriceDriftDetail {
  itemId: string;
  variantId: string;
  approvedUnitPrice: number;
  currentUnitPrice: number | null;
}

/**
 * Seller-only: links an already-submitted, already-priced/stock-validated
 * `Order` (created through the existing `order draft` → `submitOrder`
 * flow — TASK-096/TASK-101, itself carrying its own server-side pricing
 * engine + stock consumption) to a `buyer_approved` collaboration session,
 * marking it `converted_to_order`.
 *
 * This deliberately never re-implements order creation (branchId, addresses,
 * payment term, full pricing engine, stock movements): that would either
 * duplicate `submitOrder`/`convertQuoteToOrder`'s own business rules or
 * silently drift from them. Instead, `tasks.md`'s "toda alteração proposta
 * precisa ser revalidada contra preço [...] no momento da conversão" is
 * enforced as a defense-in-depth check comparing the session's last
 * buyer-approved item prices (a live price-list re-read, not a stale
 * client-supplied value) against what the order actually recorded — a real
 * price drift between "buyer approved" and "seller converted" blocks the
 * conversion unless the seller explicitly acknowledges it
 * (`acceptPriceDrift`).
 */
export const convertBuyerCollaborationSession = onCall<
  RequestWithMeta & Record<string, unknown>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const uid = request.auth.uid;
  const organizationId = requireNonEmptyString(request.data.organizationId, 'organizationId');
  const sessionId = requireNonEmptyString(request.data.sessionId, 'sessionId');
  const orderId = requireNonEmptyString(request.data.orderId, 'orderId');
  const acceptPriceDrift = request.data.acceptPriceDrift === true;

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const { ref: sessionRef, data: session } = await loadSessionOrThrow(organizationRef, sessionId);
  assertSellerCanAct(membership.roleName, session, uid);

  const now = Timestamp.now();
  if (effectiveStatus(session, now) !== 'buyer_approved') {
    throw new HttpsError(
      'failed-precondition',
      'Esta sessão precisa estar aprovada pelo comprador antes de virar pedido.',
    );
  }
  if (session.convertedOrderId) {
    throw new HttpsError('already-exists', 'Esta sessão já foi convertida em pedido.');
  }

  const orderRef = organizationRef.collection('orders').doc(orderId);
  const orderSnapshot = await orderRef.get();
  const order = orderSnapshot.data();
  if (!orderSnapshot.exists || !order || order.deletedAt) {
    throw new HttpsError('failed-precondition', 'Pedido informado não foi encontrado.');
  }
  if (order.organizationId !== organizationId || order.customerId !== session.customerId) {
    throw new HttpsError(
      'failed-precondition',
      'O pedido informado não pertence a esta sessão de colaboração.',
    );
  }
  if (
    order.sellerId !== session.sellerId &&
    membership.roleName !== 'OWNER' &&
    membership.roleName !== 'ADMIN'
  ) {
    throw new HttpsError(
      'permission-denied',
      'O pedido deve ter sido enviado pelo vendedor responsável pela sessão.',
    );
  }

  const priceDrift = await detectPriceDrift(organizationRef, session);
  if (priceDrift.length > 0 && !acceptPriceDrift) {
    return {
      converted: false,
      priceDrift,
      correlationId,
    };
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const recipientUids = await findPortalRecipientUids(db, organizationId, session.customerId as string);
  await db.runTransaction(async (transaction) => {
    const freshSession = await transaction.get(sessionRef);
    const freshData = freshSession.data();
    if (!freshSession.exists || !freshData || freshData.status !== 'buyer_approved') {
      throw new HttpsError(
        'failed-precondition',
        'Esta sessão não está mais disponível para conversão.',
      );
    }
    const freshOrder = await transaction.get(orderRef);
    if (!freshOrder.exists || freshOrder.data()?.deletedAt) {
      throw new HttpsError('failed-precondition', 'Pedido informado não foi encontrado.');
    }
    transaction.set(
      sessionRef,
      {
        status: 'converted_to_order',
        convertedOrderId: orderId,
        updatedAt: now,
        lastActivityAt: now,
      },
      { merge: true },
    );
    transaction.create(sessionRef.collection('comments').doc(), {
      ...commentVisibilityFields(session),
      authorId: uid,
      authorType: 'seller',
      authorName: actorName,
      visibility: 'shared',
      itemId: null,
      kind: 'system',
      body: `Sessão convertida no pedido ${order.orderNumber ?? orderId}.`,
      attachments: [],
      mentionedMemberIds: [],
      proposedChanges: null,
      createdAt: now,
    });
    const notificationsRef = organizationRef.collection('notifications');
    recipientUids.forEach((recipientUid) => {
      transaction.create(notificationsRef.doc(), notificationPayload({
        organizationId,
        userId: recipientUid,
        title: 'Seleção convertida em pedido',
        body: `Seu pedido ${order.orderNumber ?? ''} foi criado a partir da seleção combinada.`,
        deepLink: buyerDeepLink(organizationId, sessionId),
        entityId: sessionId,
        createdAt: now,
      }));
    });
    transaction.create(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'buyerCollaborationSession.converted',
      entityType: 'buyerCollaborationSession',
      entityId: sessionId,
      previousValue: { status: 'buyer_approved' },
      newValue: { status: 'converted_to_order', orderId },
      timestamp: now,
    });
  });

  logger.info('convertBuyerCollaborationSession succeeded', {
    correlationId,
    organizationId,
    sessionId,
    orderId,
    priceDriftAccepted: priceDrift.length > 0,
    durationMs: Date.now() - startedAt,
  });
  return { converted: true, orderId, priceDrift, correlationId };
});

/**
 * Re-reads the session's `priceListId` items right now and compares each
 * session item's buyer-approved `unitPrice` to the current price-list price
 * for the same product/variant — the "preço [...] no momento da conversão"
 * revalidation. A variant no longer present in the price list is reported
 * with `currentUnitPrice: null` (treated by the caller as a drift, never
 * silently ignored).
 */
async function detectPriceDrift(
  organizationRef: FirebaseFirestore.DocumentReference,
  session: DocumentData,
): Promise<PriceDriftDetail[]> {
  const priceListId = session.priceListId as string | undefined;
  if (!priceListId) return [];
  const itemsSnapshot = await organizationRef
    .collection('priceLists')
    .doc(priceListId)
    .collection('items')
    .get();
  const currentByVariant = new Map<string, number>();
  itemsSnapshot.docs.forEach((doc) => {
    const item = mapPriceListItem(doc.data());
    if (item.variantId) currentByVariant.set(item.variantId, item.price);
  });
  const drifts: PriceDriftDetail[] = [];
  ((session.items as BuyerCollaborationItem[]) ?? []).forEach((item) => {
    const currentUnitPrice = currentByVariant.get(item.variantId) ?? null;
    if (currentUnitPrice === null || Math.abs(currentUnitPrice - item.unitPrice) > 0.01) {
      drifts.push({
        itemId: item.itemId,
        variantId: item.variantId,
        approvedUnitPrice: item.unitPrice,
        currentUnitPrice,
      });
    }
  });
  return drifts;
}
