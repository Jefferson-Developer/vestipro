import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import {
  FieldValue,
  Timestamp,
  getFirestore,
  type DocumentData,
  type DocumentReference,
  type Transaction,
} from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';
import { asInt, requirePositiveInteger } from '../inventory/stock-reservation-shared';
import {
  calculatePricingEngine,
  type PricingEngineItemInput,
  type PricingEngineOutput,
} from '../pricing/pricing-engine';
import {
  ensureActivePriceList,
  ensureCompanyScope,
  ensureValidPaymentTerm,
  mapCampaign,
  mapCommercialRule,
  mapDiscountPolicy,
  mapPaymentTerm,
  mapPriceList,
  mapPriceListItem,
  normalizeCurrency,
  optionalString,
} from '../pricing/calculate-pricing';
import { serializeQuote, type QuoteResponse } from './quote-shared';

export interface ConvertQuoteToOrderRequest extends RequestWithMeta {
  organizationId?: string;
  quoteId?: string;
  orderId?: string;
  acceptChanges?: boolean;
}

export interface ConvertQuoteToOrderResponse {
  quote: QuoteResponse;
  orderId?: string;
  orderNumber?: string;
  totalChanged: boolean;
  availabilityChanged: boolean;
  currentTotal?: number;
  message?: string;
}

interface NormalizedQuoteItem {
  id: string;
  productId: string;
  variantId: string;
  quantity: number;
  collectionId?: string;
  categoryId?: string;
  manualDiscountPercent: number;
}

interface ItemAvailabilityPlan {
  balanceRef?: DocumentReference;
  quantity?: number;
}

const ROLES_ALLOWED_TO_CONVERT_QUOTE: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
  'SALES_REP',
]);

/**
 * Converts a quote only after revalidating the current price and stock
 * situation. The original quote remains the display snapshot; the order is
 * persisted with current pricing, stock movement and a real per-company order
 * sequence, never with stale values copied silently from the quote.
 */
