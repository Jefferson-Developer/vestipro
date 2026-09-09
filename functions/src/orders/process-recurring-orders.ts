import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import {
  FieldValue,
  Timestamp,
  getFirestore,
  type DocumentData,
  type DocumentReference,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import {
  calculatePricingEngine,
  type PricingEngineItemInput,
  type PricingEngineOutput,
} from '../pricing/pricing-engine';
import {
  ensureCompanyScope,
  ensureActivePriceList,
  ensureValidPaymentTerm,
  mapCampaign,
  mapCommercialRule,
  mapDiscountPolicy,
  mapPaymentTerm,
  mapPriceList,
  mapPriceListItem,
  normalizeCurrency,
} from '../pricing/calculate-pricing';
import { asInt } from '../inventory/stock-reservation-shared';
import {
  buildApprovalChainInstance,
  enqueueApprovalNotifications,
} from './approval-chain';

export interface ProcessRecurringOrdersSummary {
  processedPlans: number;
  generatedOrders: number;
  reviewRequiredOrders: number;
  skippedPlans: number;
  notificationsCreated: number;
}

interface RecurringPlanItem {
  id: string;
  productId: string;
  variantId: string;
  quantity: number;
  collectionId?: string;
  categoryId?: string;
  manualDiscountPercent: number;
  expectedUnitPrice?: number;
}

interface FulfilledItem extends RecurringPlanItem {
  balanceRef?: DocumentReference;
}

const ACTIVE_PLAN_STATUS = 'active';
const PRICE_CHANGE_REVIEW_THRESHOLD_PERCENT = 0.01;
const NOTIFICATION_LOOKAHEAD_HOURS = 24;

export const processRecurringOrders = onSchedule(
  {
    schedule: 'every 1 hours',
    timeZone: 'America/Sao_Paulo',
  },
  async () => {
    const summary = await processRecurringOrdersHandler();
    logger.info('processRecurringOrders completed', summary);
  },
);

export async function processRecurringOrdersHandler(options: {
  db?: Firestore;
  now?: Date;
} = {}): Promise<ProcessRecurringOrdersSummary> {
  const db = options.db ?? getFirestore();
  const now = options.now ?? new Date();
  const nowTimestamp = Timestamp.fromDate(now);
  const notificationCutoff = Timestamp.fromDate(
    new Date(now.getTime() + NOTIFICATION_LOOKAHEAD_HOURS * 60 * 60 * 1000),
  );
  const summary: ProcessRecurringOrdersSummary = {
    processedPlans: 0,
    generatedOrders: 0,
    reviewRequiredOrders: 0,
    skippedPlans: 0,
    notificationsCreated: 0,
  };

  const organizations = await db.collection('organizations').get();
  for (const organization of organizations.docs) {
    const organizationRef = organization.ref;
    const notificationPlans = await organizationRef
      .collection('recurringOrderPlans')
      .where('status', '==', ACTIVE_PLAN_STATUS)
      .where('nextExecutionAt', '<=', notificationCutoff)
      .get();
    for (const planSnapshot of notificationPlans.docs) {
      const created = await maybeCreateExecutionNotification(
        organizationRef,
        planSnapshot.id,
        planSnapshot.data(),
        nowTimestamp,
      );
      if (created) summary.notificationsCreated += 1;
    }

    const duePlans = await organizationRef
      .collection('recurringOrderPlans')
      .where('status', '==', ACTIVE_PLAN_STATUS)
      .where('nextExecutionAt', '<=', nowTimestamp)
      .get();
    for (const planSnapshot of duePlans.docs) {
      summary.processedPlans += 1;
      const result = await processPlanTransaction(
        db,
        organizationRef,
        planSnapshot.id,
        nowTimestamp,
      );
      if (result === 'generated') summary.generatedOrders += 1;
      if (result === 'review_required') summary.reviewRequiredOrders += 1;
      if (result === 'skipped') summary.skippedPlans += 1;
    }
  }

  return summary;
}

async function maybeCreateExecutionNotification(
  organizationRef: DocumentReference,
  planId: string,
  plan: DocumentData,
  now: Timestamp,
): Promise<boolean> {
  const nextExecutionAt = plan.nextExecutionAt as Timestamp | undefined;
  if (!nextExecutionAt) return false;
  const marker = nextExecutionAt.toDate().toISOString();
  if (plan.notificationSentForNextExecutionAt === marker) return false;
  const sellerId = requireString(plan.sellerId, 'sellerId');
  const customerId = requireString(plan.customerId, 'customerId');
  const notificationRef = organizationRef.collection('notifications').doc();
  await notificationRef.set({
    organizationId: organizationRef.id,
    companyId: requireString(plan.companyId, 'companyId'),
    userId: sellerId,
    type: 'recurring_order_execution_due',
    title: 'Pedido recorrente programado',
    body: `Revise ou pule a rodada recorrente do cliente ${customerId}.`,
    deepLink: `/orders/recurring/${planId}`,
    data: {
      planId,
      customerId,
      nextExecutionAt: marker,
    },
    readAt: null,
    createdAt: now,
    createdBy: 'system',
  });
  await organizationRef.collection('recurringOrderPlans').doc(planId).set(
    {
      notificationSentForNextExecutionAt: marker,
      updatedAt: now,
      updatedBy: 'system',
    },
    { merge: true },
  );
  return true;
}

async function processPlanTransaction(
  db: Firestore,
  organizationRef: DocumentReference,
  planId: string,
  now: Timestamp,
): Promise<'generated' | 'review_required' | 'skipped'> {
  return db.runTransaction(async (transaction) => {
    const planRef = organizationRef.collection('recurringOrderPlans').doc(planId);
    const planSnapshot = await transaction.get(planRef);
    const plan = planSnapshot.data();
    if (!planSnapshot.exists || !plan || plan.status !== ACTIVE_PLAN_STATUS) {
      return 'skipped';
    }
    const nextExecutionAt = plan.nextExecutionAt as Timestamp | undefined;
    if (!nextExecutionAt || nextExecutionAt.toMillis() > now.toMillis()) {
      return 'skipped';
    }

    const executionKey = buildExecutionKey(planId, nextExecutionAt);
    const executionRef = organizationRef.collection('recurringOrderExecutions').doc(executionKey);
    const executionSnapshot = await transaction.get(executionRef);
    if (executionSnapshot.exists) {
      return 'skipped';
    }

    const companyId = requireString(plan.companyId, 'companyId');
    const customerId = requireString(plan.customerId, 'customerId');
    const sellerId = requireString(plan.sellerId, 'sellerId');
    const priceListId = requireString(plan.priceListId, 'priceListId');
    const paymentTermId = requireString(plan.paymentTermId, 'paymentTermId');
    const items = normalizeItems(plan.items);
    if (items.length === 0) {
      transaction.set(executionRef, {
        organizationId: organizationRef.id,
        companyId,
        planId,
        status: 'skipped',
        reason: 'plan_has_no_items',
        scheduledFor: nextExecutionAt,
        processedAt: now,
      });
      advancePlan(transaction, planRef, plan, now);
      return 'skipped';
    }

    const customerSnapshot = await transaction.get(
      organizationRef.collection('customers').doc(customerId),
    );
    const customer = customerSnapshot.data();
    if (!customerSnapshot.exists || !customer || customer.status !== 'active') {
      transaction.set(executionRef, {
        organizationId: organizationRef.id,
        companyId,
        planId,
        status: 'skipped',
        reason: 'customer_not_active',
        scheduledFor: nextExecutionAt,
        processedAt: now,
      });
      advancePlan(transaction, planRef, plan, now);
      return 'skipped';
    }

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
    const policiesSnapshot = await transaction.get(
      organizationRef.collection('discountPolicies'),
    );
    const discountPolicy = policiesSnapshot.docs
      .map((doc) => mapDiscountPolicy(doc.id, doc.data()))
      .find(
        (policy) =>
          (policy.companyId === undefined || policy.companyId === companyId) &&
          policy.role === 'SALES_REP' &&
          policy.status === 'active' &&
          (!policy.priceListIds?.length || policy.priceListIds.includes(priceListId)),
      );
    const campaigns = (await transaction.get(
      organizationRef.collection('promotionalCampaigns'),
    )).docs.map((doc) => mapCampaign(doc.id, doc.data()));
    const commercialRules = (await transaction.get(
      organizationRef.collection('commercialRules'),
    )).docs.map((doc) => mapCommercialRule(doc.id, doc.data()));
    const approvalPolicies = await transaction.get(
      organizationRef.collection('approvalPolicies'),
    );
    const availability = await resolveAvailability(transaction, organizationRef, items);
    const fulfilledItems = items.filter((item) => availability.get(item.id)?.available);
    const unavailableItems = items.filter((item) => !availability.get(item.id)?.available);

    if (fulfilledItems.length === 0) {
      transaction.set(executionRef, {
        organizationId: organizationRef.id,
        companyId,
        planId,
        status: 'skipped',
        reason: 'no_items_available',
        unavailableItems: unavailableItems.map(serializePlanItem),
        scheduledFor: nextExecutionAt,
        processedAt: now,
      });
      advancePlan(transaction, planRef, plan, now);
      return 'skipped';
    }

    const pricingItems: PricingEngineItemInput[] = fulfilledItems.map((item) => ({
      productId: item.productId,
      variantId: item.variantId,
      quantity: item.quantity,
      collectionId: item.collectionId,
      categoryId: item.categoryId,
      manualDiscountPercent: item.manualDiscountPercent,
    }));
    const pricing = calculatePricingEngine({
      selectedPriceList,
      priceListItems,
      paymentTerm,
      discountPolicy,
      campaigns,
      commercialRules,
      customerId,
      customerSegment: typeof customer.segment === 'string' ? customer.segment : '',
      channel: 'recurring_order',
      items: pricingItems,
      shippingAmount: normalizeCurrency(plan.shippingAmount ?? 0, 'shippingAmount'),
    });
    const priceChanges = resolvePriceChanges(fulfilledItems, pricing);
    const reviewRequired = unavailableItems.length > 0 || priceChanges.length > 0;
    const orderId = `recurring_${executionKey}`;
    const sequenceRef = organizationRef.collection('orderNumberSequences').doc(companyId);
    const sequenceSnapshot = await transaction.get(sequenceRef);
    const nextSequence = asInt(sequenceSnapshot.data()?.lastValue) + 1;
    const orderNumber = nextSequence.toString().padStart(6, '0');
    const responseItems = pricing.items.map((item, index) => ({
      id: fulfilledItems[index]!.id,
      productId: item.productId,
      variantId: item.variantId ?? null,
      quantity: item.quantity,
      unitPrice: item.finalUnitPrice,
      discountAmount: roundCurrency(item.lineSubtotal - item.lineTotal),
      surchargeAmount: 0,
      subtotal: item.lineTotal,
    }));
    const approvalReason = pricing.approvalRequired
      ? 'Pedido recorrente requer aprovacao por politica comercial vigente.'
      : null;
    const approvalChain = approvalReason
      ? buildApprovalChainInstance(
          approvalPolicies.docs.map((doc) => ({ id: doc.id, data: doc.data() })),
          companyId,
          pricing,
          approvalReason,
        )
      : null;
    const initialStatus = reviewRequired
      ? 'draft_review_required'
      : pricing.approvalRequired ? 'under_review' : 'submitted';

    transaction.set(sequenceRef, {
      organizationId: organizationRef.id,
      companyId,
      lastValue: nextSequence,
      updatedAt: now,
      updatedBy: 'system',
    }, { merge: true });
    transaction.set(organizationRef.collection('orders').doc(orderId), {
      organizationId: organizationRef.id,
      companyId,
      branchId: requireString(plan.branchId, 'branchId'),
      customerId,
      sellerId,
      orderNumber,
      deliveryAddress: normalizeAddress(plan.deliveryAddress),
      billingAddress: normalizeAddress(plan.billingAddress),
      priceListId,
      currency: selectedPriceList.currency,
      paymentTermId,
      carrierId: plan.carrierId ?? null,
      collectionId: plan.collectionId ?? null,
      orderType: plan.orderType ?? 'recurring',
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
      notes: plan.notes ?? null,
      attachmentUrls: [],
      status: initialStatus,
      statusHistory: [{
        previousStatus: null,
        newStatus: initialStatus,
        changedAt: now,
        actorId: 'system',
        reason: reviewRequired
          ? 'Pedido recorrente gerado para revisao por diferencas de preco/estoque.'
          : approvalReason,
      }],
      approvedBy: null,
      approvedAt: null,
      rejectionReason: null,
      pricingApprovalRequired: pricing.approvalRequired,
      approvalChain,
      submittedVia: 'recurring_order',
      recurringOrderPlanId: planId,
      recurringOrderExecutionKey: executionKey,
      recurringOrderDifferences: {
        unavailableItems: unavailableItems.map(serializePlanItem),
        priceChanges,
      },
      idempotencyKey: orderId,
      createdAt: now,
      createdBy: 'system',
      updatedAt: now,
      updatedBy: 'system',
      deletedAt: null,
      version: 1,
      syncStatus: 'synced',
    });
    if (!reviewRequired) {
      applyStockMovements(transaction, fulfilledItems, availability, now);
      const firstApprovalLevel = approvalChain?.levels[0];
      if (initialStatus === 'under_review' && firstApprovalLevel) {
        await enqueueApprovalNotifications(transaction, organizationRef, {
          organizationId: organizationRef.id,
          companyId,
          orderId,
          orderNumber,
          level: firstApprovalLevel,
          now,
          actorId: 'system',
        });
      }
    }
    transaction.set(executionRef, {
      organizationId: organizationRef.id,
      companyId,
      planId,
      orderId,
      orderNumber,
      status: reviewRequired ? 'review_required' : 'generated',
      scheduledFor: nextExecutionAt,
      processedAt: now,
      unavailableItems: unavailableItems.map(serializePlanItem),
      priceChanges,
    });
    advancePlan(transaction, planRef, plan, now);
    return reviewRequired ? 'review_required' : 'generated';
  });
}

function normalizeItems(value: unknown): RecurringPlanItem[] {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item): item is DocumentData => typeof item === 'object' && item !== null)
    .map((item) => ({
      id: requireString(item.id, 'items.id'),
      productId: requireString(item.productId, 'items.productId'),
      variantId: requireString(item.variantId, 'items.variantId'),
      quantity: asInt(item.quantity),
      collectionId: optionalString(item.collectionId),
      categoryId: optionalString(item.categoryId),
      manualDiscountPercent: typeof item.manualDiscountPercent === 'number'
        ? item.manualDiscountPercent
        : 0,
      expectedUnitPrice: typeof item.expectedUnitPrice === 'number'
        ? item.expectedUnitPrice
        : undefined,
    }))
    .filter((item) => item.quantity > 0);
}

