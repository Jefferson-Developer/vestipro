import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore, type DocumentData } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString, resolveActorName } from '../invites/invite-shared';
import { requirePositiveInteger } from '../inventory/stock-reservation-shared';
import {
  ROLES_ALLOWED_TO_REQUEST_BACKORDER,
  ensureRequesterMayActOnBackorder,
  mapReturnRequestOrder,
  normalizeTeamIds,
  optionalString,
  priorityWeight,
  readTotalSellableQuantity,
  requireBackorderOrigin,
  requireBackorderPriority,
  requireBoundedString,
  requireNonNegativeNumber,
  requireOptionalBoundedString,
  resolveAutoApproveMaxQuantity,
  type BackorderOrigin,
  type BackorderPriority,
} from './backorder-shared';
import type { ReturnRequestOrder } from '../returns/return-shared';

const MAX_NOTES_LENGTH = 1000;
const MAX_SKU_LENGTH = 100;

export interface CreateBackorderRequestRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  backorderId?: string;
  customerId?: string;
  productId?: string;
  variantId?: string;
  sku?: string;
  quantity?: number;
  origin?: BackorderOrigin;
  priority?: BackorderPriority;
  sellerId?: string;
  relatedOrderId?: string;
  relatedOrderItemId?: string;
  requestedDeliveryDate?: string;
  estimatedUnitPrice?: number;
  notes?: string;
}

export interface CreateBackorderRequestResponse {
  correlationId: string;
  backorderId: string;
  status: 'queued' | 'awaiting_approval';
  quantityAtRequest: number;
}

/**
 * Idempotent callable opening a `BackorderRequest` (TASK-215, EPIC-32) —
 * registers demand for a produto/variante sem estoque pronta entrega
 * suficiente, without ever moving/reserving a single unit of stock itself
 * (`tasks.md`: "Backorder não reduz saldo de estoque atual nem garante
 * entrega sem confirmação posterior"). Auto-queues straight into `queued`
 * whenever [CreateBackorderRequestRequest.quantity] is within the
 * organization's own configured limit
 * (`resolveAutoApproveMaxQuantity`); otherwise parks it at
 * `awaiting_approval` until `decideBackorderApproval` runs
 * (`tasks.md`: "Cliente/vendedor não pode criar backorder acima de limites
 * configurados sem aprovação").
 *
 * [CreateBackorderRequestRequest.backorderId] is the client-generated
 * idempotency key *and* the resulting document id — same precedent
 * `returnRequestId`/`shipmentId` already set.
 */
