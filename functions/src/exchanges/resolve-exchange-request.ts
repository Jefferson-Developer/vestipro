import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import {
  FieldValue,
  Timestamp,
  getFirestore,
  type DocumentData,
  type Transaction,
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
  normalizeTeamIds,
  optionalString,
  resolveRestockPlans,
} from '../returns/return-shared';
import {
  calculatePricingEngine,
  type PricingEngineItemInput,
} from '../pricing/pricing-engine';
import {
  ensureActivePriceList,
  ensureCompanyScope,
  ensureValidPaymentTerm,
  mapCampaign,
  mapCommercialRule,
  mapPaymentTerm,
  mapPriceList,
  mapPriceListItem,
  requireNonEmptyString as requirePricingString,
} from '../pricing/calculate-pricing';
import {
  findFulfillableBalance,
  mapExchangeDestinationVariant,
} from './exchange-shared';
import { appendPostSaleEvent } from '../after_sales/after-sales-shared';

/**
 * Only these roles may ever decide (aprovar/recusar) an `ExchangeRequest`
 * (TASK-200, EPIC-30) — deliberately the exact same grant list
 * `ROLES_ALLOWED_TO_DECIDE_RETURN` (`resolve-return-request.ts`, TASK-199)
 * already uses.
 */
const ROLES_ALLOWED_TO_DECIDE_EXCHANGE: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
]);

const DECIDABLE_STATUSES: ReadonlySet<string> = new Set<string>(['approved', 'rejected']);

export type ExchangeRequestDecisionValue = 'approved' | 'rejected';

export interface ResolveExchangeRequestRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  exchangeRequestId?: string;
  decision?: ExchangeRequestDecisionValue;
  reason?: string;
}

export interface ResolveExchangeRequestResponse {
  correlationId: string;
  exchangeRequestId: string;
  orderId: string;
  status: ExchangeRequestDecisionValue;
  decidedBy: string;
  decidedAt: string;
  reason: string | null;
  /** Positive: cliente deve a diferença; negative: cliente recebe a
   * diferença de volta; `0`: variantes de mesmo preço vigente. Always
   * computed from the pricing engine's *current* price for the destination
   * variant (never the estimate carried since the solicitação) — `undefined`
   * for a recusa, which never prices anything. */
  priceDifferenceAmount?: number;
}

interface ExchangeItemRecord {
  orderItemId: string;
  originProductId: string;
  originVariantId: string;
  originUnitPrice: number;
  destinationVariantId: string;
  destinationProductId: string;
  quantity: number;
}

/**
 * Idempotent Cloud Function deciding an `ExchangeRequest` still `requested`
 * (TASK-200, EPIC-30) — the only place a troca's stock/financial effect is
 * ever applied, reusing every piece of infrastructure TASK-199's own
 * `resolveReturnRequest` already established:
 *
 * - a rejection never touches stock or pricing at all;
 * - an approval **revalidates, inside this same transaction, that the
 *   destination variant can still fulfill the requested quantity** —
 *   availability may have drifted since the solicitação. When it can no
 *   longer be fulfilled, this call fails outright (`failed-precondition`)
 *   instead of silently approving into a stockout: the analyst attempting
 *   the approval sees the error synchronously and must decide manually
 *   (recusar, ou aguardar reposição e tentar novamente) — `tasks.md`: "nunca
 *   aprovar silenciosamente uma troca por algo indisponível";
 * - only once availability is confirmed does it, atomically: reintegrate
 *   the origin variant's quantity into its warehouse of origin (exact same
 *   `resolveRestockPlans`/`applyRestockMovements` helpers `resolveReturnRequest`
 *   already uses) *and* debit the destination variant's own balance;
 * - the price difference between origin and destination is priced by the
 *   pricing engine's own *current* price for the destination variant
 *   (TASK-088's `calculatePricingEngine`, the same engine/Price List/
 *   payment term/campaign/commercial-rule resolution `submitOrder` itself
 *   uses) — never the client's own estimate from the solicitação, which may
 *   be stale by the time this decision is made.
 *
 * Unlike a devolução, a troca never changes the pedido's own `status`: the
 * customer still keeps the same total quantity of merchandise, only a
 * different variante — so no commission reversal, no
 * `returned`/`partiallyReturned` transition applies here.
 */