async function resolveAvailability(
  transaction: Transaction,
  organizationRef: DocumentReference,
  items: RecurringPlanItem[],
): Promise<Map<string, { available: boolean; balanceRef?: DocumentReference }>> {
  const result = new Map<string, { available: boolean; balanceRef?: DocumentReference }>();
  for (const item of items) {
    const balances = await transaction.get(
      organizationRef.collection('inventory').where('variantId', '==', item.variantId),
    );
    if (balances.empty) {
      result.set(item.id, { available: true });
      continue;
    }
    const balance = balances.docs
      .map((doc) => ({ ref: doc.ref, data: doc.data() }))
      .find((doc) =>
        asInt(doc.data.physicalQuantity) -
          asInt(doc.data.reservedQuantity) -
          asInt(doc.data.blockedQuantity) >= item.quantity,
      );
    result.set(item.id, balance ? { available: true, balanceRef: balance.ref } : { available: false });
  }
  return result;
}

function resolvePriceChanges(
  items: RecurringPlanItem[],
  pricing: PricingEngineOutput,
): DocumentData[] {
  const changes: DocumentData[] = [];
  pricing.items.forEach((item, index) => {
    const source = items[index]!;
    if (source.expectedUnitPrice === undefined) return;
    const delta = Math.abs(item.finalUnitPrice - source.expectedUnitPrice);
    const percent = source.expectedUnitPrice === 0
      ? 100
      : (delta / source.expectedUnitPrice) * 100;
    if (percent <= PRICE_CHANGE_REVIEW_THRESHOLD_PERCENT) return;
    changes.push({
      productId: source.productId,
      variantId: source.variantId,
      expectedUnitPrice: source.expectedUnitPrice,
      currentUnitPrice: item.finalUnitPrice,
      percent: roundCurrency(percent),
    });
  });
  return changes;
}

