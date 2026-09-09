import type { OrderAggregationFact } from '../../src/aggregations/aggregation-shared';
import type { ProductLabel } from '../../src/aggregations/aggregation-builders';
import { Timestamp } from 'firebase-admin/firestore';
import {
  buildBaskets,
  buildCustomerScopeRecommendation,
  buildProductScopeRecommendation,
  buildSegmentScopeRecommendation,
  computeBestSellers,
  computeCoOccurrence,
  productRecommendationDocumentId,
  SEGMENT_BEST_SELLERS_SCOPE_ID,
} from '../../src/recommendations/recommendation-shared';

function fact(params: {
  id: string;
  customerId: string;
  productIds: string[];
  status?: string;
}): OrderAggregationFact {
  return {
    id: params.id,
    organizationId: 'org-1',
    companyId: 'company-1',
    customerId: params.customerId,
    sellerId: 'seller-1',
    region: 'SP',
    city: 'São Paulo',
    status: params.status ?? 'submitted',
    createdAt: Timestamp.now(),
    currency: 'BRL',
    itemsSubtotal: 100,
    discountAmount: 0,
    surchargeAmount: 0,
    shippingAmount: 0,
    itemQuantity: params.productIds.length,
    items: params.productIds.map((productId) => ({
      productId,
      quantity: 1,
      subtotal: 50,
    })),
  };
}

const PRODUCT_LABELS = new Map<string, ProductLabel>([
  ['product-1', { name: 'Camiseta Básica' }],
  ['product-2', { name: 'Calça Jeans' }],
  ['product-3', { name: 'Boné' }],
  ['product-4', { name: 'Jaqueta' }],
]);

describe('buildBaskets', () => {
  it('only counts revenue-recognized orders and dedups items within an order', () => {
    const facts = [
      fact({ id: 'order-1', customerId: 'customer-a', productIds: ['product-1', 'product-1', 'product-2'] }),
      fact({ id: 'order-2', customerId: 'customer-a', productIds: ['product-3'], status: 'draft' }),
      fact({ id: 'order-3', customerId: 'customer-a', productIds: ['product-4'], status: 'rejected' }),
    ];

    const baskets = buildBaskets(facts);

    expect(baskets).toHaveLength(1);
    expect(baskets[0].orderId).toBe('order-1');
    expect(baskets[0].productIds.sort()).toEqual(['product-1', 'product-2']);
  });

  it('discards a basket that ends up with zero distinct products', () => {
    const facts = [fact({ id: 'order-1', customerId: 'customer-a', productIds: [] })];
    expect(buildBaskets(facts)).toHaveLength(0);
  });
});

describe('computeCoOccurrence', () => {
  it('computes symmetric pair counts and per-product purchase counts', () => {
    const baskets = buildBaskets([
      fact({ id: 'order-1', customerId: 'customer-a', productIds: ['product-1', 'product-2'] }),
      fact({ id: 'order-2', customerId: 'customer-b', productIds: ['product-1', 'product-2'] }),
      fact({ id: 'order-3', customerId: 'customer-c', productIds: ['product-1', 'product-3'] }),
    ]);

    const model = computeCoOccurrence(baskets);

    expect(model.purchaseCounts.get('product-1')).toBe(3);
    expect(model.purchaseCounts.get('product-2')).toBe(2);
    expect(model.purchaseCounts.get('product-3')).toBe(1);
    expect(model.pairCounts.get('product-1')?.get('product-2')).toBe(2);
    expect(model.pairCounts.get('product-2')?.get('product-1')).toBe(2);
    expect(model.pairCounts.get('product-1')?.get('product-3')).toBe(1);
  });
});

