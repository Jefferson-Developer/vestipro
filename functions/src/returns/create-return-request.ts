import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore, type DocumentData } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';
import { appendPostSaleEvent } from '../after_sales/after-sales-shared';
import {
  ensureRequesterMayActOnOrder,
  isReturnEligibleOrderStatus,
  mapReturnRequestOrder,
  normalizeTeamIds,
  optionalString,
  requireReasonCategory,
  requireString,
  roundMoney,
  type ReturnReasonCategory,
  type ReturnRequestOrder,
} from './return-shared';

/**
 * Only these roles may ever request a devolução for a pedido (TASK-199,
 * EPIC-30) — mirrors exactly `Capability.returnRequestCreate`'s grant list
 * in `lib/core/permissions/role_permission_matrix.dart` (OWNER/ADMIN/
 * SALES_MANAGER/SALES_REP/CUSTOMER_PORTAL; SALES_ASSISTANT/FINANCE/
 * READ_ONLY never get it). Re-checked here from the caller's real
 * Membership — never trusted from the client, same rule every other
 * Function in this codebase already follows.
 */
const ROLES_ALLOWED_TO_REQUEST_RETURN: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
  'SALES_REP',
  'CUSTOMER_PORTAL',
]);

const MAX_EVIDENCE_URLS = 5;
const MAX_REASON_DETAILS_LENGTH = 1000;

export interface CreateReturnRequestItemInput {
  orderItemId?: string;
  quantity?: number;
}

export interface CreateReturnRequestRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  orderId?: string;
  returnRequestId?: string;
  items?: CreateReturnRequestItemInput[];
  reasonCategory?: ReturnReasonCategory;
  reasonDetails?: string;
  evidenceUrls?: string[];
}

export interface CreateReturnRequestResponseItem {
  orderItemId: string;
  productId: string;
  variantId: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;
}

export interface CreateReturnRequestResponse {
  correlationId: string;
  returnRequestId: string;
  orderId: string;
  status: 'requested';
  reasonCategory: ReturnReasonCategory;
  items: CreateReturnRequestResponseItem[];
  refundAmount: number;
  requestedAt: string;
}

interface NormalizedItemInput {
  orderItemId: string;
  quantity: number;
}

/**
 * Idempotent Cloud Function opening a `ReturnRequest` (TASK-199, EPIC-30)
 * against an already-fulfilled pedido: revalidates every item/quantity
 * against the order's own persisted `items` (never the client's own
 * recollection of them) and the categorized [reasonCategory] — a devolução
 * never applies any stock/financial effect by itself (`tasks.md`: "Reposição
 * de estoque e qualquer ajuste financeiro só ocorrem após aprovação
 * formal"); that only happens later, in `resolveReturnRequest`.
 *
 * [CreateReturnRequestRequest.returnRequestId] is the client-generated
 * idempotency key *and* the resulting document id — a resubmission (double
 * tap, retry after a dropped response) always carries the very same id, so
 * it can never open a second devolução for one seller/cliente intent, same
 * precedent `submitOrder`'s own `orderId` already sets.
 */
