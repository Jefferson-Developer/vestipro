import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore, type DocumentData } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString, resolveActorName } from '../invites/invite-shared';
import {
  ROLES_ALLOWED_TO_CONVERT_BACKORDER,
  ensureRequesterMayActOnBackorder,
  mapReturnRequestOrder,
  normalizeTeamIds,
  type BackorderStatus,
} from './backorder-shared';
import type { ReturnRequestOrder } from '../returns/return-shared';

const CONVERTIBLE_STATUSES: ReadonlySet<BackorderStatus> = new Set<BackorderStatus>([
  'queued',
  'ready_to_fulfill',
]);

export interface ConvertBackorderToOrderRequest extends RequestWithMeta {
  organizationId?: string;
  backorderId?: string;
  orderId?: string;
}

export interface ConvertBackorderToOrderResponse {
  correlationId: string;
  backorderId: string;
  orderId: string;
  fulfilledQuantity: number;
  status: 'converted';
}

/**
 * Links an already-submitted, already-priced/stock/crédito-validated `Order`
 * (created through the existing "pedido em rascunho" → `submitOrder` flow,
 * TASK-096/TASK-101/TASK-088/TASK-212 — each already revalidating preço,
 * estoque, crédito e aprovação server-side at submission time) to a
 * `queued`/`ready_to_fulfill` `BackorderRequest` (TASK-215, EPIC-32), marking
 * it `converted`.
 *
 * This deliberately never re-implements order creation (branchId,
 * addresses, payment term, motor de precificação, movimentação de estoque):
 * doing so here would either duplicate `submitOrder`'s own business rules or
 * silently drift from them (`AGENTS.md`: não duplicar regra), exactly the
 * same scope decision `convertBuyerCollaborationSession` (TASK-211) already
 * documents for itself. `tasks.md`'s own "Conversão em pedido sempre revalida
 * preço, crédito, estoque e aprovação" is therefore satisfied by the pedido's
 * own submission having already happened through that unmodified pipeline —
 * this callable's only additional guarantee is that the linked pedido
 * genuinely covers the backorder's own remaining quantity for the exact same
 * produto/variante, never a mismatched or unrelated pedido.
 */
export const convertBackorderToOrder = onCall<
  ConvertBackorderToOrderRequest,
  Promise<ConvertBackorderToOrderResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'É necessário estar autenticado para converter um backorder.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const backorderId = requireNonEmptyString(request.data?.backorderId, 'backorderId');
  const orderId = requireNonEmptyString(request.data?.orderId, 'orderId');

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_CONVERT_BACKORDER.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Seu perfil não pode converter backorders.');
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const backorderRef = organizationRef.collection('backorders').doc(backorderId);
  const orderRef = organizationRef.collection('orders').doc(orderId);

  let requesterTeamIds: string[] = [];
  if (membership.roleName === 'SALES_MANAGER') {
    const requesterMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
    requesterTeamIds = normalizeTeamIds(requesterMemberSnapshot.data()?.teamIds);
  }

  const result = await db.runTransaction<ConvertBackorderToOrderResponse>(async (transaction) => {
    const backorderSnapshot = await transaction.get(backorderRef);
    const backorder = backorderSnapshot.data();
    if (!backorderSnapshot.exists || !backorder) {
      throw new HttpsError('not-found', 'Backorder não encontrado.');
    }
    if (backorder.organizationId !== organizationId) {
      throw new HttpsError('failed-precondition', 'Backorder não pertence à organização informada.');
    }
    if (!CONVERTIBLE_STATUSES.has(backorder.status as BackorderStatus)) {
      throw new HttpsError(
        'failed-precondition',
        'Somente backorders na fila (queued/ready_to_fulfill) podem ser convertidos.',
      );
    }

    let relatedOrder: ReturnRequestOrder | undefined;
    if (backorder.relatedOrderId) {
      const relatedOrderSnapshot = await transaction.get(
        organizationRef.collection('orders').doc(backorder.relatedOrderId),
      );
      if (relatedOrderSnapshot.exists) {
        relatedOrder = mapReturnRequestOrder(backorder.relatedOrderId, relatedOrderSnapshot.data());
      }
    }

    await ensureRequesterMayActOnBackorder(transaction, organizationRef, {
      roleName: membership.roleName,
      uid,
      sellerId: backorder.sellerId as string,
      customerId: backorder.customerId as string,
      requesterTeamIds,
      relatedOrder,
    });

    const orderSnapshot = await transaction.get(orderRef);
    const order = orderSnapshot.data();
    if (!orderSnapshot.exists || !order || order.deletedAt) {
      throw new HttpsError('failed-precondition', 'Pedido informado não foi encontrado.');
    }
    if (order.organizationId !== organizationId || order.customerId !== backorder.customerId) {
      throw new HttpsError(
        'failed-precondition',
        'O pedido informado não pertence a este cliente/organização.',
      );
    }

    const remainingQuantity =
      (backorder.quantity as number) - (typeof backorder.fulfilledQuantity === 'number' ? backorder.fulfilledQuantity : 0);
    const items = Array.isArray(order.items) ? (order.items as DocumentData[]) : [];
    const coveredQuantity = items
      .filter((item) => item.productId === backorder.productId && item.variantId === backorder.variantId)
      .reduce((sum, item) => sum + (typeof item.quantity === 'number' ? item.quantity : 0), 0);
    if (coveredQuantity < remainingQuantity) {
      throw new HttpsError(
        'failed-precondition',
        'O pedido informado não cobre a quantidade pendente deste backorder.',
      );
    }

    const now = Timestamp.now();
    const fulfilledQuantity = (typeof backorder.fulfilledQuantity === 'number' ? backorder.fulfilledQuantity : 0) + remainingQuantity;
    transaction.set(
      backorderRef,
      {
        status: 'converted',
        fulfilledQuantity,
        convertedOrderId: orderId,
        convertedAt: now,
        convertedBy: uid,
        updatedAt: now,
        updatedBy: uid,
        version: (typeof backorder.version === 'number' ? backorder.version : 1) + 1,
      },
      { merge: true },
    );

    if (backorder.sellerId !== uid) {
      transaction.set(organizationRef.collection('notifications').doc(), {
        organizationId,
        userId: backorder.sellerId,
        category: 'commercial',
        title: 'Backorder convertido em pedido',
        body: `A solicitação de estoque futuro do cliente foi convertida no pedido ${
          order.orderNumber ?? orderId
        }.`,
        deepLink: `/org/${organizationId}/companies/${order.companyId}/orders/${orderId}`,
        metadata: { backorderId, orderId },
        readAt: null,
        deliverAt: now,
        createdAt: now,
        createdBy: uid,
      });
    }

    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'backorder.converted',
      entityType: 'backorder',
      entityId: backorderId,
      previousValue: { status: backorder.status },
      newValue: { status: 'converted', orderId, fulfilledQuantity },
      timestamp: now,
    });

    return { correlationId, backorderId, orderId, fulfilledQuantity, status: 'converted' };
  });

  logger.info('convertBackorderToOrder succeeded', {
    correlationId,
    organizationId,
    backorderId,
    orderId,
    uid,
    durationMs: Date.now() - startedAt,
  });

  return result;
});