function applyStockMovements(
  transaction: Transaction,
  items: FulfilledItem[],
  availability: Map<string, { available: boolean; balanceRef?: DocumentReference }>,
  now: Timestamp,
): void {
  for (const item of items) {
    const balanceRef = availability.get(item.id)?.balanceRef;
    if (!balanceRef) continue;
    transaction.set(balanceRef, {
      physicalQuantity: FieldValue.increment(-item.quantity),
      updatedAt: now,
      updatedBy: 'system',
      lastSource: 'recurring_order',
      version: FieldValue.increment(1),
    }, { merge: true });
  }
}

function advancePlan(
  transaction: Transaction,
  planRef: DocumentReference,
  plan: DocumentData,
  now: Timestamp,
): void {
  const frequency = plan.frequency as DocumentData | undefined;
  const interval = Math.max(1, asInt(frequency?.interval));
  const unit = frequency?.unit === 'weeks' ? 'weeks' : 'days';
  const previous = plan.nextExecutionAt as Timestamp;
  const date = previous.toDate();
  if (unit === 'weeks') {
    date.setUTCDate(date.getUTCDate() + interval * 7);
  } else {
    date.setUTCDate(date.getUTCDate() + interval);
  }
  transaction.update(planRef, {
    nextExecutionAt: Timestamp.fromDate(date),
    notificationSentForNextExecutionAt: null,
    lastProcessedAt: now,
    updatedAt: now,
    updatedBy: 'system',
    version: FieldValue.increment(1),
  });
}

function buildExecutionKey(planId: string, scheduledFor: Timestamp): string {
  return `${planId}_${scheduledFor.toDate().toISOString().slice(0, 10)}`;
}

function normalizeAddress(value: unknown): DocumentData {
  const data = typeof value === 'object' && value !== null ? value as DocumentData : {};
  return {
    street: requireString(data.street, 'address.street'),
    number: optionalString(data.number) ?? null,
    complement: optionalString(data.complement) ?? null,
    district: optionalString(data.district) ?? null,
    city: requireString(data.city, 'address.city'),
    state: requireString(data.state, 'address.state'),
    zipCode: requireString(data.zipCode, 'address.zipCode'),
    country: optionalString(data.country) ?? 'BR',
  };
}

function serializePlanItem(item: RecurringPlanItem): DocumentData {
  return {
    id: item.id,
    productId: item.productId,
    variantId: item.variantId,
    quantity: item.quantity,
  };
}

function requireString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(`${field} is required.`);
  }
  return value.trim();
}

function optionalString(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0 ? value.trim() : undefined;
}

function roundCurrency(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}