export const convertQuoteToOrder = onCall<
  ConvertQuoteToOrderRequest,
  Promise<ConvertQuoteToOrderResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
  }

  const uid = request.auth.uid;
  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const quoteId = requireNonEmptyString(request.data?.quoteId, 'quoteId');
  const orderId = requireNonEmptyString(request.data?.orderId, 'orderId');
  const acceptChanges = request.data?.acceptChanges === true;

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_CONVERT_QUOTE.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Seu perfil nao pode converter orcamentos.');
  }

  const actorName = await resolveActorName(db, uid, request.auth.token);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const quoteRef = organizationRef.collection('quotes').doc(quoteId);
  const quoteSnapshot = await quoteRef.get();
  const quote = quoteSnapshot.data();
  if (!quoteSnapshot.exists || !quote) {
    throw new HttpsError('not-found', 'Orcamento nao encontrado.');
  }
  if (quote.status !== 'sent') {
    throw new HttpsError('failed-precondition', 'Somente orcamentos enviados podem ser convertidos.');
  }

  const expiresAt = quote.expiresAt instanceof Timestamp ? quote.expiresAt.toMillis() : 0;
  if (expiresAt <= Date.now()) {
    await quoteRef.set(
      { status: 'expired', updatedAt: Timestamp.now(), updatedBy: uid },
      { merge: true },
    );
    throw new HttpsError('failed-precondition', 'Este orcamento venceu. Gere uma nova cotacao.');
  }

  const companyId = requireNonEmptyString(quote.companyId, 'quote.companyId');
  const sellerId = requireNonEmptyString(quote.sellerId, 'quote.sellerId');
  if (sellerId !== uid && membership.roleName !== 'OWNER' && membership.roleName !== 'ADMIN') {
    throw new HttpsError('permission-denied', 'O orcamento deve ser convertido pelo vendedor responsavel.');
  }

  const customerId = requireNonEmptyString(quote.customerId, 'quote.customerId');
  const priceListId = requireNonEmptyString(quote.priceListId, 'quote.priceListId');
  const paymentTermId = requireNonEmptyString(quote.paymentTermId, 'quote.paymentTermId');
  const items = normalizeQuoteItems(quote.items, quote.collectionId);
  const shippingAmount = normalizeCurrency(quote.shippingAmount ?? 0, 'quote.shippingAmount');

  const customerSnapshot = await organizationRef.collection('customers').doc(customerId).get();
  const customerData = customerSnapshot.data();
  if (!customerSnapshot.exists || !customerData) {
    throw new HttpsError('failed-precondition', 'Customer not found.');
  }
  if (customerData.companyId !== companyId) {
    throw new HttpsError('failed-precondition', 'Customer does not belong to the requested company.');
  }
  const customerSegment =
    typeof customerData.segment === 'string' && customerData.segment.trim().length > 0
      ? customerData.segment.trim()
      : 'default';

  const pricing = await resolveCurrentPricing({
    organizationRef,
    companyId,
    roleName: membership.roleName,
    customerId,
    customerSegment,
    priceListId,
    paymentTermId,
    items,
    shippingAmount,
  });

  const quotedTotal = asNumber(quote.total);
  const totalChanged = Math.abs(pricing.total - quotedTotal) > 0.01;
  const availabilityChanged = !(await canFulfillAllItems(organizationRef, items));
  if ((totalChanged || availabilityChanged) && !acceptChanges) {
    return {
      quote: serializeQuote(quoteId, quote),
      totalChanged,
      availabilityChanged,
      currentTotal: pricing.total,
      message: totalChanged
        ? 'O valor atual diverge do orcamento. Confirme a diferenca antes de converter.'
        : 'A disponibilidade mudou desde o orcamento. Revise os itens antes de converter.',
    };
  }
  if (availabilityChanged) {
    throw new HttpsError(
      'failed-precondition',
      'A disponibilidade mudou desde o orcamento. Ajuste os itens antes de converter.',
    );
  }

  const orderRef = organizationRef.collection('orders').doc(orderId);
  const result = await db.runTransaction<ConvertQuoteToOrderResponse>(async (transaction) => {
    const existingOrder = await transaction.get(orderRef);
    if (existingOrder.exists) {
      throw new HttpsError('already-exists', 'Este orcamento ja foi convertido em pedido.');
    }

    const freshQuote = await transaction.get(quoteRef);
    const freshQuoteData = freshQuote.data();
    if (!freshQuote.exists || !freshQuoteData || freshQuoteData.status !== 'sent') {
      throw new HttpsError('failed-precondition', 'Este orcamento nao esta mais disponivel para conversao.');
    }

    const availability = await resolveItemAvailability(transaction, organizationRef, items);
    const sequenceRef = organizationRef.collection('orderNumberSequences').doc(companyId);
    const sequenceSnapshot = await transaction.get(sequenceRef);
    const nextSequence = asInt(sequenceSnapshot.data()?.lastValue) + 1;
    const orderNumber = nextSequence.toString().padStart(6, '0');
    const now = Timestamp.now();
    const responseItems = pricing.items.map((item, index) => ({
      id: items[index]?.id ?? `${index}`,
      productId: item.productId,
      variantId: item.variantId ?? null,
      quantity: item.quantity,
      unitPrice: item.finalUnitPrice,
      discountAmount: roundCurrency(item.lineSubtotal - item.lineTotal),
      surchargeAmount: 0,
      subtotal: item.lineTotal,
    }));
    const initialStatus = pricing.approvalRequired ? 'under_review' : 'submitted';
    const approvalReason = pricing.approvalRequired
      ? 'Pedido convertido de orcamento com desconto ou condicao comercial que exige aprovacao.'
      : `Convertido do orcamento ${quoteId}`;

    transaction.set(
      sequenceRef,
      { organizationId, companyId, lastValue: nextSequence, updatedAt: now, updatedBy: uid },
      { merge: true },
    );
    transaction.set(orderRef, {
      organizationId,
      companyId,
      branchId: requireNonEmptyString(freshQuoteData.branchId, 'quote.branchId'),
      customerId,
      sellerId,
      orderNumber,
      deliveryAddress: freshQuoteData.deliveryAddress,
      billingAddress: freshQuoteData.billingAddress,
      priceListId,
      currency: pricing.currency,
      paymentTermId,
      carrierId: freshQuoteData.carrierId ?? null,
      collectionId: freshQuoteData.collectionId ?? null,
      orderType: freshQuoteData.orderType ?? null,
      items: responseItems,
      discountAmount: roundCurrency(
        pricing.campaignDiscountTotal +
          pricing.commercialRuleDiscountTotal +
          pricing.manualDiscountTotal,
      ),
      commercialRuleDiscountAmount: roundCurrency(pricing.commercialRuleDiscountTotal),
      pricingCommercialRuleTrace: pricing.commercialRuleTrace,
      pricingAppliedPaymentTermRuleId: pricing.appliedPaymentTermRuleId ?? null,
      surchargeAmount: roundCurrency(pricing.paymentTermAdjustmentTotal),
      shippingAmount: roundCurrency(pricing.shippingAmount),
      taxAmount: null,
      notes: freshQuoteData.notes ?? null,
      attachmentUrls: [],
      status: initialStatus,
      statusHistory: [{
        previousStatus: null,
        newStatus: initialStatus,
        changedAt: now,
        actorId: uid,
        reason: approvalReason,
      }],
      approvedBy: null,
      approvedAt: null,
      rejectionReason: null,
      pricingApprovalRequired: pricing.approvalRequired,
      quoteId,
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
      deletedAt: null,
      version: 1,
      syncStatus: 'synced',
    });
    applyStockMovements(transaction, availability, { uid, now });
    transaction.set(quoteRef, {
      status: 'converted',
      convertedOrderId: orderId,
      convertedAt: now,
      convertedBy: uid,
      updatedAt: now,
      updatedBy: uid,
    }, { merge: true });
    transaction.set(organizationRef.collection('auditLogs').doc(), {
      organizationId,
      actorUserId: uid,
      actorName,
      action: 'quote.converted',
      entityType: 'quote',
      entityId: quoteId,
      previousValue: { status: 'sent', total: quotedTotal },
      newValue: { status: 'converted', orderId, orderNumber, total: pricing.total },
      timestamp: now,
    });

    return {
      quote: serializeQuote(quoteId, { ...freshQuoteData, status: 'converted', convertedOrderId: orderId }),
      orderId,
      orderNumber,
      totalChanged,
      availabilityChanged: false,
      currentTotal: pricing.total,
    };
  });

  logger.info('convertQuoteToOrder succeeded', {
    correlationId,
    organizationId,
    quoteId,
    orderId,
    orderNumber: result.orderNumber,
    totalChanged,
    durationMs: Date.now() - startedAt,
  });
  return result;
});