export const resolveExchangeRequest = onCall<
  ResolveExchangeRequestRequest,
  Promise<ResolveExchangeRequestResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'É necessário estar autenticado para decidir uma troca.',
    );
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
  const exchangeRequestId = requireNonEmptyString(
    request.data?.exchangeRequestId,
    'exchangeRequestId',
  );
  const decision = requireDecision(request.data?.decision);
  const reason = optionalString(request.data?.reason);
  if (decision === 'rejected' && !reason) {
    throw new HttpsError('invalid-argument', 'É necessário informar o motivo da recusa.');
  }

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_DECIDE_EXCHANGE.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Seu perfil não pode decidir trocas.');
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const exchangeRequestRef = organizationRef.collection('exchangeRequests').doc(exchangeRequestId);

  let requesterTeamIds: string[] = [];
  if (membership.roleName === 'SALES_MANAGER') {
    const requesterMemberSnapshot = await organizationRef.collection('members').doc(uid).get();
    requesterTeamIds = normalizeTeamIds(requesterMemberSnapshot.data()?.teamIds);
  }

  const result = await db.runTransaction<ResolveExchangeRequestResponse>(async (transaction) => {
    const exchangeRequestSnapshot = await transaction.get(exchangeRequestRef);
    const exchangeRequest = exchangeRequestSnapshot.data();
    if (!exchangeRequestSnapshot.exists || !exchangeRequest) {
      throw new HttpsError('failed-precondition', 'Troca não encontrada.');
    }
    if (
      exchangeRequest.organizationId !== organizationId ||
      exchangeRequest.companyId !== companyId
    ) {
      throw new HttpsError(
        'failed-precondition',
        'Troca não pertence à organização/empresa informada.',
      );
    }

    if (membership.roleName === 'SALES_MANAGER') {
      const sellerSnapshot = await transaction.get(
        organizationRef.collection('members').doc(exchangeRequest.sellerId as string),
      );
      const sellerTeamIds = normalizeTeamIds(sellerSnapshot.data()?.teamIds);
      const sharesTeam = sellerTeamIds.some((teamId) => requesterTeamIds.includes(teamId));
      if (!sharesTeam) {
        throw new HttpsError(
          'permission-denied',
          'Você só pode decidir trocas da sua própria equipe.',
        );
      }
    }

    // Retry/double-tap of the very same decision — replays what is already
    // persisted, same idempotency precedent `resolveReturnRequest` sets.
    if (exchangeRequest.status === decision) {
      return serializeDecision(exchangeRequestId, exchangeRequest, correlationId);
    }
    if (exchangeRequest.status !== 'requested') {
      throw new HttpsError(
        'failed-precondition',
        'Esta troca já foi decidida e não pode ser decidida novamente.',
      );
    }

    const orderId = requireDataString(exchangeRequest.orderId, 'exchangeRequest.orderId');
    const orderRef = organizationRef.collection('orders').doc(orderId);
    const orderSnapshot = await transaction.get(orderRef);
    if (!orderSnapshot.exists) {
      throw new HttpsError('failed-precondition', 'Pedido original não encontrado.');
    }
    const orderData = orderSnapshot.data();
    const order = mapReturnRequestOrder(orderId, orderData);

    const items = normalizeExchangeItems(exchangeRequest.items);
    const now = Timestamp.now();

    if (decision === 'rejected') {
      const decisionEntry = {
        decision: 'rejected',
        actorId: uid,
        actorName,
        reason,
        decidedAt: now,
      };
      transaction.update(exchangeRequestRef, {
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
        action: 'exchange.rejected',
        entityType: 'order',
        entityId: orderId,
        previousValue: { exchangeRequestId, status: 'requested' },
        newValue: { exchangeRequestId, status: 'rejected', reason },
        timestamp: now,
      });
      // Links this decisão onto the pedido's own pós-venda timeline
      // (TASK-201, EPIC-30) — see `create-return-request.ts`'s own
      // `appendPostSaleEvent` call for the exact same convention applied to
      // devoluções.
      appendPostSaleEvent(transaction, organizationRef, {
        eventRef: organizationRef.collection('postSaleEvents').doc(),
        organizationId,
        companyId,
        orderId,
        orderNumber: order.orderNumber,
        customerId: order.customerId,
        sellerId: order.sellerId,
        type: 'exchange_resolved',
        description: reason
          ? `Troca recusada (motivo: ${reason}).`
          : 'Troca recusada.',
        source: 'system',
        sourceRequestId: exchangeRequestId,
        createdBy: uid,
        createdByName: actorName,
        now,
      });
      return {
        correlationId,
        exchangeRequestId,
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
        'Este pedido não está mais em um status elegível para troca.',
      );
    }

    // Re-validates (server-side, inside this same transaction) that
    // approving this troca never pushes an exchanged quantity above the
    // pedido's own original item quantity — a second safety net beyond
    // `createExchangeRequest`'s own check, covering the (rare) race of two
    // overlapping trocas approved concurrently.
    const otherExchangeRequestsSnapshot = await transaction.get(
      organizationRef
        .collection('exchangeRequests')
        .where('orderId', '==', orderId)
        .where('status', '==', 'approved'),
    );
    const approvedByOrderItemId = sumApprovedQuantities(
      otherExchangeRequestsSnapshot.docs
        .filter((doc) => doc.id !== exchangeRequestId)
        .map((doc) => doc.data()),
    );
    for (const item of items) {
      const orderItem = order.items.find((candidate) => candidate.id === item.orderItemId);
      if (!orderItem) continue;
      const alreadyApproved = approvedByOrderItemId.get(item.orderItemId) ?? 0;
      if (alreadyApproved + item.quantity > orderItem.quantity) {
        throw new HttpsError(
          'failed-precondition',
          `A troca aprovada de outra solicitação já cobre a quantidade do item ` +
            `"${item.orderItemId}"; esta aprovação excederia a quantidade original do pedido.`,
        );
      }
      approvedByOrderItemId.set(item.orderItemId, alreadyApproved + item.quantity);
    }

    // ---- destination variant + availability re-checks (reads only) ------
    const destinationBalances = new Map<string, { ref: FirebaseFirestore.DocumentReference }>();
    for (const item of items) {
      const destinationSnapshot = await transaction.get(
        organizationRef.collection('productVariants').doc(item.destinationVariantId),
      );
      const destinationVariant = mapExchangeDestinationVariant(
        item.destinationVariantId,
        destinationSnapshot.data(),
      );
      if (destinationVariant.status !== 'active') {
        throw new HttpsError(
          'failed-precondition',
          'A variante de destino não está mais ativa; a troca não pode ser aprovada ' +
            'automaticamente. Recuse ou renegocie a variante com o cliente.',
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
          'A variante de destino ficou indisponível desde a solicitação. A troca não foi ' +
            'aprovada automaticamente — decida manualmente (recuse ou aguarde reposição e ' +
            'tente novamente) após reavaliar com o cliente.',
        );
      }
      destinationBalances.set(item.destinationVariantId, { ref: fulfillable.ref });
    }

    // ---- pricing: destination variant's *current* price (never the --------
    // ---- estimate frozen at the solicitação) -----------------------------
    const priceDifferenceAmount = await computePriceDifference(
      transaction,
      organizationRef,
      companyId,
      order,
      orderData,
      items,
    );

    // ---- writes -----------------------------------------------------------
    const restockPlans = await resolveRestockPlans(
      transaction,
      organizationRef,
      items.map((item) => ({
        variantId: item.originVariantId,
        quantity: item.quantity,
        warehouseId:
          order.items.find((orderItem) => orderItem.id === item.orderItemId)?.warehouseId ?? null,
      })),
    );
    applyRestockMovements(transaction, restockPlans, {
      uid,
      now,
      source: 'exchange_request_approval_origin_restock',
    });

    for (const item of items) {
      const destinationBalance = destinationBalances.get(item.destinationVariantId);
      if (!destinationBalance) continue;
      transaction.set(
        destinationBalance.ref,
        {
          physicalQuantity: FieldValue.increment(-item.quantity),
          updatedAt: now,
          updatedBy: uid,
          lastSource: 'exchange_request_approval_destination_debit',
          version: FieldValue.increment(1),
        },
        { merge: true },
      );
    }

    const decisionEntry = {
      decision: 'approved',
      actorId: uid,
      actorName,
      reason: reason ?? null,
      decidedAt: now,
    };
    transaction.update(exchangeRequestRef, {
      status: 'approved',
      priceDifferenceAmount,
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
      action: 'exchange.approved',
      entityType: 'order',
      entityId: orderId,
      previousValue: { exchangeRequestId, status: 'requested' },
      newValue: {
        exchangeRequestId,
        status: 'approved',
        priceDifferenceAmount,
        reason: reason ?? null,
      },
      timestamp: now,
    });

    // Links this decisão onto the pedido's own pós-venda timeline
    // (TASK-201, EPIC-30) — see `create-return-request.ts`'s own
    // `appendPostSaleEvent` call for the exact same convention applied to
    // devoluções.
    appendPostSaleEvent(transaction, organizationRef, {
      eventRef: organizationRef.collection('postSaleEvents').doc(),
      organizationId,
      companyId,
      orderId,
      orderNumber: order.orderNumber,
      customerId: order.customerId,
      sellerId: order.sellerId,
      type: 'exchange_resolved',
      description: 'Troca aprovada.',
      source: 'system',
      sourceRequestId: exchangeRequestId,
      createdBy: uid,
      createdByName: actorName,
      now,
    });

    return {
      correlationId,
      exchangeRequestId,
      orderId,
      status: 'approved',
      decidedBy: uid,
      decidedAt: now.toDate().toISOString(),
      reason: reason ?? null,
      priceDifferenceAmount,
    };
  });

  logger.info('resolveExchangeRequest succeeded', {
    correlationId,
    organizationId,
    companyId,
    exchangeRequestId,
    decision,
    uid,
    durationMs: Date.now() - startedAt,
  });

  return result;
});