export const createReturnRequest = onCall<
  CreateReturnRequestRequest,
  Promise<CreateReturnRequestResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para solicitar uma devolução.',
    );
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
  const orderId = requireNonEmptyString(request.data?.orderId, 'orderId');
  const returnRequestId = requireNonEmptyString(request.data?.returnRequestId, 'returnRequestId');
  const reasonCategory = requireReasonCategory(request.data?.reasonCategory);
  const reasonDetails = requireOptionalBoundedString(
    request.data?.reasonDetails,
    'reasonDetails',
    MAX_REASON_DETAILS_LENGTH,
  );
  const evidenceUrls = requireEvidenceUrls(request.data?.evidenceUrls);
  const items = requireItems(request.data?.items);

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_REQUEST_RETURN.has(membership.roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil não pode solicitar devoluções.',
    );
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const orderRef = organizationRef.collection('orders').doc(orderId);
  const returnRequestRef = organizationRef.collection('returnRequests').doc(returnRequestId);

  let portalCustomerId: string | undefined;
  let requesterTeamIds: string[] = [];
  if (membership.roleName === 'CUSTOMER_PORTAL') {
    const portalMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
    portalCustomerId = optionalString(portalMemberSnapshot.data()?.customerId);
  } else if (membership.roleName === 'SALES_MANAGER') {
    const requesterMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
    requesterTeamIds = normalizeTeamIds(requesterMemberSnapshot.data()?.teamIds);
  }

  const result = await db.runTransaction<CreateReturnRequestResponse>(async (transaction) => {
    const existingSnapshot = await transaction.get(returnRequestRef);
    if (existingSnapshot.exists) {
      const existing = existingSnapshot.data();
      if (!existing) throw new HttpsError('internal', 'Invalid return request record.');
      return serializeReturnRequest(returnRequestId, existing, correlationId);
    }

    const orderSnapshot = await transaction.get(orderRef);
    if (!orderSnapshot.exists) {
      throw new HttpsError('failed-precondition', 'Pedido não encontrado.');
    }
    const order = mapReturnRequestOrder(orderId, orderSnapshot.data());
    if (order.organizationId !== organizationId || order.companyId !== companyId) {
      throw new HttpsError(
        'failed-precondition',
        'Pedido não pertence à organização/empresa informada.',
      );
    }
    if (!isReturnEligibleOrderStatus(order.status)) {
      throw new HttpsError(
        'failed-precondition',
        'Este pedido não está em um status elegível para devolução.',
      );
    }

    await ensureRequesterMayActOnOrder(transaction, organizationRef, {
      roleName: membership.roleName,
      uid,
      order,
      portalCustomerId,
      requesterTeamIds,
    });

    const previousReturnRequestsSnapshot = await transaction.get(
      organizationRef.collection('returnRequests').where('orderId', '==', orderId),
    );
    const alreadyCommittedByOrderItemId = sumCommittedQuantities(
      previousReturnRequestsSnapshot.docs.map((doc) => doc.data()),
    );

    const responseItems = items.map((item) =>
      buildResponseItem(item, order, alreadyCommittedByOrderItemId),
    );
    const refundAmount = roundCurrency(
      responseItems.reduce((sum, item) => sum + item.subtotal, 0),
    );

    const now = Timestamp.now();
    const returnRequestData: DocumentData = {
      organizationId,
      companyId,
      orderId,
      orderNumber: order.orderNumber,
      customerId: order.customerId,
      sellerId: order.sellerId,
      currency: order.currency,
      items: responseItems.map((item) => ({
        orderItemId: item.orderItemId,
        productId: item.productId,
        variantId: item.variantId,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        subtotal: item.subtotal,
        warehouseId:
          order.items.find((orderItem) => orderItem.id === item.orderItemId)?.warehouseId ?? null,
      })),
      reasonCategory,
      reasonDetails: reasonDetails ?? null,
      evidenceUrls,
      status: 'requested',
      refundAmount,
      requestedBy: uid,
      requestedByName: actorName,
      requestedAt: now,
      decisions: [],
      decidedBy: null,
      decidedAt: null,
      decisionReason: null,
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
      version: 1,
    };
    transaction.set(returnRequestRef, returnRequestData);

    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'return.requested',
      entityType: 'order',
      entityId: orderId,
      previousValue: null,
      newValue: {
        returnRequestId,
        reasonCategory,
        items: responseItems.map((item) => ({
          orderItemId: item.orderItemId,
          quantity: item.quantity,
        })),
        refundAmount,
      },
      timestamp: now,
    });

    // Links this devolução onto the pedido's own pós-venda timeline
    // (TASK-201, EPIC-30): "Vincular devoluções/trocas... como eventos na
    // mesma timeline, para visão única de pós-venda do pedido". Also
    // notifies the vendedor responsável (`SELLER_NOTIFIABLE_TYPES`).
    appendPostSaleEvent(transaction, organizationRef, {
      eventRef: organizationRef.collection('postSaleEvents').doc(),
      organizationId,
      companyId,
      orderId,
      orderNumber: order.orderNumber,
      customerId: order.customerId,
      sellerId: order.sellerId,
      type: 'return_requested',
      description: `Devolução solicitada (motivo: ${reasonCategory}).`,
      source: 'system',
      sourceRequestId: returnRequestId,
      createdBy: uid,
      createdByName: actorName,
      now,
    });

    return serializeReturnRequest(returnRequestId, returnRequestData, correlationId);
  });

  logger.info('createReturnRequest succeeded', {
    correlationId,
    organizationId,
    companyId,
    orderId,
    returnRequestId,
    uid,
    durationMs: Date.now() - startedAt,
  });

  return result;
});

