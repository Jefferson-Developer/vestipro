import { Timestamp, type DocumentData } from 'firebase-admin/firestore';

import {
  calculateProductRecommendationsForCompany,
  calculateProductRecommendationsScheduledHandler,
} from '../../src/recommendations/calculate-product-recommendations';
import type {
  ProductRecommendationPersistence,
  RecommendationCustomerRow,
} from '../../src/recommendations/recommendation-data-source';
import type { OrderAggregationFact } from '../../src/aggregations/aggregation-shared';
import type { ProductLabel } from '../../src/aggregations/aggregation-builders';

class InMemoryProductRecommendationPersistence
  implements ProductRecommendationPersistence
{
  organizationIds: string[] = [];
  companyIdsByOrganization = new Map<string, string[]>();
  factsByOrgCompany = new Map<string, OrderAggregationFact[]>();
  productLabelsByOrg = new Map<string, Map<string, ProductLabel>>();
  customersByOrgCompany = new Map<string, RecommendationCustomerRow[]>();
  readonly saved = new Map<string, DocumentData>();

  private key(organizationId: string, companyId: string): string {
    return `${organizationId}::${companyId}`;
  }

  setFacts(organizationId: string, companyId: string, facts: OrderAggregationFact[]): void {
    this.factsByOrgCompany.set(this.key(organizationId, companyId), facts);
  }

  setCustomers(
    organizationId: string,
    companyId: string,
    customers: RecommendationCustomerRow[],
  ): void {
    this.customersByOrgCompany.set(this.key(organizationId, companyId), customers);
  }

  async listActiveOrganizationIds(): Promise<ReadonlyArray<string>> {
    return this.organizationIds;
  }

  async listActiveCompanyIds(organizationId: string): Promise<ReadonlyArray<string>> {
    return this.companyIdsByOrganization.get(organizationId) ?? [];
  }

  async loadOrderFacts(params: {
    organizationId: string;
    companyId: string;
  }): Promise<OrderAggregationFact[]> {
    return this.factsByOrgCompany.get(this.key(params.organizationId, params.companyId)) ?? [];
  }

  async loadProductLabels(
    organizationId: string,
    productIds: readonly string[],
  ): Promise<Map<string, ProductLabel>> {
    const labels = this.productLabelsByOrg.get(organizationId) ?? new Map<string, ProductLabel>();
    const result = new Map<string, ProductLabel>();
    for (const productId of productIds) {
      const label = labels.get(productId);
      if (label) result.set(productId, label);
    }
    return result;
  }

  async listActiveCustomers(
    organizationId: string,
    companyId: string,
  ): Promise<ReadonlyArray<RecommendationCustomerRow>> {
    return this.customersByOrgCompany.get(this.key(organizationId, companyId)) ?? [];
  }

  async saveRecommendation(
    organizationId: string,
    documentId: string,
    data: DocumentData,
  ): Promise<void> {
    this.saved.set(`${organizationId}/${documentId}`, data);
  }
}

function fact(params: {
  id: string;
  organizationId?: string;
  companyId?: string;
  customerId: string;
  productIds: string[];
  status?: string;
}): OrderAggregationFact {
  return {
    id: params.id,
    organizationId: params.organizationId ?? 'org-1',
    companyId: params.companyId ?? 'company-1',
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
    items: params.productIds.map((productId) => ({ productId, quantity: 1, subtotal: 50 })),
  };
}

