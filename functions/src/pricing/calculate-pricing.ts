import { createHash } from 'node:crypto';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  calculatePricingEngine,
  exceedsPricingTolerance,
  type PricingEngineCampaign,
  type PricingEngineDiscountPolicy,
  type PricingEngineItemInput,
  type PricingEnginePaymentTerm,
  type PricingEnginePriceList,
  type PricingEnginePriceListItem,
} from './pricing-engine';

export interface CalculatePricingRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  customerSegment?: string;
  priceListId?: string;
  paymentTermId?: string;
  idempotencyKey?: string;
  shippingAmount?: number;
  clientOrderTotal?: number;
  items?: PricingEngineItemInput[];
}

export interface CalculatePricingResponse {
  correlationId: string;
  idempotencyKey: string;
  currency: string;
  subtotal: number;
  campaignDiscountTotal: number;
  manualDiscountTotal: number;
  paymentTermAdjustmentTotal: number;
  shippingAmount: number;
  total: number;
  blocked: boolean;
  approvalRequired: boolean;
  clientTotalDiverged: boolean;
  tolerance: number;
  items: ReturnType<typeof calculatePricingEngine>['items'];
}

const tolerance = 0.01;
const alreadyExistsGrpcCode = 6;

export const calculatePricing = onCall<
  CalculatePricingRequest,
  Promise<CalculatePricingResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  }

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
  const customerSegment = requireNonEmptyString(request.data?.customerSegment, 'customerSegment');
  const priceListId = requireNonEmptyString(request.data?.priceListId, 'priceListId');
  const paymentTermId = requireNonEmptyString(request.data?.paymentTermId, 'paymentTermId');
  const idempotencyKey = requireNonEmptyString(
    request.data?.idempotencyKey,
    'idempotencyKey',
  );

  if (!Array.isArray(request.data?.items) || request.data.items.length === 0) {
    throw new HttpsError('invalid-argument', 'items is required.');
  }

  const normalizedItems = request.data.items.map((item, index) =>
    normalizeItem(item, index),
  );
  const shippingAmount = normalizeCurrency(request.data?.shippingAmount ?? 0, 'shippingAmount');
  const clientOrderTotal = request.data?.clientOrderTotal;
  if (
    clientOrderTotal !== undefined &&
    (typeof clientOrderTotal !== 'number' || Number.isNaN(clientOrderTotal))
  ) {
    throw new HttpsError('invalid-argument', 'clientOrderTotal must be numeric.');
  }

  const db = getFirestore();
  const orgRef = db.collection('organizations').doc(organizationId);
  const cacheRef = orgRef.collection('pricingCalculations').doc(idempotencyKey);
  const requestHash = createHash('sha256')
    .update(
      JSON.stringify({
        organizationId,
        companyId,
        customerSegment,
        priceListId,
        paymentTermId,
        shippingAmount,
        clientOrderTotal,
        items: normalizedItems,
      }),
    )
    .digest('hex');

  const cachedResponse = await loadCachedResponse(cacheRef, requestHash);
  if (cachedResponse) return cachedResponse;

  const membershipSnapshot = await orgRef.collection('members').doc(request.auth.uid).get();
  if (!membershipSnapshot.exists) {
    throw new HttpsError('permission-denied', 'Membership not found for pricing.');
  }
  const roleName = requireNonEmptyString(membershipSnapshot.data()?.roleName, 'roleName');

  const priceListSnapshot = await orgRef.collection('priceLists').doc(priceListId).get();
  if (!priceListSnapshot.exists) {
    throw new HttpsError('failed-precondition', 'Price list not found.');
  }
  const selectedPriceList = mapPriceList(priceListId, priceListSnapshot.data());
  ensureCompanyScope(companyId, 'Price list', selectedPriceList);
  ensureActivePriceList(selectedPriceList);

  const paymentTermSnapshot = await orgRef.collection('paymentTerms').doc(paymentTermId).get();
  if (!paymentTermSnapshot.exists) {
    throw new HttpsError('failed-precondition', 'Payment term not found.');
  }
  const paymentTerm = mapPaymentTerm(paymentTermId, paymentTermSnapshot.data());
  ensureCompanyScope(companyId, 'Payment term', paymentTerm);
  ensureValidPaymentTerm(paymentTerm, priceListId);

  const priceItemSnapshots = await orgRef
    .collection('priceLists')
    .doc(priceListId)
    .collection('items')
    .get();
  const priceListItems = priceItemSnapshots.docs.map((doc) =>
    mapPriceListItem(doc.data()),
  );
  priceListItems.forEach((item) => ensureCompanyScope(companyId, 'Price list item', item));

  const policiesSnapshot = await orgRef.collection('discountPolicies').get();
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

  const campaignSnapshots = await orgRef.collection('promotionalCampaigns').get();
  const campaigns = campaignSnapshots.docs.map((doc) =>
    mapCampaign(doc.id, doc.data()),
  );
  campaigns.forEach((campaign) => ensureCompanyScope(companyId, 'Campaign', campaign));

  const pricing = calculatePricingEngine({
    selectedPriceList,
    priceListItems,
    paymentTerm,
    discountPolicy,
    campaigns,
    customerSegment,
    items: normalizedItems,
    shippingAmount,
  });

  const response: CalculatePricingResponse = {
    correlationId,
    idempotencyKey,
    currency: pricing.currency,
    subtotal: pricing.subtotal,
    campaignDiscountTotal: pricing.campaignDiscountTotal,
    manualDiscountTotal: pricing.manualDiscountTotal,
    paymentTermAdjustmentTotal: pricing.paymentTermAdjustmentTotal,
    shippingAmount: pricing.shippingAmount,
    total: pricing.total,
    blocked: pricing.blocked,
    approvalRequired: pricing.approvalRequired,
    clientTotalDiverged:
      clientOrderTotal === undefined
        ? false
        : exceedsPricingTolerance(clientOrderTotal, pricing.total, tolerance),
    tolerance,
    items: pricing.items,
  };

  await persistIdempotentResponse(cacheRef, requestHash, response, request.auth.uid);

  logger.info('calculatePricing succeeded', {
    correlationId,
    organizationId,
    companyId,
    priceListId,
    paymentTermId,
    uid: request.auth.uid,
    idempotencyKey,
    itemCount: response.items.length,
    campaignDiscountTotal: response.campaignDiscountTotal,
    manualDiscountTotal: response.manualDiscountTotal,
    paymentTermAdjustmentTotal: response.paymentTermAdjustmentTotal,
    clientTotalDiverged: response.clientTotalDiverged,
    blocked: response.blocked,
    approvalRequired: response.approvalRequired,
    durationMs: Date.now() - startedAt,
  });

  return response;
});

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return value.trim();
}