describe('computeBestSellers', () => {
  it('ranks by purchase count descending, tie-broken by productId', () => {
    const baskets = buildBaskets([
      fact({ id: 'order-1', customerId: 'customer-a', productIds: ['product-2'] }),
      fact({ id: 'order-2', customerId: 'customer-b', productIds: ['product-2'] }),
      fact({ id: 'order-3', customerId: 'customer-c', productIds: ['product-1'] }),
      fact({ id: 'order-4', customerId: 'customer-d', productIds: ['product-3'] }),
    ]);
    const model = computeCoOccurrence(baskets);

    const items = computeBestSellers({
      model,
      productLabels: PRODUCT_LABELS,
      lookbackDays: 180,
    });

    expect(items.map((item) => item.productId)).toEqual(['product-2', 'product-1', 'product-3']);
    expect(items.every((item) => item.reasonCode === 'bestSeller')).toBe(true);
  });

  it('excludes the given product ids and respects the limit', () => {
    const baskets = buildBaskets([
      fact({ id: 'order-1', customerId: 'customer-a', productIds: ['product-1'] }),
      fact({ id: 'order-2', customerId: 'customer-b', productIds: ['product-2'] }),
      fact({ id: 'order-3', customerId: 'customer-c', productIds: ['product-3'] }),
    ]);
    const model = computeCoOccurrence(baskets);

    const items = computeBestSellers({
      model,
      productLabels: PRODUCT_LABELS,
      lookbackDays: 180,
      excludeProductIds: new Set(['product-1']),
      limit: 1,
    });

    expect(items).toHaveLength(1);
    expect(items[0].productId).not.toBe('product-1');
  });
});

describe('buildProductScopeRecommendation', () => {
  it('recommends products frequently bought together, ranked by confidence', () => {
    const baskets = buildBaskets([
      fact({ id: 'order-1', customerId: 'customer-a', productIds: ['product-1', 'product-2'] }),
      fact({ id: 'order-2', customerId: 'customer-b', productIds: ['product-1', 'product-2'] }),
      fact({ id: 'order-3', customerId: 'customer-c', productIds: ['product-1', 'product-3'] }),
      fact({ id: 'order-4', customerId: 'customer-d', productIds: ['product-1', 'product-3'] }),
      fact({ id: 'order-5', customerId: 'customer-e', productIds: ['product-1'] }),
    ]);
    const model = computeCoOccurrence(baskets);

    const result = buildProductScopeRecommendation({
      anchorProductId: 'product-1',
      model,
      productLabels: PRODUCT_LABELS,
    });

    expect(result.scopeType).toBe('product');
    expect(result.insufficientData).toBe(false);
    expect(result.fallbackApplied).toBe(false);
    // `product-1` was purchased 5 times; both `product-2` and `product-3`
    // co-occurred twice (confidence 2/5 each) — tie broken by productId asc.
    expect(result.items.map((item) => item.productId)).toEqual(['product-2', 'product-3']);
    expect(result.items[0].reasonCode).toBe('boughtTogether');
    expect(result.items[0].reasonLabel).toContain('Camiseta Básica');
    expect(result.items[0].score).toBeCloseTo(2 / 5);
  });

  it('excludes pairs below the minimum co-occurrence count', () => {
    const baskets = buildBaskets([
      fact({ id: 'order-1', customerId: 'customer-a', productIds: ['product-1', 'product-2'] }),
      fact({ id: 'order-2', customerId: 'customer-b', productIds: ['product-1'] }),
    ]);
    const model = computeCoOccurrence(baskets);

    const result = buildProductScopeRecommendation({
      anchorProductId: 'product-1',
      model,
      productLabels: PRODUCT_LABELS,
      minCoOccurrenceCount: 2,
    });

    expect(result.items).toEqual([]);
    expect(result.insufficientData).toBe(true);
  });

  it('marks insufficientData (never a fabricated list) for a product never sold', () => {
    const model = computeCoOccurrence([]);

    const result = buildProductScopeRecommendation({
      anchorProductId: 'product-never-sold',
      model,
      productLabels: PRODUCT_LABELS,
    });

    expect(result.insufficientData).toBe(true);
    expect(result.items).toEqual([]);
    expect(result.signalsUsed).toEqual([]);
  });
});