export const createBackorderRequest = onCall<
  CreateBackorderRequestRequest,
  Promise<CreateBackorderRequestResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'É necessário estar autenticado para solicitar um backorder.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
  const backorderId = requireNonEmptyString(request.data?.backorderId, 'backorderId');
  const customerId = requireNonEmptyString(request.data?.customerId, 'customerId');
  const productId = requireNonEmptyString(request.data?.productId, 'productId');
  const variantId = requireNonEmptyString(request.data?.variantId, 'variantId');
  const sku = requireOptionalBoundedString(request.data?.sku, 'sku', MAX_SKU_LENGTH);
  const quantity = requirePositiveInteger(request.data?.quantity, 'quantity');
  const origin = requireBackorderOrigin(request.data?.origin);
  const priority = requireBackorderPriority(request.data?.priority);
  const relatedOrderId = optionalString(request.data?.relatedOrderId);
  const relatedOrderItemId = optionalString(request.data?.relatedOrderItemId);
  const requestedDeliveryDate = parseOptionalDate(request.data?.requestedDeliveryDate);
  const estimatedUnitPrice =
    request.data?.estimatedUnitPrice === undefined
      ? undefined
      : requireNonNegativeNumber(request.data?.estimatedUnitPrice, 'estimatedUnitPrice');
  const notes = request.data?.notes === undefined
    ? undefined
    : requireBoundedString(request.data?.notes, 'notes', MAX_NOTES_LENGTH);

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_REQUEST_BACKORDER.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Seu perfil não pode solicitar backorders.');
  }

  const organizationRef = db.collection('organizations').doc(organizationId);
  const backorderRef = organizationRef.collection('backorders').doc(backorderId);

  const existingSnapshot = await backorderRef.get();
  if (existingSnapshot.exists) {
    const existing = existingSnapshot.data();
    if (!existing) throw new HttpsError('internal', 'Invalid backorder record.');
    return {
      correlationId,
      backorderId,
      status: existing.status === 'awaiting_approval' ? 'awaiting_approval' : 'queued',
      quantityAtRequest: (existing.quantityAtRequest as number) ?? 0,
    };
  }

  const customerSnapshot = await organizationRef.collection('customers').doc(customerId).get();
  const customer = customerSnapshot.data();
  if (!customerSnapshot.exists || !customer) {
    throw new HttpsError('failed-precondition', 'Cliente não encontrado.');
  }
  if (customer.companyId !== companyId) {
    throw new HttpsError('failed-precondition', 'Cliente não pertence à empresa informada.');
  }

  const variantSnapshot = await organizationRef
    .collection('products')
    .doc(productId)
    .collection('variants')
    .doc(variantId)
    .get();
  if (!variantSnapshot.exists) {
    throw new HttpsError('failed-precondition', 'Variante de produto não encontrada.');
  }

  let relatedOrder: ReturnRequestOrder | undefined;
  let requesterTeamIds: string[] = [];
  if (membership.roleName === 'SALES_MANAGER') {
    const requesterMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
    requesterTeamIds = normalizeTeamIds(requesterMemberSnapshot.data()?.teamIds);
  }

  let portalCustomerId: string | undefined;
  if (membership.roleName === 'CUSTOMER_PORTAL') {
    if (!relatedOrderId) {
      throw new HttpsError(
        'failed-precondition',
        'O portal só pode solicitar um backorder vinculado a um pedido existente.',
      );
    }
    const portalMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
    portalCustomerId = optionalString(portalMemberSnapshot.data()?.customerId);
  }

  if (relatedOrderId) {
    const orderSnapshot = await organizationRef.collection('orders').doc(relatedOrderId).get();
    if (!orderSnapshot.exists) {
      throw new HttpsError('failed-precondition', 'Pedido relacionado não encontrado.');
    }
    relatedOrder = mapReturnRequestOrder(relatedOrderId, orderSnapshot.data());
    if (relatedOrder.customerId !== customerId) {
      throw new HttpsError('failed-precondition', 'O pedido relacionado não pertence a este cliente.');
    }
  }

  const resolvedSellerId =
    membership.roleName === 'SALES_REP'
      ? uid
      : relatedOrder
        ? relatedOrder.sellerId
        : requireNonEmptyString(request.data?.sellerId, 'sellerId');

  const sellerSnapshot = await organizationRef.collection('members').doc(resolvedSellerId).get();
  if (!sellerSnapshot.exists) {
    throw new HttpsError('failed-precondition', 'Vendedor responsável não encontrado.');
  }

  const organizationSnapshot = await organizationRef.get();
  const autoApproveMaxQuantity = resolveAutoApproveMaxQuantity(organizationSnapshot.data());
  const status = quantity <= autoApproveMaxQuantity ? 'queued' : 'awaiting_approval';
  const quantityAtRequest = await readTotalSellableQuantity(organizationRef, variantId);
  const actorName = await resolveActorName(db, uid, request.auth.token);

  await db.runTransaction(async (transaction) => {
    await ensureRequesterMayActOnBackorder(transaction, organizationRef, {
      roleName: membership.roleName,
      uid,
      sellerId: resolvedSellerId,
      customerId,
      portalCustomerId,
      requesterTeamIds,
      relatedOrder,
    });

    const existing = await transaction.get(backorderRef);
    if (existing.exists) return;

    const now = Timestamp.now();

    const backorderData: DocumentData = {
      organizationId,
      companyId,
      customerId,
      productId,
      variantId,
      sku: sku ?? null,
      quantity,
      fulfilledQuantity: 0,
      quantityAtRequest,
      origin,
      priority,
      priorityWeight: priorityWeight(priority),
      sellerId: resolvedSellerId,
      relatedOrderId: relatedOrderId ?? null,
      relatedOrderItemId: relatedOrderItemId ?? null,
      requestedDeliveryDate: requestedDeliveryDate ?? null,
      estimatedUnitPrice: estimatedUnitPrice ?? null,
      notes: notes ?? null,
      status,
      resolutionNote: null,
      convertedOrderId: null,
      convertedAt: null,
      convertedBy: null,
      expectedAvailabilityDate: null,
      readyToFulfillAt: null,
      requestedBy: uid,
      requestedByName: actorName,
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
      version: 1,
    };
    transaction.set(backorderRef, backorderData);

    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'backorder.requested',
      entityType: 'backorder',
      entityId: backorderId,
      previousValue: null,
      newValue: { customerId, productId, variantId, quantity, status },
      timestamp: now,
    });
  });

  const finalSnapshot = await backorderRef.get();
  const finalData = finalSnapshot.data();

  logger.info('createBackorderRequest succeeded', {
    correlationId,
    organizationId,
    backorderId,
    customerId,
    variantId,
    quantity,
    status: finalData?.status,
    uid,
    durationMs: Date.now() - startedAt,
  });

  return {
    correlationId,
    backorderId,
    status: (finalData?.status as 'queued' | 'awaiting_approval') ?? 'queued',
    quantityAtRequest: (finalData?.quantityAtRequest as number) ?? 0,
  };
});

function parseOptionalDate(value: string | undefined): Timestamp | undefined {
  const normalized = optionalString(value);
  if (!normalized) return undefined;
  const parsed = new Date(normalized);
  if (Number.isNaN(parsed.getTime())) {
    throw new HttpsError('invalid-argument', 'requestedDeliveryDate must be a valid ISO date.');
  }
  return Timestamp.fromDate(parsed);
}
