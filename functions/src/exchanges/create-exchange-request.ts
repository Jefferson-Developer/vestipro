import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore, type DocumentData, type Transaction } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';
import {
  ensureRequesterMayActOnOrder,
  isReturnEligibleOrderStatus,
  mapReturnRequestOrder,
  normalizeTeamIds,
  optionalString,
  requireString,
  type ReturnRequestOrder,
} from '../returns/return-shared';
import {
  findFulfillableBalance,
  mapExchangeDestinationVariant,
  requireExchangeReasonCategory,
  type ExchangeReasonCategory,
} from './exchange-shared';
import { appendPostSaleEvent } from '../after_sales/after-sales-shared';

/**
 * Only these roles may ever request a troca for a pedido (TASK-200,
 * EPIC-30) — deliberately the exact same grant list
 * `ROLES_ALLOWED_TO_REQUEST_RETURN` (`create-return-request.ts`, TASK-199)
 * already uses: a troca is requested by whoever could already act on that
 * same order.
 */
const ROLES_ALLOWED_TO_REQUEST_EXCHANGE: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
  'SALES_REP',
  'CUSTOMER_PORTAL',
]);

const MAX_REASON_DETAILS_LENGTH = 1000;

export interface CreateExchangeRequestItemInput {
  orderItemId?: string;
  destinationVariantId?: string;
  quantity?: number;
}

export interface CreateExchangeRequestRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  orderId?: string;
  exchangeRequestId?: string;
  items?: CreateExchangeRequestItemInput[];
  reasonCategory?: ExchangeReasonCategory;
  reasonDetails?: string;
}

export interface CreateExchangeRequestResponseItem {
  orderItemId: string;
  originProductId: string;
  originVariantId: string;
  originUnitPrice: number;
  destinationVariantId: string;
  destinationProductId: string;
  quantity: number;
}

export interface CreateExchangeRequestResponse {
  correlationId: string;
  exchangeRequestId: string;
  orderId: string;
  status: 'requested';
  reasonCategory: ExchangeReasonCategory;
  items: CreateExchangeRequestResponseItem[];
  requestedAt: string;
}

interface NormalizedItemInput {
  orderItemId: string;
  destinationVariantId: string;
  quantity: number;
}

/**
 * Idempotent Cloud Function opening an `ExchangeRequest` (TASK-200, EPIC-30)
 * against an already-fulfilled pedido, reusing the very same order-
 * eligibility/ownership rules `createReturnRequest` (TASK-199) already
 * established: revalidates every original item against the order's own
 * persisted `items`, and — the one check a devolução never needs — checks
 * in real time whether the destination variant can actually fulfill the
 * requested quantity (`tasks.md`: "checar em tempo real a disponibilidade da
 * variante de destino... antes de permitir a solicitação"). Never applies
 * any stock/financial effect by itself — that only happens later, in
 * `resolveExchangeRequest`, and only after a *second*, independent
 * revalidation of this same availability (stock can drift between the
 * solicitação and the aprovação).
 *
 * [CreateExchangeRequestRequest.exchangeRequestId] is the client-generated
 * idempotency key *and* the resulting document id, same precedent
 * `createReturnRequest`'s own `returnRequestId` already sets.
 */