/**
 * Prices every destination variant with the pedido's own commercial
 * conditions (Price List/payment term/campaigns/commercial rules) *as they
 * stand right now* — reusing `calculatePricingEngine` (TASK-088), the exact
 * same engine `submitOrder` itself uses, instead of a bespoke price lookup
 * that could silently drift from it. No manual discount/discount policy is
 * ever considered here: a troca is never a renegotiation of the seller's own
 * discount, only a same-product/different-variant swap at the catalog's
 * current price.
 */
async function computePriceDifference(
  transaction: Transaction,
  organizationRef: FirebaseFirestore.DocumentReference,
  companyId: string,
  order: ReturnType<typeof mapReturnRequestOrder>,
  orderData: DocumentData | undefined,
  items: ExchangeItemRecord[],
): Promise<number> {
  const priceListId = requirePricingString(orderData?.priceListId, 'order.priceListId');
  const paymentTermId = requirePricingString(orderData?.paymentTermId, 'order.paymentTermId');

  const customerSnapshot = await transaction.get(
    organizationRef.collection('customers').doc(order.customerId),
  );
  const customerSegment = optionalString(customerSnapshot.data()?.segment) ?? '';

  const priceListSnapshot = await transaction.get(
    organizationRef.collection('priceLists').doc(priceListId),
  );
  const selectedPriceList = mapPriceList(priceListId, priceListSnapshot.data());
  ensureCompanyScope(companyId, 'Price list', selectedPriceList);
  ensureActivePriceList(selectedPriceList);

  const paymentTermSnapshot = await transaction.get(
    organizationRef.collection('paymentTerms').doc(paymentTermId),
  );
  const paymentTerm = mapPaymentTerm(paymentTermId, paymentTermSnapshot.data());
  ensureCompanyScope(companyId, 'Payment term', paymentTerm);
  ensureValidPaymentTerm(paymentTerm, priceListId);

  const priceItemSnapshots = await transaction.get(
    organizationRef.collection('priceLists').doc(priceListId).collection('items'),
  );
  const priceListItems = priceItemSnapshots.docs.map((doc) => mapPriceListItem(doc.data()));
  priceListItems.forEach((item) => ensureCompanyScope(companyId, 'Price list item', item));

  const campaignSnapshots = await transaction.get(
    organizationRef.collection('promotionalCampaigns'),
  );
  const campaigns = campaignSnapshots.docs.map((doc) => mapCampaign(doc.id, doc.data()));
  campaigns.forEach((campaign) => ensureCompanyScope(companyId, 'Campaign', campaign));

  const commercialRuleSnapshots = await transaction.get(
    organizationRef.collection('commercialRules'),
  );
  const commercialRules = commercialRuleSnapshots.docs.map((doc) =>
    mapCommercialRule(doc.id, doc.data()),
  );
  commercialRules.forEach((rule) => ensureCompanyScope(companyId, 'Commercial rule', rule));

  const pricingItems: PricingEngineItemInput[] = items.map((item) => ({
    productId: item.destinationProductId,
    variantId: item.destinationVariantId,
    quantity: item.quantity,
  }));
  const pricing = calculatePricingEngine({
    selectedPriceList,
    priceListItems,
    paymentTerm,
    campaigns,
    commercialRules,
    customerId: order.customerId,
    customerSegment,
    channel: 'internal',
    items: pricingItems,
    shippingAmount: 0,
  });

  const destinationTotal = pricing.items.reduce((sum, item) => sum + item.lineTotal, 0);
  const originTotal = items.reduce(
    (sum, item) => sum + item.originUnitPrice * item.quantity,
    0,
  );
  return roundCurrency(destinationTotal - originTotal);
}