async function resolveCurrentPricing(input: {
  organizationRef: DocumentReference;
  companyId: string;
  roleName: string;
  customerId: string;
  customerSegment: string;
  priceListId: string;
  paymentTermId: string;
  items: NormalizedQuoteItem[];
  shippingAmount: number;
}): Promise<PricingEngineOutput> {
  const {
    organizationRef,
    companyId,
    roleName,
    customerId,
    customerSegment,
    priceListId,
    paymentTermId,
    items,
    shippingAmount,
  } = input;
  const priceListSnapshot = await organizationRef.collection('priceLists').doc(priceListId).get();
  const selectedPriceList = mapPriceList(priceListId, priceListSnapshot.data());
  ensureCompanyScope(companyId, 'Price list', selectedPriceList);
  ensureActivePriceList(selectedPriceList);

  const paymentTermSnapshot = await organizationRef.collection('paymentTerms').doc(paymentTermId).get();
  const paymentTerm = mapPaymentTerm(paymentTermId, paymentTermSnapshot.data());
  ensureCompanyScope(companyId, 'Payment term', paymentTerm);
  ensureValidPaymentTerm(paymentTerm, priceListId);

  const priceItemSnapshots = await organizationRef
    .collection('priceLists')
    .doc(priceListId)
    .collection('items')
    .get();
  const priceListItems = priceItemSnapshots.docs.map((doc) => mapPriceListItem(doc.data()));
  priceListItems.forEach((item) => ensureCompanyScope(companyId, 'Price list item', item));

  const policiesSnapshot = await organizationRef.collection('discountPolicies').get();
  const discountPolicy = policiesSnapshot.docs
    .map((doc) => mapDiscountPolicy(doc.id, doc.data()))
    .find(
      (policy) =>
        (policy.companyId === undefined || policy.companyId === companyId) &&
        policy.role === roleName &&
        policy.status === 'active' &&
        (policy.priceListIds === undefined ||
          policy.priceListIds.length === 0 ||
          policy.priceListIds.includes(priceListId)),
    );
  const campaignSnapshots = await organizationRef.collection('promotionalCampaigns').get();
  const campaigns = campaignSnapshots.docs.map((doc) => mapCampaign(doc.id, doc.data()));
  campaigns.forEach((campaign) => ensureCompanyScope(companyId, 'Campaign', campaign));
  const commercialRuleSnapshots = await organizationRef.collection('commercialRules').get();
  const commercialRules = commercialRuleSnapshots.docs.map((doc) => mapCommercialRule(doc.id, doc.data()));
  commercialRules.forEach((rule) => ensureCompanyScope(companyId, 'Commercial rule', rule));

  const pricing = calculatePricingEngine({
    selectedPriceList,
    priceListItems,
    paymentTerm,
    discountPolicy,
    campaigns,
    commercialRules,
    customerId,
    customerSegment,
    channel: 'quote_conversion',
    items: items.map(toPricingItem),
    shippingAmount,
  });
  if (pricing.blocked) {
    throw new HttpsError('failed-precondition', 'Um desconto aplicado esta fora do limite permitido.');
  }
  return pricing;
}

