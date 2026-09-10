import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import {
  FieldValue,
  Timestamp,
  getFirestore,
  type DocumentData,
} from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';
import {
  applyRestockMovements,
  isReturnEligibleOrderStatus,
  mapReturnRequestOrder,
  optionalString,
  resolveOrderStatusAfterApproval,
  resolveRestockPlans,
  type RestockableItem,
} from './return-shared';
import { appendPostSaleEvent } from '../after_sales/after-sales-shared';

/**
 * Only these roles may ever decide (aprovar/recusar) a `ReturnRequest`
 * (TASK-199, EPIC-30) — mirrors exactly `Capability.returnRequestApprove`'s
 * grant list in `lib/core/permissions/role_permission_matrix.dart`
 * (OWNER/ADMIN/SALES_MANAGER — the exact same set `decideOrderApproval`
 * already uses for `Capability.orderApprove`; SALES_REP/CUSTOMER_PORTAL may
 * *request* a devolução but never decide one).
 */
const ROLES_ALLOWED_TO_DECIDE_RETURN: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
]);

const DECIDABLE_STATUSES: ReadonlySet<string> = new Set<string>(['approved', 'rejected']);

export type ReturnRequestDecisionValue = 'approved' | 'rejected';

export interface ResolveReturnRequestRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  returnRequestId?: string;
  decision?: ReturnRequestDecisionValue;
  reason?: string;
}

export interface ResolveReturnRequestResponse {
  correlationId: string;
  returnRequestId: string;
  orderId: string;
  status: ReturnRequestDecisionValue;
  decidedBy: string;
  decidedAt: string;
  reason: string | null;
  resultingOrderStatus?: 'returned' | 'partiallyReturned';
}

/**
 * Idempotent Cloud Function deciding a `ReturnRequest` still `requested`
 * (TASK-199, EPIC-30) — the only place a devolução's stock/financial effect
 * is ever applied:
 *
 * - a rejection never touches stock or the pedido's own status at all
 *   (`tasks.md`: "Reposição de estoque e qualquer ajuste financeiro só
 *   ocorrem após aprovação formal, nunca automaticamente na simples
 *   solicitação");
 * - an approval reintegrates every returned quantity into the exact
 *   warehouse of origin denormalized on the order item at submission time
 *   (TASK-101/TASK-090), then drives the pedido's own `status` into
 *   `returned` (every original unit now covered by an approved devolução)
 *   or `partiallyReturned` (TASK-199) — both statuses `commission-shared.ts`
 *   already treats as `isReversalOrderStatus`, so this single write also
 *   triggers `calculateOrderCommissionOnWrite` and reverses the seller's
 *   commission for this pedido (EPIC-29), with no reversal logic duplicated
 *   here.
 *
 * Every decision (approve/reject) is recorded with author, timestamp and
 * motivo both on the `ReturnRequest.decisions` trail and on the order's own
 * `statusHistory`/`auditLogs` (`tasks.md`: "Toda decisão... é registrada com
 * autor, timestamp e motivo, na trilha de auditoria do pedido").
 */
