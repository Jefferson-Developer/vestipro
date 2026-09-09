import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore, type DocumentData } from 'firebase-admin/firestore';
import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString,
  resolveActorName,
} from '../invites/invite-shared';
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
  mapDiscountPolicy,
  mapPaymentTerm,
  mapPriceList,
  mapPriceListItem,
  normalizeCurrency,
  normalizeItem,
  optionalString,
} from '../pricing/calculate-pricing';
import { serializeQuote, type QuoteResponse } from './quote-shared';
import type { SubmitOrderAddressInput, SubmitOrderItemInput } from './submit-order';

const ROLES_ALLOWED_TO_GENERATE_QUOTE: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
  'SALES_REP',
]);

export interface GenerateQuoteRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  quoteId?: string;
  orderDraftId?: string;
  branchId?: string;
  customerId?: string;
  sellerId?: string;
  deliveryAddress?: SubmitOrderAddressInput;
  billingAddress?: SubmitOrderAddressInput;
  priceListId?: string;
  paymentTermId?: string;
  carrierId?: string;
  collectionId?: string;
  orderType?: string;
  items?: SubmitOrderItemInput[];
  notes?: string;
  shippingAmount?: number;
  validityDays?: number;
}

export const generateQuote = onCall<GenerateQuoteRequest, Promise<QuoteResponse>>(
  async (request) => {
    const startedAt = Date.now();
    const correlationId = resolveCorrelationId(request.data?._meta);
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
    }

    const uid = request.auth.uid;
    const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
    const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
    const quoteId = requireNonEmptyString(request.data?.quoteId, 'quoteId');
    const orderDraftId = requireNonEmptyString(request.data?.orderDraftId, 'orderDraftId');
    const branchId = requireNonEmptyString(request.data?.branchId, 'branchId');
    const customerId = requireNonEmptyString(request.data?.customerId, 'customerId');
    const sellerId = requireNonEmptyString(request.data?.sellerId, 'sellerId');
    const priceListId = requireNonEmptyString(request.data?.priceListId, 'priceListId');
    const paymentTermId = requireNonEmptyString(request.data?.paymentTermId, 'paymentTermId');
    const shippingAmount = normalizeCurrency(request.data?.shippingAmount ?? 0, 'shippingAmount');
    const validityDays = normalizeValidityDays(request.data?.validityDays);
    const items = requireQuoteItems(request.data?.items);

    const db = getFirestore();
    const membership = await loadActiveMembership(db, organizationId, uid);
    if (!ROLES_ALLOWED_TO_GENERATE_QUOTE.has(membership.roleName)) {
      throw new HttpsError('permission-denied', 'Seu perfil nao pode gerar orcamentos.');
    }
    if (sellerId !== uid && membership.roleName !== 'OWNER' && membership.roleName !== 'ADMIN') {
      throw new HttpsError('permission-denied', 'O orcamento deve ser gerado pelo vendedor responsavel.');
    }

    const actorName = await resolveActorName(db, uid, request.auth.token);
    const orgRef = db.collection('organizations').doc(organizationId);
    const quoteRef = orgRef.collection('quotes').doc(quoteId);

    const result = await db.runTransaction<QuoteResponse>(async (transaction) => {
      const existing = await transaction.get(quoteRef);
      if (existing.exists) {
        return serializeQuote(quoteId, existing.data() ?? {});
      }

      const customerSnapshot = await transaction.get(orgRef.collection('customers').doc(customerId));
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

      const priceListSnapshot = await transaction.get(orgRef.collection('priceLists').doc(priceListId));
      const selectedPriceList = mapPriceList(priceListId, priceListSnapshot.data());
      ensureCompanyScope(companyId, 'Price list', selectedPriceList);
      ensureActivePriceList(selectedPriceList);

      const paymentTermSnapshot = await transaction.get(orgRef.collection('paymentTerms').doc(paymentTermId));
      const paymentTerm = mapPaymentTerm(paymentTermId, paymentTermSnapshot.data());
      ensureCompanyScope(companyId, 'Payment term', paymentTerm);
      ensureValidPaymentTerm(paymentTerm, priceListId);

      const priceItemSnapshots = await transaction.get(
        orgRef.collection('priceLists').doc(priceListId).collection('items'),
      );
      const priceListItems = priceItemSnapshots.docs.map((doc) => mapPriceListItem(doc.data()));
      priceListItems.forEach((item) => ensureCompanyScope(companyId, 'Price list item', item));

      const policiesSnapshot = await transaction.get(orgRef.collection('discountPolicies'));
      const discountPolicy = policiesSnapshot.docs
        .map((doc) => mapDiscountPolicy(doc.id, doc.data()))
        .find(
          (policy) =>
            (policy.companyId === undefined || policy.companyId === companyId) &&
            policy.role === membership.roleName &&
            policy.status === 'active' &&
            (policy.priceListIds === undefined ||
              policy.priceListIds.length === 0 ||
              policy.priceListIds.includes(priceListId)),
        );

      const campaignSnapshots = await transaction.get(orgRef.collection('promotionalCampaigns'));
      const campaigns = campaignSnapshots.docs.map((doc) => mapCampaign(doc.id, doc.data()));
      campaigns.forEach((campaign) => ensureCompanyScope(companyId, 'Campaign', campaign));

      const commercialRuleSnapshots = await transaction.get(orgRef.collection('commercialRules'));
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
        channel: 'quote',
        items,
        shippingAmount,
      });
      if (pricing.blocked) {
        throw new HttpsError('failed-precondition', 'Um desconto aplicado esta fora do limite permitido.');
      }

      const now = Timestamp.now();
      const expiresAt = Timestamp.fromMillis(now.toMillis() + validityDays * 24 * 60 * 60 * 1000);
      const quoteData: DocumentData = {
        organizationId,
        companyId,
        orderDraftId,
        branchId,
        customerId,
        sellerId,
        deliveryAddress: normalizeAddress(request.data?.deliveryAddress, 'deliveryAddress'),
        billingAddress: normalizeAddress(request.data?.billingAddress, 'billingAddress'),
        priceListId,
        paymentTermId,
        carrierId: optionalString(request.data?.carrierId) ?? null,
        collectionId: optionalString(request.data?.collectionId) ?? null,
        orderType: optionalString(request.data?.orderType) ?? null,
        notes: optionalString(request.data?.notes) ?? null,
        currency: pricing.currency,
        subtotal: pricing.subtotal,
        discountAmount:
          roundCurrency(pricing.campaignDiscountTotal + pricing.commercialRuleDiscountTotal + pricing.manualDiscountTotal),
        surchargeAmount: roundCurrency(pricing.paymentTermAdjustmentTotal),
        shippingAmount: pricing.shippingAmount,
        total: pricing.total,
        status: 'sent',
        expiresAt,
        items: pricing.items.map((item, index) => ({
          id: request.data?.items?.[index]?.id ?? `${index}`,
          productId: item.productId,
          variantId: item.variantId ?? null,
          quantity: item.quantity,
          unitPrice: item.finalUnitPrice,
          discountAmount: roundCurrency(item.lineSubtotal - item.lineTotal),
          subtotal: item.lineTotal,
        })),
        priceSnapshot: {
          campaignDiscountTotal: pricing.campaignDiscountTotal,
          commercialRuleDiscountTotal: pricing.commercialRuleDiscountTotal,
          manualDiscountTotal: pricing.manualDiscountTotal,
          paymentTermAdjustmentTotal: pricing.paymentTermAdjustmentTotal,
          appliedPaymentTermRuleId: pricing.appliedPaymentTermRuleId ?? null,
          commercialRuleTrace: pricing.commercialRuleTrace,
        },
        createdAt: now,
        createdBy: uid,
        updatedAt: now,
        updatedBy: uid,
        convertedOrderId: null,
        version: 1,
      };
      transaction.set(quoteRef, quoteData);
      transaction.set(orgRef.collection('auditLogs').doc(), {
        organizationId,
        actorUserId: uid,
        actorName,
        action: 'quote.generated',
        entityType: 'quote',
        entityId: quoteId,
        previousValue: null,
        newValue: { customerId, total: pricing.total, expiresAt },
        timestamp: now,
      });
      return serializeQuote(quoteId, quoteData);
    });

    logger.info('generateQuote succeeded', {
      correlationId,
      organizationId,
      companyId,
      quoteId,
      uid,
      itemCount: result.itemCount,
      total: result.total,
      durationMs: Date.now() - startedAt,
    });
    return result;
  },
);