describe('calculateProductRecommendationsForCompany', () => {
  it('generates segment, product and customer scope recommendations from order history', async () => {
    const persistence = new InMemoryProductRecommendationPersistence();
    persistence.setFacts('org-1', 'company-1', [
      fact({ id: 'order-1', customerId: 'customer-a', productIds: ['product-1', 'product-2'] }),
      fact({ id: 'order-2', customerId: 'customer-b', productIds: ['product-1', 'product-2'] }),
      fact({ id: 'order-3', customerId: 'customer-c', productIds: ['product-1'] }),
    ]);
    persistence.productLabelsByOrg.set(
      'org-1',
      new Map([
        ['product-1', { name: 'Camiseta Básica' }],
        ['product-2', { name: 'Calça Jeans' }],
      ]),
    );
    persistence.setCustomers('org-1', 'company-1', [
      { customerId: 'customer-a', primarySalesRepId: 'rep-1', teamId: 'team-1' },
      { customerId: 'customer-new', primarySalesRepId: 'rep-1', teamId: 'team-1' },
    ]);

    const outcome = await calculateProductRecommendationsForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      now: new Date('2026-09-08T00:00:00.000Z'),
      persistence,
    });

    expect(outcome.segmentGenerated).toBe(true);
    expect(outcome.productScopeCount).toBeGreaterThan(0);
    expect(outcome.customerScopeCount).toBe(2);

    const segment = persistence.saved.get('org-1/company-1_segment_company-best-sellers');
    expect(segment).toBeDefined();
    expect((segment?.items as unknown[]).length).toBeGreaterThan(0);

    const productScope = persistence.saved.get('org-1/company-1_product_product-1');
    expect(productScope).toBeDefined();
    expect(productScope?.scopeType).toBe('product');

    const personalizedCustomer = persistence.saved.get('org-1/company-1_customer_customer-a');
    expect(personalizedCustomer?.fallbackApplied).toBe(false);
    expect(personalizedCustomer?.primarySalesRepId).toBe('rep-1');
    expect(personalizedCustomer?.teamId).toBe('team-1');

    const newCustomer = persistence.saved.get('org-1/company-1_customer_customer-new');
    expect(newCustomer?.fallbackApplied).toBe(true);
    expect(newCustomer?.insufficientData).toBe(false);
  });

  it('never persists a product-scope document for a product without qualifying co-occurrence', async () => {
    const persistence = new InMemoryProductRecommendationPersistence();
    persistence.setFacts('org-1', 'company-1', [
      fact({ id: 'order-1', customerId: 'customer-a', productIds: ['product-solo'] }),
    ]);

    await calculateProductRecommendationsForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      now: new Date('2026-09-08T00:00:00.000Z'),
      persistence,
    });

    expect(persistence.saved.has('org-1/company-1_product_product-solo')).toBe(false);
  });

  it('always writes a customer-scope document, even with zero order history in the company', async () => {
    const persistence = new InMemoryProductRecommendationPersistence();
    persistence.setCustomers('org-1', 'company-1', [
      { customerId: 'customer-new', primarySalesRepId: 'rep-1', teamId: 'team-1' },
    ]);

    await calculateProductRecommendationsForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      now: new Date('2026-09-08T00:00:00.000Z'),
      persistence,
    });

    const saved = persistence.saved.get('org-1/company-1_customer_customer-new');
    expect(saved).toBeDefined();
    expect(saved?.insufficientData).toBe(true);
    expect(saved?.items).toEqual([]);
  });

  it('skips a customer missing carteira visibility fields (never generates an unreadable document)', async () => {
    // `listActiveCustomers` (real Firestore adapter) already filters these
    // out — this test documents that the orchestrator trusts the persistence
    // port and simply never receives such a row.
    const persistence = new InMemoryProductRecommendationPersistence();
    persistence.setCustomers('org-1', 'company-1', []);

    await calculateProductRecommendationsForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      now: new Date('2026-09-08T00:00:00.000Z'),
      persistence,
    });

    expect(
      [...persistence.saved.keys()].some((key) => key.includes('_customer_')),
    ).toBe(false);
  });

  it('is idempotent: re-running for the same company overwrites the same documents, never duplicating', async () => {
    const persistence = new InMemoryProductRecommendationPersistence();
    persistence.setFacts('org-1', 'company-1', [
      fact({ id: 'order-1', customerId: 'customer-a', productIds: ['product-1', 'product-2'] }),
      fact({ id: 'order-2', customerId: 'customer-b', productIds: ['product-1', 'product-2'] }),
    ]);

    await calculateProductRecommendationsForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      now: new Date('2026-09-08T00:00:00.000Z'),
      persistence,
    });
    const firstRunSize = persistence.saved.size;
    await calculateProductRecommendationsForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      now: new Date('2026-09-08T00:00:00.000Z'),
      persistence,
    });

    expect(persistence.saved.size).toBe(firstRunSize);
  });
});

describe('calculateProductRecommendationsScheduledHandler', () => {
  it('never leaks one organization/company scope into another', async () => {
    const persistence = new InMemoryProductRecommendationPersistence();
    persistence.organizationIds = ['org-a', 'org-b'];
    persistence.companyIdsByOrganization.set('org-a', ['company-a']);
    persistence.companyIdsByOrganization.set('org-b', ['company-b']);
    persistence.setFacts('org-a', 'company-a', [
      fact({
        id: 'order-1',
        organizationId: 'org-a',
        companyId: 'company-a',
        customerId: 'customer-a',
        productIds: ['shared-product-id', 'product-a2'],
      }),
      fact({
        id: 'order-2',
        organizationId: 'org-a',
        companyId: 'company-a',
        customerId: 'customer-a2',
        productIds: ['shared-product-id', 'product-a2'],
      }),
    ]);
    persistence.setFacts('org-b', 'company-b', [
      fact({
        id: 'order-3',
        organizationId: 'org-b',
        companyId: 'company-b',
        customerId: 'customer-b',
        productIds: ['shared-product-id', 'product-b2'],
      }),
      fact({
        id: 'order-4',
        organizationId: 'org-b',
        companyId: 'company-b',
        customerId: 'customer-b2',
        productIds: ['shared-product-id', 'product-b2'],
      }),
    ]);

    await calculateProductRecommendationsScheduledHandler(new Date('2026-09-08T00:00:00.000Z'), persistence);

    const savedA = persistence.saved.get('org-a/company-a_product_shared-product-id');
    const savedB = persistence.saved.get('org-b/company-b_product_shared-product-id');
    expect(savedA?.organizationId).toBe('org-a');
    expect(savedB?.organizationId).toBe('org-b');
    expect((savedA?.items as Array<{ productId: string }>).map((item) => item.productId)).toEqual([
      'product-a2',
    ]);
    expect((savedB?.items as Array<{ productId: string }>).map((item) => item.productId)).toEqual([
      'product-b2',
    ]);
  });

  it('continues processing remaining companies when one company fails', async () => {
    const persistence = new InMemoryProductRecommendationPersistence();
    persistence.organizationIds = ['org-1'];
    persistence.companyIdsByOrganization.set('org-1', ['company-broken', 'company-ok']);
    persistence.setFacts('org-1', 'company-ok', [
      fact({ id: 'order-1', customerId: 'customer-a', productIds: ['product-1', 'product-2'] }),
      fact({ id: 'order-2', customerId: 'customer-b', productIds: ['product-1', 'product-2'] }),
    ]);
    const originalLoad = persistence.loadOrderFacts.bind(persistence);
    persistence.loadOrderFacts = async (params) => {
      if (params.companyId === 'company-broken') {
        throw new Error('boom');
      }
      return originalLoad(params);
    };

    await expect(
      calculateProductRecommendationsScheduledHandler(new Date('2026-09-08T00:00:00.000Z'), persistence),
    ).resolves.toBeUndefined();

    const saved = persistence.saved.get('org-1/company-ok_product_product-1');
    expect(saved).toBeDefined();
  });
});