function normalizeCurrency(value: unknown, field: string): number {
  if (typeof value !== 'number' || Number.isNaN(value) || value < 0) {
    throw new HttpsError('invalid-argument', `${field} must be zero or greater.`);
  }
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function normalizeItem(item: PricingEngineItemInput, index: number): PricingEngineItemInput {
  if (typeof item !== 'object' || item === null) {
    throw new HttpsError('invalid-argument', `items[${index}] is invalid.`);
  }
  const productId = requireNonEmptyString(item.productId, `items[${index}].productId`);
  if (
    typeof item.quantity !== 'number' ||
    Number.isNaN(item.quantity) ||
    item.quantity <= 0
  ) {
    throw new HttpsError(
      'invalid-argument',
      `items[${index}].quantity must be greater than zero.`,
    );
  }
  if (
    item.manualDiscountPercent !== undefined &&
    (typeof item.manualDiscountPercent !== 'number' ||
      Number.isNaN(item.manualDiscountPercent) ||
      item.manualDiscountPercent < 0 ||
      item.manualDiscountPercent > 100)
  ) {
    throw new HttpsError(
      'invalid-argument',
      `items[${index}].manualDiscountPercent must stay between 0 and 100.`,
    );
  }

  return {
    productId,
    quantity: item.quantity,
    variantId: optionalString(item.variantId),
    collectionId: optionalString(item.collectionId),
    categoryId: optionalString(item.categoryId),
    manualDiscountPercent: item.manualDiscountPercent,
  };
}

async function loadCachedResponse(
  cacheRef: FirebaseFirestore.DocumentReference,
  requestHash: string,
): Promise<CalculatePricingResponse | null> {
  const cached = await cacheRef.get();
  if (!cached.exists) return null;

  const data = cached.data();
  if (data?.requestHash !== requestHash) {
    throw new HttpsError(
      'already-exists',
      'idempotencyKey already used with a different payload.',
    );
  }
  return data.response as CalculatePricingResponse;
}

async function persistIdempotentResponse(
  cacheRef: FirebaseFirestore.DocumentReference,
  requestHash: string,
  response: CalculatePricingResponse,
  uid: string,
): Promise<void> {
  try {
    await cacheRef.create({
      requestHash,
      response,
      createdAt: Timestamp.now(),
      createdBy: uid,
    });
  } catch (error) {
    if (isAlreadyExistsError(error)) {
      const cachedResponse = await loadCachedResponse(cacheRef, requestHash);
      if (cachedResponse) {
        return;
      }
    }
    throw error;
  }
}

function optionalString(value: unknown): string | undefined {
  if (typeof value !== 'string') return undefined;
  const trimmed = value.trim();
  return trimmed.length === 0 ? undefined : trimmed;
}

function mapPriceList(id: string, data: FirebaseFirestore.DocumentData | undefined): PricingEnginePriceList {
  if (!data) throw new HttpsError('failed-precondition', 'Price list payload missing.');
  return {
    id,
    companyId: optionalString(data.companyId),
    currency: requireNonEmptyString(data.currency, 'currency'),
    status: requireNonEmptyString(data.status, 'status') as PricingEnginePriceList['status'],
    validFrom: serializeDate(data.validFrom),
    validTo: data.validTo ? serializeDate(data.validTo) : undefined,
  };
}

function ensureActivePriceList(priceList: PricingEnginePriceList): void {
  if (priceList.status !== 'active') {
    throw new HttpsError('failed-precondition', 'Price list is not active.');
  }
}

function mapPaymentTerm(
  id: string,
  data: FirebaseFirestore.DocumentData | undefined,
): PricingEnginePaymentTerm {
  if (!data) throw new HttpsError('failed-precondition', 'Payment term payload missing.');
  return {
    id,
    companyId: optionalString(data.companyId),
    name: requireNonEmptyString(data.name, 'name'),
    averageTermDays: Number(data.averageTermDays ?? 0),
    status: requireNonEmptyString(data.status, 'status') as PricingEnginePaymentTerm['status'],
    priceListIds: Array.isArray(data.priceListIds)
      ? data.priceListIds.filter((value): value is string => typeof value === 'string')
      : [],
  };
}

function ensureValidPaymentTerm(paymentTerm: PricingEnginePaymentTerm, priceListId: string): void {
  if (paymentTerm.status !== 'active') {
    throw new HttpsError('failed-precondition', 'Payment term is not active.');
  }
  if (paymentTerm.priceListIds.length > 0 && !paymentTerm.priceListIds.includes(priceListId)) {
    throw new HttpsError(
      'failed-precondition',
      'Payment term is not compatible with the selected price list.',
    );
  }
}

function mapPriceListItem(data: FirebaseFirestore.DocumentData): PricingEnginePriceListItem {
  return {
    productId: requireNonEmptyString(data.productId, 'productId'),
    variantId: optionalString(data.variantId),
    companyId: optionalString(data.companyId),
    price: normalizeCurrency(Number(data.price), 'price'),
  };
}

function mapDiscountPolicy(
  id: string,
  data: FirebaseFirestore.DocumentData,
): PricingEngineDiscountPolicy {
  return {
    id,
    companyId: optionalString(data.companyId),
    role: requireNonEmptyString(data.role, 'role'),
    maxDiscountPercent: Number(data.maxDiscountPercent ?? 0),
    requiresApprovalAbovePercent:
      data.requiresApprovalAbovePercent === undefined
        ? undefined
        : Number(data.requiresApprovalAbovePercent),
    priceListIds: Array.isArray(data.priceListIds)
      ? data.priceListIds.filter((value): value is string => typeof value === 'string')
      : [],
    status: requireNonEmptyString(data.status, 'status') as PricingEngineDiscountPolicy['status'],
  };
}

function mapCampaign(
  id: string,
  data: FirebaseFirestore.DocumentData,
): PricingEngineCampaign {
  return {
    id,
    companyId: optionalString(data.companyId),
    name: requireNonEmptyString(data.name, 'name'),
    customerSegment: requireNonEmptyString(data.customerSegment, 'customerSegment'),
    productIds: Array.isArray(data.productIds)
      ? data.productIds.filter((value): value is string => typeof value === 'string')
      : [],
    collectionIds: Array.isArray(data.collectionIds)
      ? data.collectionIds.filter((value): value is string => typeof value === 'string')
      : [],
    categoryIds: Array.isArray(data.categoryIds)
      ? data.categoryIds.filter((value): value is string => typeof value === 'string')
      : [],
    discountType: requireNonEmptyString(data.discountType, 'discountType') as PricingEngineCampaign['discountType'],
    discountValue: Number(data.discountValue ?? 0),
    stackableWithOtherCampaigns: Boolean(data.stackableWithOtherCampaigns),
    priority: Number(data.priority ?? 0),
    status: requireNonEmptyString(data.status, 'status') as PricingEngineCampaign['status'],
    validFrom: serializeDate(data.validFrom),
    validTo: serializeDate(data.validTo),
  };
}

function ensureCompanyScope(
  companyId: string,
  entityName: string,
  scopedEntity: { companyId?: string },
): void {
  if (scopedEntity.companyId && scopedEntity.companyId !== companyId) {
    throw new HttpsError(
      'failed-precondition',
      `${entityName} does not belong to the requested company.`,
    );
  }
}

function isAlreadyExistsError(error: unknown): boolean {
  if (!(error instanceof Error)) return false;
  const candidate = error as Error & { code?: string | number };
  return (
    candidate.code === 'already-exists' ||
    candidate.code === alreadyExistsGrpcCode
  );
}

function serializeDate(value: unknown): string {
  if (value instanceof Timestamp) {
    return value.toDate().toISOString();
  }
  if (value instanceof Date) {
    return value.toISOString();
  }
  if (typeof value === 'string' && value.trim().length > 0) {
    return new Date(value).toISOString();
  }
  throw new HttpsError('failed-precondition', 'Invalid date field.');
}