function normalizeValidityDays(value: unknown): number {
  if (value === undefined) return 7;
  if (typeof value !== 'number' || Number.isNaN(value) || value < 1 || value > 90) {
    throw new HttpsError('invalid-argument', 'validityDays must stay between 1 and 90.');
  }
  return Math.floor(value);
}

function requireQuoteItems(value: SubmitOrderItemInput[] | undefined): PricingEngineItemInput[] {
  if (!Array.isArray(value) || value.length === 0) {
    throw new HttpsError('invalid-argument', 'items is required.');
  }
  return value.map((item, index) =>
    normalizeItem({
      productId: item.productId ?? '',
      variantId: item.variantId,
      quantity: item.quantity ?? 0,
      collectionId: item.collectionId,
      categoryId: item.categoryId,
      manualDiscountPercent: item.manualDiscountPercent,
    }, index),
  );
}

function normalizeAddress(value: SubmitOrderAddressInput | undefined, field: string): DocumentData {
  if (typeof value !== 'object' || value === null) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return {
    street: requireNonEmptyString(value.street, `${field}.street`),
    number: optionalString(value.number) ?? null,
    complement: optionalString(value.complement) ?? null,
    district: optionalString(value.district) ?? null,
    city: requireNonEmptyString(value.city, `${field}.city`),
    state: requireNonEmptyString(value.state, `${field}.state`),
    zipCode: requireNonEmptyString(value.zipCode, `${field}.zipCode`),
    country: optionalString(value.country) ?? 'BR',
  };
}

function roundCurrency(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}
