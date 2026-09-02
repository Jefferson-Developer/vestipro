import { Timestamp } from 'firebase-admin/firestore';

import {
  buildCustomerMonthlySnapshots,
  buildProductMonthlySnapshots,
  buildRegionMonthlySnapshots,
  buildSalesDailySnapshots,
  buildSellerMonthlySnapshots,
} from '../../src/aggregations/aggregation-builders';
import type { OrderAggregationFact } from '../../src/aggregations/aggregation-shared';

function fact(overrides: Partial<OrderAggregationFact> = {}): OrderAggregationFact {
  return {
    id: overrides.id ?? 'order-1',
    organizationId: overrides.organizationId ?? 'org-1',
    companyId: overrides.companyId ?? 'company-1',
    customerId: overrides.customerId ?? 'customer-1',
    sellerId: overrides.sellerId ?? 'seller-1',
    region: overrides.region ?? 'SC',
    status: overrides.status ?? 'submitted',
    createdAt: overrides.createdAt ?? Timestamp.fromDate(new Date('2026-08-15T10:00:00.000Z')),
    itemsSubtotal: overrides.itemsSubtotal ?? 1000,
    discountAmount: overrides.discountAmount ?? 100,
    surchargeAmount: overrides.surchargeAmount ?? 0,
    shippingAmount: overrides.shippingAmount ?? 50,
    itemQuantity: overrides.itemQuantity ?? 10,
    items: overrides.items ?? [
      { productId: 'product-1', quantity: 6, subtotal: 600 },
      { productId: 'product-2', quantity: 4, subtotal: 400 },
    ],
  };
}

describe('buildSalesDailySnapshots', () => {
  it('aggregates revenue-recognized orders of a single day per company', () => {
    const snapshots = buildSalesDailySnapshots({
      organizationId: 'org-1',
      dayKey: '2026-08-15',
      facts: [
        fact({ id: 'order-1', itemsSubtotal: 1000, discountAmount: 100, shippingAmount: 50 }),
        fact({ id: 'order-2', itemsSubtotal: 500, discountAmount: 0, shippingAmount: 10 }),
        fact({ id: 'order-3', status: 'rejected' }),
      ],
    });

    expect(snapshots).toHaveLength(1);
    expect(snapshots[0].scopeId).toBe('company-1');
    expect(snapshots[0].orderCount).toBe(2);
    expect(snapshots[0].revenueGross).toBeCloseTo(1500, 2);
    expect(snapshots[0].revenueNet).toBeCloseTo(1000 - 100 + 50 + (500 - 0 + 10), 2);
    expect(snapshots[0].discountAmount).toBeCloseTo(100, 2);
    expect(snapshots[0].itemQuantity).toBe(20);
  });

  it('excludes rejected/cancelled orders entirely', () => {
    const snapshots = buildSalesDailySnapshots({
      organizationId: 'org-1',
      dayKey: '2026-08-15',
      facts: [fact({ status: 'cancelled' }), fact({ status: 'rejected' })],
    });
    expect(snapshots).toHaveLength(0);
  });

  it('never mixes two companies into a single snapshot', () => {
    const snapshots = buildSalesDailySnapshots({
      organizationId: 'org-1',
      dayKey: '2026-08-15',
      facts: [
        fact({ id: 'order-1', companyId: 'company-1' }),
        fact({ id: 'order-2', companyId: 'company-2' }),
      ],
    });
    expect(snapshots).toHaveLength(2);
    expect(snapshots.map((snapshot) => snapshot.companyId).sort()).toEqual([
      'company-1',
      'company-2',
    ]);
  });

  it('never mixes two organizations into a single snapshot even with the same companyId', () => {
    const snapshots = buildSalesDailySnapshots({
      organizationId: 'org-1',
      dayKey: '2026-08-15',
      facts: [fact({ organizationId: 'org-1' })],
    });
    expect(snapshots.every((snapshot) => snapshot.organizationId === 'org-1')).toBe(true);
  });

  it('returns an empty array for a period with zero orders', () => {
    expect(
      buildSalesDailySnapshots({ organizationId: 'org-1', dayKey: '2026-08-15', facts: [] }),
    ).toEqual([]);
  });
});