export const resolveReturnRequest = onCall<
  ResolveReturnRequestRequest,
  Promise<ResolveReturnRequestResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para decidir uma devolução.',
    );
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
  const returnRequestId = requireNonEmptyString(request.data?.returnRequestId, 'returnRequestId');
  const decision = requireDecision(request.data?.decision);
  const reason = optionalString(request.data?.reason);
  if (decision === 'rejected' && !reason) {
    throw new HttpsError('invalid-argument', 'É necessário informar o motivo da recusa.');
  }

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_DECIDE_RETURN.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Seu perfil não pode decidir devoluções.');
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const returnRequestRef = organizationRef.collection('returnRequests').doc(returnRequestId);

  let requesterTeamIds: string[] = [];
  if (membership.roleName === 'SALES_MANAGER') {
    const requesterMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
    requesterTeamIds = normalizeTeamIds(requesterMemberSnapshot.data()?.teamIds);
  }

  const result = await db.runTransaction<ResolveReturnRequestResponse>(async (transaction) => {
    const returnRequestSnapshot = await transaction.get(returnRequestRef);
    const returnRequest = returnRequestSnapshot.data();
    if (!returnRequestSnapshot.exists || !returnRequest) {
      throw new HttpsError('failed-precondition', 'Devolução não encontrada.');
    }
    if (returnRequest.organizationId !== organizationId || returnRequest.companyId !== companyId) {
      throw new HttpsError(
        'failed-precondition',
        'Devolução não pertence à organização/empresa informada.',
      );
    }

    if (membership.roleName === 'SALES_MANAGER') {
      const sellerSnapshot = await transaction.get(
        organizationRef.collection('members').doc(returnRequest.sellerId as string),
      );
      const sellerTeamIds = normalizeTeamIds(sellerSnapshot.data()?.teamIds);
      const sharesTeam = sellerTeamIds.some((teamId) => requesterTeamIds.includes(teamId));
      if (!sharesTeam) {
        throw new HttpsError(
          'permission-denied',
          'Você só pode decidir devoluções da sua própria equipe.',
        );
      }
    }

    // Retry/double-tap of the very same decision — replays what is already
    // persisted, same idempotency precedent `decideOrderApproval` sets.
    if (returnRequest.status === decision) {
      return serializeDecision(returnRequestId, returnRequest, correlationId);
    }
    if (returnRequest.status !== 'requested') {
      throw new HttpsError(
        'failed-precondition',
        'Esta devolução já foi decidida e não pode ser decidida novamente.',
      );
    }

    const orderId = requireDataString(returnRequest.orderId, 'returnRequest.orderId');
    const orderRef = organizationRef.collection('orders').doc(orderId);
    const orderSnapshot = await transaction.get(orderRef);
    if (!orderSnapshot.exists) {
      throw new HttpsError('failed-precondition', 'Pedido original não encontrado.');
    }
    const order = mapReturnRequestOrder(orderId, orderSnapshot.data());

    const items = normalizeReturnRequestItems(returnRequest.items);
    const now = Timestamp.now();

    if (decision === 'rejected') {
      const decisionEntry = {
        decision: 'rejected',
        actorId: uid,
        actorName,
        reason,
        decidedAt: now,
      };
      transaction.update(returnRequestRef, {
        status: 'rejected',
        decisions: FieldValue.arrayUnion(decisionEntry),
        decidedBy: uid,
        decidedAt: now,
        decisionReason: reason,
        updatedAt: now,
        updatedBy: uid,
        version: FieldValue.increment(1),
      });
      transaction.set(organizationRef.collection('auditLogs').doc(), {
        organizationId,
        actorUserId: uid,
        actorName,
        action: 'return.rejected',
        entityType: 'order',
        entityId: orderId,
        previousValue: { returnRequestId, status: 'requested' },
        newValue: { returnRequestId, status: 'rejected', reason },
        timestamp: now,
      });
      // Links this decisão onto the pedido's own pós-venda timeline
      // (TASK-201, EPIC-30) — see `create-return-request.ts`'s own
      // `appendPostSaleEvent` call for `return_requested`.
      appendPostSaleEvent(transaction, organizationRef, {
        eventRef: organizationRef.collection('postSaleEvents').doc(),
        organizationId,
        companyId,
        orderId,
        orderNumber: order.orderNumber,
        customerId: order.customerId,
        sellerId: order.sellerId,
        type: 'return_resolved',
        description: reason
          ? `Devolução recusada (motivo: ${reason}).`
          : 'Devolução recusada.',
        source: 'system',
        sourceRequestId: returnRequestId,
        createdBy: uid,
        createdByName: actorName,
        now,
      });
      return {
        correlationId,
        returnRequestId,
        orderId,
        status: 'rejected',
        decidedBy: uid,
        decidedAt: now.toDate().toISOString(),
        reason: reason ?? null,
      };
    }

    if (!isReturnEligibleOrderStatus(order.status)) {
      throw new HttpsError(
        'failed-precondition',
        'Este pedido não está mais em um status elegível para devolução.',
      );
    }

    // Re-validates (server-side, inside this same transaction) that
    // approving this devolução never pushes a returned quantity above the
    // pedido's own original item quantity — a second safety net beyond
    // `createReturnRequest`'s own check, covering the (rare) race of two
    // overlapping devoluções approved concurrently.
    const otherReturnRequestsSnapshot = await transaction.get(
      organizationRef
        .collection('returnRequests')
        .where('orderId', '==', orderId)
        .where('status', '==', 'approved'),
    );
    const approvedByOrderItemId = sumApprovedQuantities(
      otherReturnRequestsSnapshot.docs
        .filter((doc) => doc.id !== returnRequestId)
        .map((doc) => doc.data()),
    );
    for (const item of items) {
      const orderItem = order.items.find((candidate) => candidate.id === item.orderItemId);
      if (!orderItem) continue;
      const alreadyApproved = approvedByOrderItemId.get(item.orderItemId) ?? 0;
      if (alreadyApproved + item.quantity > orderItem.quantity) {
        throw new HttpsError(
          'failed-precondition',
          `A devolução aprovada de outra solicitação já cobre a quantidade do item ` +
            `"${item.orderItemId}"; esta aprovação excederia a quantidade original do pedido.`,
        );
      }
      approvedByOrderItemId.set(item.orderItemId, alreadyApproved + item.quantity);
    }

    // ---- reads for stock reintegration (staged before any write) --------
    const restockPlans = await resolveRestockPlans(
      transaction,
      organizationRef,
      toRestockableItems(items),
    );

    // ---- writes -----------------------------------------------------------
    applyRestockMovements(transaction, restockPlans, {
      uid,
      now,
      source: 'return_request_approval',
    });

    const resultingOrderStatus = resolveOrderStatusAfterApproval(
      order.items,
      approvedByOrderItemId,
    );
    const orderStatusCode = resultingOrderStatus === 'returned' ? 'returned' : 'partially_returned';
    transaction.update(orderRef, {
      status: orderStatusCode,
      statusHistory: FieldValue.arrayUnion({
        previousStatus: order.status,
        newStatus: orderStatusCode,
        changedAt: now,
        actorId: uid,
        reason: `Devolução aprovada (${returnRequestId}).`,
      }),
      updatedAt: now,
      updatedBy: uid,
      version: FieldValue.increment(1),
    });

    const decisionEntry = {
      decision: 'approved',
      actorId: uid,
      actorName,
      reason: reason ?? null,
      decidedAt: now,
    };
    transaction.update(returnRequestRef, {
      status: 'approved',
      decisions: FieldValue.arrayUnion(decisionEntry),
      decidedBy: uid,
      decidedAt: now,
      decisionReason: reason ?? null,
      updatedAt: now,
      updatedBy: uid,
      version: FieldValue.increment(1),
    });

    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'return.approved',
      entityType: 'order',
      entityId: orderId,
      previousValue: { returnRequestId, status: 'requested', orderStatus: order.status },
      newValue: {
        returnRequestId,
        status: 'approved',
        orderStatus: orderStatusCode,
        refundAmount: typeof returnRequest.refundAmount === 'number' ? returnRequest.refundAmount : 0,
        reason: reason ?? null,
      },
      timestamp: now,
    });

    // Links this decisão onto the pedido's own pós-venda timeline
    // (TASK-201, EPIC-30) — see `create-return-request.ts`'s own
    // `appendPostSaleEvent` call for `return_requested`.
    appendPostSaleEvent(transaction, organizationRef, {
      eventRef: organizationRef.collection('postSaleEvents').doc(),
      organizationId,
      companyId,
      orderId,
      orderNumber: order.orderNumber,
      customerId: order.customerId,
      sellerId: order.sellerId,
      type: 'return_resolved',
      description: 'Devolução aprovada.',
      source: 'system',
      sourceRequestId: returnRequestId,
      createdBy: uid,
      createdByName: actorName,
      now,
    });

    return {
      correlationId,
      returnRequestId,
      orderId,
      status: 'approved',
      decidedBy: uid,
      decidedAt: now.toDate().toISOString(),
      reason: reason ?? null,
      resultingOrderStatus,
    };
  });

  logger.info('resolveReturnRequest succeeded', {
    correlationId,
    organizationId,
    companyId,
    returnRequestId,
    decision,
    uid,
    durationMs: Date.now() - startedAt,
  });

  return result;
});

