import { Timestamp } from 'firebase-admin/firestore';

import {
  recomputeSalesDailyForOrderChange,
  resolveAffectedSalesDay,
} from '../../src/aggregations/recompute-sales-daily-on-order-write';
import type { OrderAggregationFact } from '../../src/aggregations/aggregation-shared';
import { InMemoryAggregationDataSource } from './in-memory-aggregation-data-source';

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

describe('resolveAffectedSalesDay', () => {
  it('resolves organization/company/day from the "after" snapshot on create/update', () => {
    const affected = resolveAffectedSalesDay(
      undefined,
      {
        organizationId: 'org-1',
        companyId: 'company-1',
        createdAt: Timestamp.fromDate(new Date('2026-08-15T23:59:00.000Z')),
      },
    );
    expect(affected).toEqual({
      organizationId: 'org-1',
      companyId: 'company-1',
      dayKey: '2026-08-15',
    });
  });

  it('falls back to the "before" snapshot on delete (after is undefined)', () => {
    const affected = resolveAffectedSalesDay(
      {
        organizationId: 'org-1',
        companyId: 'company-1',
        createdAt: Timestamp.fromDate(new Date('2026-08-10T00:00:00.000Z')),
      },
      undefined,
    );
    expect(affected?.dayKey).toBe('2026-08-10');
  });

  it('returns null for a malformed document', () => {
    expect(resolveAffectedSalesDay(undefined, { organizationId: 'org-1' })).toBeNull();
  });
});

describe('recomputeSalesDailyForOrderChange', () => {
  it('recomputes the salesDaily snapshot from every order that exists right now for that day/company', async () => {
    const dataSource = new InMemoryAggregationDataSource();
    dataSource.orders = [
      fact({ id: 'order-1', itemsSubtotal: 1000 }),
      fact({ id: 'order-2', itemsSubtotal: 500 }),
    ];

    await recomputeSalesDailyForOrderChange(
      { organizationId: 'org-1', companyId: 'company-1', dayKey: '2026-08-15' },
      dataSource,
      Timestamp.now(),
    );

    const written = dataSource.writesByDimension.get('salesDaily');
    expect(written?.size).toBe(1);
    const snapshot = [...(written?.values() ?? [])][0];
    expect(snapshot.orderCount).toBe(2);
    expect(snapshot.revenueGross).toBeCloseTo(1500, 2);
  });

  it('is idempotent: recomputing the same day twice yields the exact same snapshot (upsert overwrite, no duplication)', async () => {
    const dataSource = new InMemoryAggregationDataSource();
    dataSource.orders = [fact({ id: 'order-1', itemsSubtotal: 1000 })];
    const generatedAt = Timestamp.now();

    await recomputeSalesDailyForOrderChange(
      { organizationId: 'org-1', companyId: 'company-1', dayKey: '2026-08-15' },
      dataSource,
      generatedAt,
    );
    await recomputeSalesDailyForOrderChange(
      { organizationId: 'org-1', companyId: 'company-1', dayKey: '2026-08-15' },
      dataSource,
      generatedAt,
    );

    const written = dataSource.writesByDimension.get('salesDaily');
    expect(written?.size).toBe(1);
  });

  it('a second order arriving on the same day is reflected without touching other days (self-healing recompute)', async () => {
    const dataSource = new InMemoryAggregationDataSource();
    dataSource.orders = [fact({ id: 'order-1', itemsSubtotal: 1000 })];

    await recomputeSalesDailyForOrderChange(
      { organizationId: 'org-1', companyId: 'company-1', dayKey: '2026-08-15' },
      dataSource,
    );
    dataSource.orders.push(
      fact({
        id: 'order-2',
        itemsSubtotal: 300,
        createdAt: Timestamp.fromDate(new Date('2026-08-15T18:00:00.000Z')),
      }),
    );
    await recomputeSalesDailyForOrderChange(
      { organizationId: 'org-1', companyId: 'company-1', dayKey: '2026-08-15' },
      dataSource,
    );

    const written = dataSource.writesByDimension.get('salesDaily');
    const snapshot = [...(written?.values() ?? [])][0];
    expect(snapshot.orderCount).toBe(2);
    expect(snapshot.revenueGross).toBeCloseTo(1300, 2);
  });

  it('never mixes orders from a different organization into the recomputed day (multi-tenant isolation)', async () => {
    const dataSource = new InMemoryAggregationDataSource();
    dataSource.orders = [
      fact({ id: 'order-1', organizationId: 'org-1', itemsSubtotal: 1000 }),
      fact({ id: 'order-2', organizationId: 'org-2', itemsSubtotal: 999999 }),
    ];

    await recomputeSalesDailyForOrderChange(
      { organizationId: 'org-1', companyId: 'company-1', dayKey: '2026-08-15' },
      dataSource,
    );

    const written = dataSource.writesByDimension.get('salesDaily');
    expect(written?.size).toBe(1);
    const snapshot = [...(written?.values() ?? [])][0];
    expect(snapshot.organizationId).toBe('org-1');
    expect(snapshot.revenueGross).toBeCloseTo(1000, 2);
  });

  it('a day with zero orders produces no snapshot at all (no empty/zeroed document written)', async () => {
    const dataSource = new InMemoryAggregationDataSource();
    await recomputeSalesDailyForOrderChange(
      { organizationId: 'org-1', companyId: 'company-1', dayKey: '2026-08-15' },
      dataSource,
    );
    expect(dataSource.writesByDimension.get('salesDaily')).toBeUndefined();
  });
});