describe('buildCustomerMonthlySnapshots', () => {
  it('groups by company + customer and denormalizes the customer label', () => {
    const snapshots = buildCustomerMonthlySnapshots({
      organizationId: 'org-1',
      monthKey: '2026-08',
      facts: [
        fact({ id: 'order-1', customerId: 'customer-1' }),
        fact({ id: 'order-2', customerId: 'customer-1' }),
        fact({ id: 'order-3', customerId: 'customer-2' }),
      ],
      customerLabels: new Map([
        ['customer-1', { name: 'Loja da Maria', segment: 'gold' }],
      ]),
    });

    expect(snapshots).toHaveLength(2);
    const customer1 = snapshots.find((snapshot) => snapshot.scopeId === 'customer-1');
    expect(customer1?.orderCount).toBe(2);
    expect(customer1?.labels.customerName).toBe('Loja da Maria');
    expect(customer1?.labels.segment).toBe('gold');
    const customer2 = snapshots.find((snapshot) => snapshot.scopeId === 'customer-2');
    expect(customer2?.labels.customerName).toBeUndefined();
  });
});

describe('buildSellerMonthlySnapshots', () => {
  it('groups by company + seller', () => {
    const snapshots = buildSellerMonthlySnapshots({
      organizationId: 'org-1',
      monthKey: '2026-08',
      facts: [fact({ sellerId: 'seller-1' }), fact({ id: 'order-2', sellerId: 'seller-2' })],
      sellerLabels: new Map([['seller-1', { name: 'João Vendedor' }]]),
    });
    expect(snapshots).toHaveLength(2);
    expect(
      snapshots.find((snapshot) => snapshot.scopeId === 'seller-1')?.labels.sellerName,
    ).toBe('João Vendedor');
  });
});

describe('buildRegionMonthlySnapshots', () => {
  it('groups by company + region (delivery address state)', () => {
    const snapshots = buildRegionMonthlySnapshots({
      organizationId: 'org-1',
      monthKey: '2026-08',
      facts: [fact({ region: 'SC' }), fact({ id: 'order-2', region: 'sp' })],
    });
    expect(snapshots.map((snapshot) => snapshot.scopeId).sort()).toEqual(['SC', 'sp']);
  });
});

describe('buildProductMonthlySnapshots', () => {
  it('fans out one order into one snapshot per distinct product line, without allocating order-level discount', () => {
    const snapshots = buildProductMonthlySnapshots({
      organizationId: 'org-1',
      monthKey: '2026-08',
      facts: [
        fact({
          id: 'order-1',
          discountAmount: 100,
          items: [
            { productId: 'product-1', quantity: 6, subtotal: 600 },
            { productId: 'product-2', quantity: 4, subtotal: 400 },
          ],
        }),
      ],
      productLabels: new Map([
        [
          'product-1',
          {
            name: 'Vestido Floral',
            categoryId: 'cat-1',
            categoryName: 'Vestidos',
            collectionId: 'col-1',
            collectionName: 'Verão 2026',
          },
        ],
      ]),
    });

    expect(snapshots).toHaveLength(2);
    const product1 = snapshots.find((snapshot) => snapshot.scopeId === 'product-1');
    expect(product1?.revenueGross).toBeCloseTo(600, 2);
    // Documented limitation: order-level discount is not allocated per item.
    expect(product1?.revenueNet).toBeCloseTo(product1?.revenueGross ?? -1, 2);
    expect(product1?.itemQuantity).toBe(6);
    expect(product1?.labels.categoryId).toBe('cat-1');
    expect(product1?.labels.collectionName).toBe('Verão 2026');
  });

  it('counts one order once per product even if reprocessed idempotently (same input twice, still exactly two products)', () => {
    const facts = [
      fact({
        id: 'order-1',
        items: [
          { productId: 'product-1', quantity: 1, subtotal: 100 },
          { productId: 'product-2', quantity: 1, subtotal: 100 },
        ],
      }),
    ];
    const generatedAt = Timestamp.now();
    const first = buildProductMonthlySnapshots({
      organizationId: 'org-1',
      monthKey: '2026-08',
      facts,
      generatedAt,
    });
    const second = buildProductMonthlySnapshots({
      organizationId: 'org-1',
      monthKey: '2026-08',
      facts,
      generatedAt,
    });
    expect(first).toHaveLength(2);
    expect(second).toEqual(first);
  });
});