interface NormalizedReturnItem {
  orderItemId: string;
  variantId: string;
  quantity: number;
  warehouseId: string | null;
}

function normalizeReturnRequestItems(value: unknown): NormalizedReturnItem[] {
  if (!Array.isArray(value)) return [];
  return value.map((item) => ({
    orderItemId: (item as DocumentData).orderItemId as string,
    variantId: (item as DocumentData).variantId as string,
    quantity: typeof (item as DocumentData).quantity === 'number' ? (item as DocumentData).quantity : 0,
    warehouseId: optionalString((item as DocumentData).warehouseId) ?? null,
  }));
}

function toRestockableItems(items: NormalizedReturnItem[]): RestockableItem[] {
  return items.map((item) => ({
    variantId: item.variantId,
    quantity: item.quantity,
    warehouseId: item.warehouseId,
  }));
}

function sumApprovedQuantities(approvedReturnRequests: DocumentData[]): Map<string, number> {
  const totals = new Map<string, number>();
  for (const returnRequest of approvedReturnRequests) {
    const items = Array.isArray(returnRequest.items) ? returnRequest.items : [];
    for (const item of items) {
      const orderItemId = item?.orderItemId as string | undefined;
      if (!orderItemId) continue;
      const quantity = typeof item?.quantity === 'number' ? item.quantity : 0;
      totals.set(orderItemId, (totals.get(orderItemId) ?? 0) + quantity);
    }
  }
  return totals;
}

function requireDecision(value: unknown): ReturnRequestDecisionValue {
  if (typeof value !== 'string' || !DECIDABLE_STATUSES.has(value)) {
    throw new HttpsError('invalid-argument', 'decision must be either "approved" or "rejected".');
  }
  return value as ReturnRequestDecisionValue;
}

function requireDataString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('internal', `Invalid return request record: ${field} is missing.`);
  }
  return value;
}

function normalizeTeamIds(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((entry): entry is string => typeof entry === 'string');
}

function serializeDecision(
  returnRequestId: string,
  data: DocumentData,
  correlationId: string,
): ResolveReturnRequestResponse {
  const status = data.status as string;
  if (status !== 'approved' && status !== 'rejected') {
    throw new HttpsError('internal', 'Invalid return request record for a decided devolução.');
  }
  const decidedAt = (data.decidedAt as Timestamp | undefined) ?? (data.updatedAt as Timestamp);
  return {
    correlationId,
    returnRequestId,
    orderId: data.orderId as string,
    status,
    decidedBy: (data.decidedBy as string | null) ?? '',
    decidedAt: decidedAt.toDate().toISOString(),
    reason: (data.decisionReason as string | null) ?? null,
  };
}