function normalizeExchangeItems(value: unknown): ExchangeItemRecord[] {
  if (!Array.isArray(value)) return [];
  return value.map((item) => {
    const data = item as DocumentData;
    return {
      orderItemId: data.orderItemId as string,
      originProductId: data.originProductId as string,
      originVariantId: data.originVariantId as string,
      originUnitPrice: typeof data.originUnitPrice === 'number' ? data.originUnitPrice : 0,
      destinationVariantId: data.destinationVariantId as string,
      destinationProductId: data.destinationProductId as string,
      quantity: typeof data.quantity === 'number' ? data.quantity : 0,
    };
  });
}

function sumApprovedQuantities(approvedExchangeRequests: DocumentData[]): Map<string, number> {
  const totals = new Map<string, number>();
  for (const exchangeRequest of approvedExchangeRequests) {
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

function requireDecision(value: unknown): ExchangeRequestDecisionValue {
  if (typeof value !== 'string' || !DECIDABLE_STATUSES.has(value)) {
    throw new HttpsError('invalid-argument', 'decision must be either "approved" or "rejected".');
  }
  return value as ExchangeRequestDecisionValue;
}

function requireDataString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('internal', `Invalid exchange request record: ${field} is missing.`);
  }
  return value;
}

function roundCurrency(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function serializeDecision(
  exchangeRequestId: string,
  data: DocumentData,
  correlationId: string,
): ResolveExchangeRequestResponse {
  const status = data.status as string;
  if (status !== 'approved' && status !== 'rejected') {
    throw new HttpsError('internal', 'Invalid exchange request record for a decided troca.');
  }
  const decidedAt = (data.decidedAt as Timestamp | undefined) ?? (data.updatedAt as Timestamp);
  return {
    correlationId,
    exchangeRequestId,
    orderId: data.orderId as string,
    status,
    decidedBy: (data.decidedBy as string | null) ?? '',
    decidedAt: decidedAt.toDate().toISOString(),
    reason: (data.decisionReason as string | null) ?? null,
    priceDifferenceAmount:
      typeof data.priceDifferenceAmount === 'number' ? data.priceDifferenceAmount : undefined,
  };
}