export const createExchangeRequest = onCall<
  CreateExchangeRequestRequest,
  Promise<CreateExchangeRequestResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para solicitar uma troca.',
    );
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
  const orderId = requireNonEmptyString(request.data?.orderId, 'orderId');
  const exchangeRequestId = requireNonEmptyString(
    request.data?.exchangeRequestId,
    'exchangeRequestId',
  );
  const reasonCategory = requireExchangeReasonCategory(request.data?.reasonCategory);
  const reasonDetails = requireOptionalBoundedString(
    request.data?.reasonDetails,
    'reasonDetails',
    MAX_REASON_DETAILS_LENGTH,
  );
  const items = requireItems(request.data?.items);

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_REQUEST_EXCHANGE.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Seu perfil não pode solicitar trocas.');
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const orderRef = organizationRef.collection('orders').doc(orderId);
  const exchangeRequestRef = organizationRef.collection('exchangeRequests').doc(exchangeRequestId);

  let portalCustomerId: string | undefined;
  let requesterTeamIds: string[] = [];
  if (membership.roleName === 'CUSTOMER_PORTAL') {
    const portalMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
    portalCustomerId = optionalString(portalMemberSnapshot.data()?.customerId);
  } else if (membership.roleName === 'SALES_MANAGER') {
    const requesterMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
    requesterTeamIds = normalizeTeamIds(requesterMemberSnapshot.data()?.teamIds);
  }

  const result = await db.runTransaction<CreateExchangeRequestResponse>(async (transaction) => {
    const existingSnapshot = await transaction.get(exchangeRequestRef);
    if (existingSnapshot.exists) {
      const existing = existingSnapshot.data();
      if (!existing) throw new HttpsError('internal', 'Invalid exchange request record.');
      return serializeExchangeRequest(exchangeRequestId, existing, correlationId);
    }

    const orderSnapshot = await transaction.get(orderRef);
    if (!orderSnapshot.exists) {
      throw new HttpsError('failed-precondition', 'Pedido não encontrado.');
    }
    const orderData = orderSnapshot.data();
    const order = mapReturnRequestOrder(orderId, orderData);
    if (order.organizationId !== organizationId || order.companyId !== companyId) {
      throw new HttpsError(
        'failed-precondition',
        'Pedido não pertence à organização/empresa informada.',
      );
    }
    // Same window a devolução is allowed in (TASK-199): a troca only ever
    // makes sense once goods have actually left the warehouse/been billed.
    if (!isReturnEligibleOrderStatus(order.status)) {
      throw new HttpsError(
        'failed-precondition',
        'Este pedido não está em um status elegível para troca.',
      );
    }

    await ensureRequesterMayActOnOrder(transaction, organizationRef, {
      roleName: membership.roleName,
      uid,
      order,
      portalCustomerId,
      requesterTeamIds,
    });

    const previousExchangeRequestsSnapshot = await transaction.get(
      organizationRef.collection('exchangeRequests').where('orderId', '==', orderId),
    );
    const alreadyCommittedByOrderItemId = sumCommittedQuantities(
      previousExchangeRequestsSnapshot.docs.map((doc) => doc.data()),
    );

    // ---- destination variant + availability reads (before any write) ----
    const responseItems: CreateExchangeRequestResponseItem[] = [];
    for (const item of items) {
      responseItems.push(
        await resolveExchangeItem(transaction, organizationRef, item, order, alreadyCommittedByOrderItemId),
      );
      // Every item consumes its own slice of `alreadyCommittedByOrderItemId`
      // so two lines of this very same request referencing the same
      // `orderItemId` are validated cumulatively, never independently.
      const orderItemId = item.orderItemId;
      alreadyCommittedByOrderItemId.set(
        orderItemId,
        (alreadyCommittedByOrderItemId.get(orderItemId) ?? 0) + item.quantity,
      );
    }

    const now = Timestamp.now();
    const exchangeRequestData: DocumentData = {
      organizationId,
      companyId,
      orderId,
      orderNumber: order.orderNumber,
      customerId: order.customerId,
      sellerId: order.sellerId,
      currency: order.currency,
      priceListId: optionalString(orderData?.priceListId) ?? null,
      paymentTermId: optionalString(orderData?.paymentTermId) ?? null,
      items: responseItems,
      reasonCategory,
      reasonDetails: reasonDetails ?? null,
      status: 'requested',
      priceDifferenceAmount: null,
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
    transaction.set(exchangeRequestRef, exchangeRequestData);

    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'exchange.requested',
      entityType: 'order',
      entityId: orderId,
      previousValue: null,
      newValue: {
        exchangeRequestId,
        reasonCategory,
        items: responseItems.map((item) => ({
          orderItemId: item.orderItemId,
          destinationVariantId: item.destinationVariantId,
          quantity: item.quantity,
        })),
      },
      timestamp: now,
    });

    // Links this troca onto the pedido's own pós-venda timeline (TASK-201,
    // EPIC-30) — see `create-return-request.ts`'s own `appendPostSaleEvent`
    // call for the exact same convention applied to devoluções.
    appendPostSaleEvent(transaction, organizationRef, {
      eventRef: organizationRef.collection('postSaleEvents').doc(),
      organizationId,
      companyId,
      orderId,
      orderNumber: order.orderNumber,
      customerId: order.customerId,
      sellerId: order.sellerId,
      type: 'exchange_requested',
      description: `Troca solicitada (motivo: ${reasonCategory}).`,
      source: 'system',
      sourceRequestId: exchangeRequestId,
      createdBy: uid,
      createdByName: actorName,
      now,
    });

    return serializeExchangeRequest(exchangeRequestId, exchangeRequestData, correlationId);
  });

  logger.info('createExchangeRequest succeeded', {
    correlationId,
    organizationId,
    companyId,
    orderId,
    exchangeRequestId,
    uid,
    durationMs: Date.now() - startedAt,
  });

  return result;
});

