import { Timestamp } from 'firebase-admin/firestore';

import type { OrderAggregationFact } from '../../src/aggregations/aggregation-shared';
import { InMemoryAggregationDataSource } from './in-memory-aggregation-data-source';

// `recomputeMonthlyAggregatesScheduledHandler` builds its own
// Firestore-backed `AggregationDataSource` internally (it has no per-org
// caller to inject one, unlike the callable/per-write functions) — mocked
// here so the "every active organization/company, current + previous
// month" looping/isolation behaviour can still be exercised with the same
// in-memory fake, without needing the Firebase Emulator Suite or real
// Admin SDK credentials just to enumerate zero organizations.
const sharedDataSource = new InMemoryAggregationDataSource();
jest.mock('../../src/aggregations/aggregation-data-source', () => {
  const actual = jest.requireActual('../../src/aggregations/aggregation-data-source');
  return {
    ...actual,
    createFirestoreAggregationDataSource: () => sharedDataSource,
  };
});

import {
  recomputeMonthlyAggregatesForCompany,
  recomputeMonthlyAggregatesScheduledHandler,
} from '../../src/aggregations/recompute-monthly-aggregates';

function fact(overrides: Partial<OrderAggregationFact> = {}): OrderAggregationFact {
  return {
    id: overrides.id ?? 'order-1',
    organizationId: overrides.organizationId ?? 'org-1',
    companyId: overrides.companyId ?? 'company-1',
    customerId: overrides.customerId ?? 'customer-1',
    sellerId: overrides.sellerId ?? 'seller-1',
    region: overrides.region ?? 'SC',
    status: overrides.status ?? 'submitted',
    createdAt:
      overrides.createdAt ?? Timestamp.fromDate(new Date('2026-08-15T10:00:00.000Z')),
    itemsSubtotal: overrides.itemsSubtotal ?? 1000,
    discountAmount: overrides.discountAmount ?? 0,
    surchargeAmount: overrides.surchargeAmount ?? 0,
    shippingAmount: overrides.shippingAmount ?? 0,
    itemQuantity: overrides.itemQuantity ?? 1,
    items: overrides.items ?? [{ productId: 'product-1', quantity: 1, subtotal: 1000 }],
  };
}

describe('recomputeMonthlyAggregatesForCompany', () => {
  it('generates customer/seller/region/product monthly snapshots from every order in the month', async () => {
    const dataSource = new InMemoryAggregationDataSource();
    dataSource.orders = [
      fact({ id: 'order-1', customerId: 'customer-1', sellerId: 'seller-1', region: 'SC' }),
      fact({ id: 'order-2', customerId: 'customer-2', sellerId: 'seller-1', region: 'SP' }),
    ];
    dataSource.customerLabels.set('customer-1', { name: 'Loja A' });

    const result = await recomputeMonthlyAggregatesForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      monthKey: '2026-08',
      dataSource,
    });

    expect(result.generatedSnapshots).toBeGreaterThan(0);
    expect(dataSource.writesByDimension.get('customerMonthly')?.size).toBe(2);
    expect(dataSource.writesByDimension.get('sellerMonthly')?.size).toBe(1);
    expect(dataSource.writesByDimension.get('representativeMonthly')?.size).toBe(1);
    expect(dataSource.writesByDimension.get('regionMonthly')?.size).toBe(2);
    expect(dataSource.writesByDimension.get('productMonthly')?.size).toBe(1);

    const customerSnapshots = dataSource.writesByDimension.get('customerMonthly');
    const customer1Key = [...(customerSnapshots?.keys() ?? [])].find((key) =>
      key.includes('customer-1'),
    );
    expect(customerSnapshots?.get(customer1Key ?? '')?.labels.customerName).toBe('Loja A');
  });

  it('is idempotent: recomputing the same organization/company/month twice never duplicates snapshots', async () => {
    const dataSource = new InMemoryAggregationDataSource();
    dataSource.orders = [fact({ id: 'order-1' })];

    await recomputeMonthlyAggregatesForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      monthKey: '2026-08',
      dataSource,
    });
    await recomputeMonthlyAggregatesForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      monthKey: '2026-08',
      dataSource,
    });

    expect(dataSource.writesByDimension.get('customerMonthly')?.size).toBe(1);
    expect(dataSource.writesByDimension.get('sellerMonthly')?.size).toBe(1);
    expect(dataSource.writesByDimension.get('representativeMonthly')?.size).toBe(1);
    expect(dataSource.writesByDimension.get('regionMonthly')?.size).toBe(1);
    expect(dataSource.writesByDimension.get('productMonthly')?.size).toBe(1);
  });

  it('a month with zero orders in this company produces zero snapshots for every dimension', async () => {
    const dataSource = new InMemoryAggregationDataSource();
    const result = await recomputeMonthlyAggregatesForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      monthKey: '2026-08',
      dataSource,
    });
    expect(result.generatedSnapshots).toBe(0);
    expect(dataSource.writesByDimension.size).toBe(0);
  });

  it('never leaks a different company/organization into the recomputed month (multi-tenant isolation)', async () => {
    const dataSource = new InMemoryAggregationDataSource();
    dataSource.orders = [
      fact({ id: 'order-1', organizationId: 'org-1', companyId: 'company-1' }),
      fact({ id: 'order-2', organizationId: 'org-1', companyId: 'company-2' }),
      fact({ id: 'order-3', organizationId: 'org-2', companyId: 'company-1' }),
    ];

    await recomputeMonthlyAggregatesForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      monthKey: '2026-08',
      dataSource,
    });

    const sellerSnapshots = [
      ...(dataSource.writesByDimension.get('sellerMonthly')?.values() ?? []),
    ];
    expect(sellerSnapshots).toHaveLength(1);
    expect(sellerSnapshots[0].organizationId).toBe('org-1');
    expect(sellerSnapshots[0].companyId).toBe('company-1');
    expect(sellerSnapshots[0].orderCount).toBe(1);
  });
});