/** Sums, per `orderItemId`, every quantity already committed to a devolução
 * that has not been rejected (`requested` or `approved`) — never letting a
 * new request push the total above what the pedido's own item actually
 * carries (`tasks.md`: "Quantidade devolvida nunca pode exceder a
 * quantidade original do item no pedido; validado sempre server-side"). A
 * `rejected` devolução frees its quantity back up for a new request. */
function sumCommittedQuantities(previousReturnRequests: DocumentData[]): Map<string, number> {
  const totals = new Map<string, number>();
  for (const returnRequest of previousReturnRequests) {
    if (returnRequest.status === 'rejected') continue;
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

function buildResponseItem(
  item: NormalizedItemInput,
  order: ReturnRequestOrder,
  alreadyCommittedByOrderItemId: Map<string, number>,
): CreateReturnRequestResponseItem {
  const orderItem = order.items.find((candidate) => candidate.id === item.orderItemId);
  if (!orderItem) {
    throw new HttpsError(
      'invalid-argument',
      `O item "${item.orderItemId}" não pertence a este pedido.`,
    );
  }
  const alreadyCommitted = alreadyCommittedByOrderItemId.get(item.orderItemId) ?? 0;
  if (alreadyCommitted + item.quantity > orderItem.quantity) {
    throw new HttpsError(
      'failed-precondition',
      `A quantidade solicitada para o item "${item.orderItemId}" excede a quantidade ` +
        'disponível para devolução neste pedido.',
    );
  }
  return {
    orderItemId: item.orderItemId,
    productId: orderItem.productId,
    variantId: orderItem.variantId,
    quantity: item.quantity,
    unitPrice: orderItem.unitPrice,
    subtotal: roundCurrency(orderItem.unitPrice * item.quantity),
  };
}

function requireItems(value: CreateReturnRequestItemInput[] | undefined): NormalizedItemInput[] {
  if (!Array.isArray(value) || value.length === 0) {
    throw new HttpsError('invalid-argument', 'items is required.');
  }
  const seen = new Set<string>();
  return value.map((item, index) => {
    if (typeof item !== 'object' || item === null) {
      throw new HttpsError('invalid-argument', `items[${index}] is invalid.`);
    }
    const orderItemId = requireString(item.orderItemId, `items[${index}].orderItemId`);
    if (seen.has(orderItemId)) {
      throw new HttpsError(
        'invalid-argument',
        `items[${index}].orderItemId "${orderItemId}" is duplicated.`,
      );
    }
    seen.add(orderItemId);
    const quantity = item.quantity;
    if (typeof quantity !== 'number' || !Number.isInteger(quantity) || quantity <= 0) {
      throw new HttpsError(
        'invalid-argument',
        `items[${index}].quantity must be a positive integer.`,
      );
    }
    return { orderItemId, quantity };
  });
}

function requireEvidenceUrls(value: string[] | undefined): string[] {
  if (value === undefined) return [];
  if (!Array.isArray(value) || value.some((entry) => typeof entry !== 'string')) {
    throw new HttpsError('invalid-argument', 'evidenceUrls must be an array of strings.');
  }
  if (value.length > MAX_EVIDENCE_URLS) {
    throw new HttpsError(
      'invalid-argument',
      `evidenceUrls must carry at most ${MAX_EVIDENCE_URLS} items.`,
    );
  }
  return value;
}

function requireOptionalBoundedString(
  value: string | undefined,
  field: string,
  maxLength: number,
): string | undefined {
  const normalized = optionalString(value);
  if (normalized && normalized.length > maxLength) {
    throw new HttpsError('invalid-argument', `${field} must stay under ${maxLength} characters.`);
  }
  return normalized;
}

function roundCurrency(value: number): number {
  return roundMoney(value);
}

function serializeReturnRequest(
  returnRequestId: string,
  data: DocumentData,
  correlationId: string,
): CreateReturnRequestResponse {
  const requestedAt = data.requestedAt as Timestamp;
  const rawItems = Array.isArray(data.items) ? (data.items as DocumentData[]) : [];
  return {
    correlationId,
    returnRequestId,
    orderId: data.orderId as string,
    status: 'requested',
    reasonCategory: data.reasonCategory as ReturnReasonCategory,
    items: rawItems.map((item) => ({
      orderItemId: item.orderItemId as string,
      productId: item.productId as string,
      variantId: item.variantId as string,
      quantity: item.quantity as number,
      unitPrice: item.unitPrice as number,
      subtotal: item.subtotal as number,
    })),
    refundAmount: typeof data.refundAmount === 'number' ? data.refundAmount : 0,
    requestedAt: requestedAt.toDate().toISOString(),
  };
}