describe('buildCustomerScopeRecommendation', () => {
  it('recommends products co-purchased with what the customer already bought, excluding already-purchased items', () => {
    const baskets = buildBaskets([
      fact({ id: 'order-1', customerId: 'customer-a', productIds: ['product-1'] }),
      fact({ id: 'order-2', customerId: 'customer-b', productIds: ['product-1', 'product-2'] }),
      fact({ id: 'order-3', customerId: 'customer-c', productIds: ['product-1', 'product-2'] }),
    ]);
    const model = computeCoOccurrence(baskets);
    const bestSellers = computeBestSellers({ model, productLabels: PRODUCT_LABELS, lookbackDays: 180 });

    const result = buildCustomerScopeRecommendation({
      customerId: 'customer-a',
      purchasedProductIds: new Set(['product-1']),
      model,
      productLabels: PRODUCT_LABELS,
      bestSellers,
    });

    expect(result.scopeType).toBe('customer');
    expect(result.fallbackApplied).toBe(false);
    expect(result.insufficientData).toBe(false);
    expect(result.items.map((item) => item.productId)).toEqual(['product-2']);
    expect(result.items[0].reasonCode).toBe('purchaseHistorySimilarity');
  });

  it('falls back to best-sellers for a brand-new customer with no purchase history', () => {
    const baskets = buildBaskets([
      fact({ id: 'order-1', customerId: 'customer-existing', productIds: ['product-1'] }),
      fact({ id: 'order-2', customerId: 'customer-existing-2', productIds: ['product-1'] }),
    ]);
    const model = computeCoOccurrence(baskets);
    const bestSellers = computeBestSellers({ model, productLabels: PRODUCT_LABELS, lookbackDays: 180 });

    const result = buildCustomerScopeRecommendation({
      customerId: 'customer-new',
      purchasedProductIds: new Set(),
      model,
      productLabels: PRODUCT_LABELS,
      bestSellers,
    });

    expect(result.fallbackApplied).toBe(true);
    expect(result.insufficientData).toBe(false);
    expect(result.items.map((item) => item.productId)).toEqual(['product-1']);
    expect(result.items[0].reasonCode).toBe('bestSeller');
    expect(result.signalsUsed).toEqual(['best_sellers_fallback']);
  });

  it('marks insufficientData (never a fabricated list) when even best-sellers has nothing to offer', () => {
    const model = computeCoOccurrence([]);

    const result = buildCustomerScopeRecommendation({
      customerId: 'customer-new',
      purchasedProductIds: new Set(),
      model,
      productLabels: PRODUCT_LABELS,
      bestSellers: [],
    });

    expect(result.fallbackApplied).toBe(false);
    expect(result.insufficientData).toBe(true);
    expect(result.items).toEqual([]);
  });

  it('never recommends a product the customer already purchased, even via the fallback', () => {
    const baskets = buildBaskets([
      fact({ id: 'order-1', customerId: 'customer-a', productIds: ['product-1'] }),
      fact({ id: 'order-2', customerId: 'customer-b', productIds: ['product-1'] }),
    ]);
    const model = computeCoOccurrence(baskets);
    const bestSellers = computeBestSellers({ model, productLabels: PRODUCT_LABELS, lookbackDays: 180 });

    const result = buildCustomerScopeRecommendation({
      customerId: 'customer-a',
      purchasedProductIds: new Set(['product-1']),
      model,
      productLabels: PRODUCT_LABELS,
      bestSellers,
    });

    expect(result.items.some((item) => item.productId === 'product-1')).toBe(false);
    expect(result.insufficientData).toBe(true);
  });
});

describe('buildSegmentScopeRecommendation', () => {
  it('returns the company-wide best-sellers as a standalone segment scope', () => {
    const baskets = buildBaskets([
      fact({ id: 'order-1', customerId: 'customer-a', productIds: ['product-1'] }),
    ]);
    const model = computeCoOccurrence(baskets);

    const result = buildSegmentScopeRecommendation({
      model,
      productLabels: PRODUCT_LABELS,
      lookbackDays: 180,
    });

    expect(result.scopeType).toBe('segment');
    expect(result.scopeId).toBe(SEGMENT_BEST_SELLERS_SCOPE_ID);
    expect(result.items).toHaveLength(1);
  });
});

describe('productRecommendationDocumentId', () => {
  it('builds a deterministic id from company/scope', () => {
    expect(productRecommendationDocumentId('company-1', 'product', 'product-1')).toBe(
      'company-1_product_product-1',
    );
  });
});