function normalizeQuoteItems(value: unknown, collectionId: unknown): NormalizedQuoteItem[] {
  if (!Array.isArray(value) || value.length === 0) {
    throw new HttpsError('failed-precondition', 'O orcamento nao possui itens.');
  }
  return value.map((item, index) => {
    if (typeof item !== 'object' || item === null) {
      throw new HttpsError('failed-precondition', `quote.items[${index}] is invalid.`);
    }
    const data = item as DocumentData;
    return {
      id: requireNonEmptyString(data.id, `quote.items[${index}].id`),
      productId: requireNonEmptyString(data.productId, `quote.items[${index}].productId`),
      variantId: requireNonEmptyString(data.variantId, `quote.items[${index}].variantId`),
      quantity: requirePositiveInteger(data.quantity, `quote.items[${index}].quantity`),
      collectionId: optionalString(collectionId),
      categoryId: optionalString(data.categoryId),
      manualDiscountPercent: 0,
    };
  });
}

function toPricingItem(item: NormalizedQuoteItem): PricingEngineItemInput {
  return {
    productId: item.productId,
    variantId: item.variantId,
    quantity: item.quantity,
    collectionId: item.collectionId,
    categoryId: item.categoryId,
    manualDiscountPercent: item.manualDiscountPercent,
  };
}

async function canFulfillAllItems(
  organizationRef: DocumentReference,
  items: NormalizedQuoteItem[],
): Promise<boolean> {
  for (const item of items) {
    const snapshots = await organizationRef
      .collection('inventory')
      .where('variantId', '==', item.variantId)
      .get();
    if (snapshots.empty) continue;
    const fulfillable = snapshots.docs.some((doc) => sellableQuantity(doc.data()) >= item.quantity);
    if (!fulfillable) return false;
  }
  return true;
}

async function resolveItemAvailability(
  transaction: Transaction,
  organizationRef: DocumentReference,
  items: NormalizedQuoteItem[],
): Promise<Map<string, ItemAvailabilityPlan>> {
  const plans = new Map<string, ItemAvailabilityPlan>();
  for (const item of items) {
    const balanceSnapshots = await transaction.get(
      organizationRef.collection('inventory').where('variantId', '==', item.variantId),
    );
    if (balanceSnapshots.empty) {
      plans.set(item.id, {});
      continue;
    }
    const fulfillable = balanceSnapshots.docs
      .map((doc) => ({ ref: doc.ref, data: doc.data() }))
      .filter((balance) => sellableQuantity(balance.data) >= item.quantity)
      .sort((left, right) => left.ref.id.localeCompare(right.ref.id))[0];
    if (!fulfillable) {
      throw new HttpsError(
        'failed-precondition',
        'A quantidade solicitada nao esta disponivel em estoque para um dos itens.',
      );
    }
    plans.set(item.id, { balanceRef: fulfillable.ref, quantity: item.quantity });
  }
  return plans;
}

function applyStockMovements(
  transaction: Transaction,
  availability: Map<string, ItemAvailabilityPlan>,
  context: { uid: string; now: Timestamp },
): void {
  availability.forEach((plan) => {
    if (!plan.balanceRef) return;
    transaction.set(
      plan.balanceRef,
      {
        physicalQuantity: FieldValue.increment(-(plan.quantity ?? 0)),
        updatedAt: context.now,
        updatedBy: context.uid,
        lastSource: 'quote_conversion',
        version: FieldValue.increment(1),
      },
      { merge: true },
    );
  });
}

function sellableQuantity(data: DocumentData | undefined): number {
  return asInt(data?.physicalQuantity) - asInt(data?.reservedQuantity) - asInt(data?.blockedQuantity);
}

function asNumber(value: unknown): number {
  return typeof value === 'number' && !Number.isNaN(value) ? value : 0;
}

function roundCurrency(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}