async function resolveExchangeItem(
  transaction: Transaction,
  organizationRef: FirebaseFirestore.DocumentReference,
  item: NormalizedItemInput,
  order: ReturnRequestOrder,
  alreadyCommittedByOrderItemId: Map<string, number>,
): Promise<CreateExchangeRequestResponseItem> {
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
        'disponível para troca neste pedido.',
    );
  }
  if (item.destinationVariantId === orderItem.variantId) {
    throw new HttpsError(
      'invalid-argument',
      'A variante de destino não pode ser igual à variante original.',
    );
  }

  const destinationSnapshot = await transaction.get(
    organizationRef.collection('productVariants').doc(item.destinationVariantId),
  );
  const destinationVariant = mapExchangeDestinationVariant(
    item.destinationVariantId,
    destinationSnapshot.data(),
  );
  if (destinationVariant.productId !== orderItem.productId) {
    throw new HttpsError(
      'invalid-argument',
      'A variante de destino precisa ser do mesmo produto da variante original (troca de cor/tamanho).',
    );
  }
  if (destinationVariant.status !== 'active') {
    throw new HttpsError(
      'failed-precondition',
      'A variante de destino não está mais ativa para venda.',
    );
  }

  const fulfillable = await findFulfillableBalance(
    (query) => transaction.get(query),
    organizationRef,
    item.destinationVariantId,
    item.quantity,
  );
  if (!fulfillable) {
    throw new HttpsError(
      'failed-precondition',
      'A variante de destino não tem estoque suficiente para a quantidade solicitada.',
    );
  }

  return {
    orderItemId: item.orderItemId,
    originProductId: orderItem.productId,
    originVariantId: orderItem.variantId,
    originUnitPrice: orderItem.unitPrice,
    destinationVariantId: item.destinationVariantId,
    destinationProductId: destinationVariant.productId,
    quantity: item.quantity,
  };
}

/** Sums, per `orderItemId`, every quantity already committed to a troca
 * that has not been rejected (`requested` or `approved`) — same precedent
 * `sumCommittedQuantities` (`create-return-request.ts`) already sets for
 * devoluções, kept as an independent copy here since it queries a different
 * collection (`exchangeRequests`, never `returnRequests`) — this codebase
 * deliberately does not cross-check the two collections against one another
 * yet (see this task's own "Riscos conhecidos"). */
function sumCommittedQuantities(previousExchangeRequests: DocumentData[]): Map<string, number> {
  const totals = new Map<string, number>();
  for (const exchangeRequest of previousExchangeRequests) {
    if (exchangeRequest.status === 'rejected') continue;
    const items = Array.isArray(exchangeRequest.items) ? exchangeRequest.items : [];
    for (const item of items) {
      const orderItemId = item?.orderItemId as string | undefined;
      if (!orderItemId) continue;
      const quantity = typeof item?.quantity === 'number' ? item.quantity : 0;
      totals.set(orderItemId, (totals.get(orderItemId) ?? 0) + quantity);
    }
  }
  return totals;
}

function requireItems(value: CreateExchangeRequestItemInput[] | undefined): NormalizedItemInput[] {
  if (!Array.isArray(value) || value.length === 0) {
    throw new HttpsError('invalid-argument', 'items is required.');
  }
  return value.map((item, index) => {
    if (typeof item !== 'object' || item === null) {
      throw new HttpsError('invalid-argument', `items[${index}] is invalid.`);
    }
    const orderItemId = requireString(item.orderItemId, `items[${index}].orderItemId`);
    const destinationVariantId = requireString(
      item.destinationVariantId,
      `items[${index}].destinationVariantId`,
    );
    const quantity = item.quantity;
    if (typeof quantity !== 'number' || !Number.isInteger(quantity) || quantity <= 0) {
      throw new HttpsError(
        'invalid-argument',
        `items[${index}].quantity must be a positive integer.`,
      );
    }
    return { orderItemId, destinationVariantId, quantity };
  });
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

function serializeExchangeRequest(
  exchangeRequestId: string,
  data: DocumentData,
  correlationId: string,
): CreateExchangeRequestResponse {
  const requestedAt = data.requestedAt as Timestamp;
  const rawItems = Array.isArray(data.items) ? (data.items as DocumentData[]) : [];
  return {
    correlationId,
    exchangeRequestId,
    orderId: data.orderId as string,
    status: 'requested',
    reasonCategory: data.reasonCategory as ExchangeReasonCategory,
    items: rawItems.map((item) => ({
      orderItemId: item.orderItemId as string,
      originProductId: item.originProductId as string,
      originVariantId: item.originVariantId as string,
      originUnitPrice: item.originUnitPrice as number,
      destinationVariantId: item.destinationVariantId as string,
      destinationProductId: item.destinationProductId as string,
      quantity: item.quantity as number,
    })),
    requestedAt: requestedAt.toDate().toISOString(),
  };
}
