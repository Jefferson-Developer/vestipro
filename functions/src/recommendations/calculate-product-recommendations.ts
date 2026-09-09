import { Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import {
  DEFAULT_LOOKBACK_DAYS,
  MAX_RECOMMENDATIONS_PER_SCOPE,
  PRODUCT_RECOMMENDATION_MODEL,
  PRODUCT_RECOMMENDATION_MODEL_VERSION,
  buildBaskets,
  buildCustomerScopeRecommendation,
  buildProductScopeRecommendation,
  buildSegmentScopeRecommendation,
  computeBestSellers,
  computeCoOccurrence,
  productRecommendationDocumentId,
  type ProductRecommendationResult,
} from './recommendation-shared';
import {
  createFirestoreProductRecommendationDataSource,
  type ProductRecommendationPersistence,
} from './recommendation-data-source';

export interface ProductRecommendationCalculationOutcome {
  segmentGenerated: boolean;
  productScopeCount: number;
  customerScopeCount: number;
}

/**
 * Calculates (and idempotently persists) every `product`/`customer`/
 * `segment` recommendation document for one company (TASK-190, EPIC-28),
 * from `DEFAULT_LOOKBACK_DAYS` days of already-persisted `Order` documents —
 * see `recommendation-shared.ts`'s module doc comment for the full signal/
 * cadência documentation this task requires.
 *
 * Reads the company's order history exactly once (`loadOrderFacts`) and
 * derives every scope from that single pass: the co-occurrence model itself,
 * the company-wide best-sellers, the per-product "frequently bought
 * together" documents, and the per-customer personalized/fallback
 * recommendation — never a second, duplicated order query per scope.
 *
 * Always a full overwrite keyed by `{companyId}_{scopeType}_{scopeId}` (no
 * time dimension — this is always "the latest recommendation", unlike
 * `DemandForecast`'s anchor-month-keyed id): idempotent re-execution for the
 * same company never duplicates a document, it simply replaces the previous
 * one with a fresher calculation.
 */
export async function calculateProductRecommendationsForCompany(params: {
  organizationId: string;
  companyId: string;
  now: Date;
  persistence: ProductRecommendationPersistence;
  lookbackDays?: number;
  maxItemsPerScope?: number;
  generatedAt?: Timestamp;
}): Promise<ProductRecommendationCalculationOutcome> {
  const lookbackDays = params.lookbackDays ?? DEFAULT_LOOKBACK_DAYS;
  const maxItems = params.maxItemsPerScope ?? MAX_RECOMMENDATIONS_PER_SCOPE;
  const generatedAt = params.generatedAt ?? Timestamp.now();
  const end = params.now;
  const start = new Date(end.getTime() - lookbackDays * 24 * 60 * 60 * 1000);

  const facts = await params.persistence.loadOrderFacts({
    organizationId: params.organizationId,
    companyId: params.companyId,
    start,
    end,
  });
  const baskets = buildBaskets(facts);
  const model = computeCoOccurrence(baskets);

  const productIds = [...new Set(baskets.flatMap((basket) => basket.productIds))];
  const productLabels = await params.persistence.loadProductLabels(
    params.organizationId,
    productIds,
  );

  const bestSellers = computeBestSellers({
    model,
    productLabels,
    lookbackDays,
    limit: maxItems,
  });

  // -- segment scope (company-wide best-sellers) --------------------------
  const segmentResult = buildSegmentScopeRecommendation({
    model,
    productLabels,
    lookbackDays,
  });
  await params.persistence.saveRecommendation(
    params.organizationId,
    productRecommendationDocumentId(params.companyId, 'segment', segmentResult.scopeId),
    toRecommendationDoc({
      organizationId: params.organizationId,
      companyId: params.companyId,
      result: segmentResult,
      lookbackDays,
      generatedAt,
    }),
  );

  // -- product scope (frequently bought together) --------------------------
  // Deliberately skips a product with `insufficientData` — attributing
  // "clientes que compraram X" to a product never actually co-purchased with
  // anything would be a fabricated justification (see
  // `recommendation-shared.ts`'s own doc comment on
  // `buildProductScopeRecommendation`).
  let productScopeCount = 0;
  for (const productId of productIds) {
    const result = buildProductScopeRecommendation({
      anchorProductId: productId,
      model,
      productLabels,
      maxItems,
    });
    if (result.insufficientData) continue;
    await params.persistence.saveRecommendation(
      params.organizationId,
      productRecommendationDocumentId(params.companyId, 'product', productId),
      toRecommendationDoc({
        organizationId: params.organizationId,
        companyId: params.companyId,
        result,
        lookbackDays,
        generatedAt,
      }),
    );
    productScopeCount += 1;
  }

  // -- customer scope (personalized, always written — see fallback rule) --
  const purchasedProductsByCustomer = new Map<string, Set<string>>();
  for (const basket of baskets) {
    const purchased = purchasedProductsByCustomer.get(basket.customerId) ?? new Set<string>();
    basket.productIds.forEach((productId) => purchased.add(productId));
    purchasedProductsByCustomer.set(basket.customerId, purchased);
  }

  const customers = await params.persistence.listActiveCustomers(
    params.organizationId,
    params.companyId,
  );
  let customerScopeCount = 0;
  for (const customer of customers) {
    const purchasedProductIds =
      purchasedProductsByCustomer.get(customer.customerId) ?? new Set<string>();
    const result = buildCustomerScopeRecommendation({
      customerId: customer.customerId,
      purchasedProductIds,
      model,
      productLabels,
      bestSellers,
      maxItems,
    });
    await params.persistence.saveRecommendation(
      params.organizationId,
      productRecommendationDocumentId(params.companyId, 'customer', customer.customerId),
      toRecommendationDoc({
        organizationId: params.organizationId,
        companyId: params.companyId,
        result,
        lookbackDays,
        generatedAt,
        primarySalesRepId: customer.primarySalesRepId,
        teamId: customer.teamId,
      }),
    );
    customerScopeCount += 1;
  }

  return {
    segmentGenerated: true,
    productScopeCount,
    customerScopeCount,
  };
}

function toRecommendationDoc(params: {
  organizationId: string;
  companyId: string;
  result: ProductRecommendationResult;
  lookbackDays: number;
  generatedAt: Timestamp;
  primarySalesRepId?: string;
  teamId?: string;
}): DocumentData {
  const base: DocumentData = {
    organizationId: params.organizationId,
    companyId: params.companyId,
    scopeType: params.result.scopeType,
    scopeId: params.result.scopeId,
    items: params.result.items.map((item) => ({ ...item })),
    fallbackApplied: params.result.fallbackApplied,
    insufficientData: params.result.insufficientData,
    signalsUsed: params.result.signalsUsed,
    lookbackDays: params.lookbackDays,
    model: PRODUCT_RECOMMENDATION_MODEL,
    modelVersion: PRODUCT_RECOMMENDATION_MODEL_VERSION,
    generatedAt: params.generatedAt,
    version: 1,
  };
  if (params.primarySalesRepId != null) {
    base.primarySalesRepId = params.primarySalesRepId;
  }
  if (params.teamId != null) {
    base.teamId = params.teamId;
  }
  return base;
}

/**
 * Loops every active organization/company, isolating failures per company —
 * same "one tenant's failure never aborts the batch" contract as
 * `../demand-forecast/calculate-demand-forecasts.ts`/
 * `../replenishment/calculate-replenishment-suggestions.ts`.
 */
export async function calculateProductRecommendationsScheduledHandler(
  now: Date = new Date(),
  persistence?: ProductRecommendationPersistence,
): Promise<void> {
  const adapter = persistence ?? createFirestoreProductRecommendationDataSource();
  const organizationIds = await adapter.listActiveOrganizationIds();

  for (const organizationId of organizationIds) {
    const companyIds = await adapter.listActiveCompanyIds(organizationId);
    for (const companyId of companyIds) {
      try {
        const outcome = await calculateProductRecommendationsForCompany({
          organizationId,
          companyId,
          now,
          persistence: adapter,
        });
        logger.info('calculateProductRecommendations processed company', {
          organizationId,
          companyId,
          productScopeCount: outcome.productScopeCount,
          customerScopeCount: outcome.customerScopeCount,
        });
      } catch (error) {
        logger.error('calculateProductRecommendations failed for company', {
          organizationId,
          companyId,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    }
  }
}

/**
 * Weekly product-recommendation calculation (TASK-190, EPIC-28) — same
 * weekly cadence as `calculateReplenishmentSuggestions` (a recommendation
 * does not need to be recomputed every day), staggered 30 minutes after it
 * to avoid both jobs contending for the same Firestore/Functions capacity at
 * the exact same minute.
 */
export const calculateProductRecommendations = onSchedule(
  {
    schedule: 'every monday 04:30',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',
  },
  async () => {
    await calculateProductRecommendationsScheduledHandler();
  },
);