describe('recomputeMonthlyAggregatesScheduledHandler', () => {
  beforeEach(() => {
    sharedDataSource.orders = [];
    sharedDataSource.activeOrganizationIds = [];
    sharedDataSource.activeCompanyIdsByOrganization.clear();
    sharedDataSource.writesByDimension.clear();
  });

  it('processes the current and previous month for every active organization/company', async () => {
    sharedDataSource.activeOrganizationIds = ['org-1'];
    sharedDataSource.activeCompanyIdsByOrganization.set('org-1', ['company-1']);
    sharedDataSource.orders = [
      fact({ id: 'order-july', createdAt: Timestamp.fromDate(new Date('2026-07-20T10:00:00.000Z')) }),
      fact({ id: 'order-aug', createdAt: Timestamp.fromDate(new Date('2026-08-05T10:00:00.000Z')) }),
    ];

    await recomputeMonthlyAggregatesScheduledHandler(
      new Date('2026-08-15T03:00:00.000Z'),
    );

    const sellerSnapshots = [
      ...(sharedDataSource.writesByDimension.get('sellerMonthly')?.values() ?? []),
    ];
    expect(sellerSnapshots.map((snapshot) => snapshot.periodKey).sort()).toEqual([
      '2026-07',
      '2026-08',
    ]);
  });

  it('does not throw when there are no active organizations', async () => {
    await expect(
      recomputeMonthlyAggregatesScheduledHandler(new Date('2026-08-15T03:00:00.000Z')),
    ).resolves.toBeUndefined();
    expect(sharedDataSource.writesByDimension.size).toBe(0);
  });

  it('one company failing to recompute does not stop the rest of the tenant base (isolation by job)', async () => {
    sharedDataSource.activeOrganizationIds = ['org-1'];
    sharedDataSource.activeCompanyIdsByOrganization.set('org-1', [
      'company-broken',
      'company-ok',
    ]);
    sharedDataSource.orders = [
      fact({ id: 'order-ok', companyId: 'company-ok' }),
    ];
    const originalLoadOrderFacts = sharedDataSource.loadOrderFacts.bind(sharedDataSource);
    sharedDataSource.loadOrderFacts = async (loadParams) => {
      if (loadParams.companyId === 'company-broken') {
        throw new Error('simulated failure for company-broken');
      }
      return originalLoadOrderFacts(loadParams);
    };

    await expect(
      recomputeMonthlyAggregatesScheduledHandler(new Date('2026-08-15T03:00:00.000Z')),
    ).resolves.toBeUndefined();

    const sellerSnapshots = [
      ...(sharedDataSource.writesByDimension.get('sellerMonthly')?.values() ?? []),
    ];
    expect(sellerSnapshots.some((snapshot) => snapshot.companyId === 'company-ok')).toBe(true);
  });
});
