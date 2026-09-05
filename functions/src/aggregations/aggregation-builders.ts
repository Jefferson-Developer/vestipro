import { Timestamp } from 'firebase-admin/firestore';

import {
  isRevenueRecognized,
  netRevenueOf,
  roundCurrency,
  type AggregateSnapshotDoc,
  type OrderAggregationFact,
} from './aggregation-shared';

export interface ProductLabel {
  name: string;
  categoryId?: string | null;
  categoryName?: string | null;
  collectionId?: string | null;
  collectionName?: string | null;
}

export interface CustomerLabel {
  name: string;
  segment?: string | null;
}

export interface SellerLabel {
  name: string;
  teamIds?: readonly string[];
}

/** Builds one `salesDaily` snapshot per company found in [facts] — every
 * fact passed in is assumed to already belong to the single [dayKey] being
 * recomputed (caller's responsibility, mirrors `buildSnapshotsForAllScopes`
 * in `recompute-stock-turnover-metrics.ts`). */
export function buildSalesDailySnapshots(params: {
  organizationId: string;
  dayKey: string;
  facts: readonly OrderAggregationFact[];
  generatedAt?: Timestamp;
}): AggregateSnapshotDoc[] {
  const generatedAt = params.generatedAt ?? Timestamp.now();
  const grouped = groupBy(
    params.facts.filter(isRevenueRecognized),
    (fact) => fact.companyId,
  );
  return [...grouped.entries()].map(([companyId, companyFacts]) =>
    buildOrderLevelSnapshot({
      organizationId: params.organizationId,
      dimension: 'salesDaily',
      companyId,
      scopeId: companyId,
      periodKey: params.dayKey,
      facts: companyFacts,
      labels: {},
      generatedAt,
    }),
  );
}

/** Builds the near-real-time per-seller rows used by the representative
 * dashboard's "venda de hoje" card. */
export function buildSellerDailySnapshots(params: {
  organizationId: string;
  dayKey: string;
  facts: readonly OrderAggregationFact[];
  generatedAt?: Timestamp;
}): AggregateSnapshotDoc[] {
  const generatedAt = params.generatedAt ?? Timestamp.now();
  const grouped = groupBy(
    params.facts.filter(isRevenueRecognized),
    (fact) => `${fact.companyId}::${fact.sellerId}`,
  );
  return [...grouped.values()].map((sellerFacts) => {
    const first = sellerFacts[0];
    return buildOrderLevelSnapshot({
      organizationId: params.organizationId,
      dimension: 'sellerDaily',
      companyId: first.companyId,
      scopeId: first.sellerId,
      periodKey: params.dayKey,
      facts: sellerFacts,
      labels: {},
      generatedAt,
    });
  });
}

export function buildCustomerMonthlySnapshots(params: {
  organizationId: string;
  monthKey: string;
  facts: readonly OrderAggregationFact[];
  customerLabels?: ReadonlyMap<string, CustomerLabel>;
  generatedAt?: Timestamp;
}): AggregateSnapshotDoc[] {
  const generatedAt = params.generatedAt ?? Timestamp.now();
  const recognized = params.facts.filter(isRevenueRecognized);
  const grouped = groupBy(
    recognized,
    (fact) => `${fact.companyId}::${fact.customerId}`,
  );
  return [...grouped.entries()].map(([, companyFacts]) => {
    const first = companyFacts[0];
    const label = params.customerLabels?.get(first.customerId);
    return buildOrderLevelSnapshot({
      organizationId: params.organizationId,
      dimension: 'customerMonthly',
      companyId: first.companyId,
      scopeId: first.customerId,
      periodKey: params.monthKey,
      facts: companyFacts,
      labels: {
        ...(label?.name ? { customerName: label.name } : {}),
        ...(label?.segment ? { segment: label.segment } : {}),
      },
      generatedAt,
    });
  });
}

export function buildSellerMonthlySnapshots(params: {
  organizationId: string;
  monthKey: string;
  facts: readonly OrderAggregationFact[];
  sellerLabels?: ReadonlyMap<string, SellerLabel>;
  generatedAt?: Timestamp;
}): AggregateSnapshotDoc[] {
  const generatedAt = params.generatedAt ?? Timestamp.now();
  const recognized = params.facts.filter(isRevenueRecognized);
  const grouped = groupBy(
    recognized,
    (fact) => `${fact.companyId}::${fact.sellerId}`,
  );
  const snapshots = [...grouped.entries()].map(([, companyFacts]) => {
    const first = companyFacts[0];
    const label = params.sellerLabels?.get(first.sellerId);
    return buildOrderLevelSnapshot({
      organizationId: params.organizationId,
      dimension: 'sellerMonthly',
      companyId: first.companyId,
      scopeId: first.sellerId,
      periodKey: params.monthKey,
      facts: companyFacts,
      labels: label?.name ? { sellerName: label.name } : {},
      generatedAt,
    });
  });
  for (const snapshot of snapshots) {
    const teamIds = params.sellerLabels?.get(snapshot.scopeId)?.teamIds ?? [];
    const primaryTeamId = [...teamIds].sort()[0];
    if (!primaryTeamId) continue;
    const peers = snapshots
      .filter(
        (candidate) =>
          candidate.companyId === snapshot.companyId &&
          (params.sellerLabels?.get(candidate.scopeId)?.teamIds ?? []).includes(
            primaryTeamId,
          ),
      )
      .sort((a, b) => b.revenueNet - a.revenueNet || a.scopeId.localeCompare(b.scopeId));
    snapshot.labels = {
      ...snapshot.labels,
      teamId: primaryTeamId,
      teamRank: String(peers.findIndex((peer) => peer.scopeId === snapshot.scopeId) + 1),
      teamSize: String(peers.length),
    };
  }
  return snapshots;
}

export function buildRegionMonthlySnapshots(params: {
  organizationId: string;
  monthKey: string;
  facts: readonly OrderAggregationFact[];
  productLabels?: ReadonlyMap<string, ProductLabel>;
  generatedAt?: Timestamp;
}): AggregateSnapshotDoc[] {
  const generatedAt = params.generatedAt ?? Timestamp.now();
  const recognized = params.facts.filter(isRevenueRecognized);
  const grouped = groupBy(
    recognized,
    (fact) => `${fact.companyId}::${fact.region}::${fact.city ?? 'UNKNOWN'}`,
  );
  return [...grouped.entries()].map(([, companyFacts]) => {
    const first = companyFacts[0];
    const city = first.city ?? 'UNKNOWN';
    const productQuantity = new Map<string, number>();
    for (const fact of companyFacts) {
      for (const item of fact.items) {
        const name = params.productLabels?.get(item.productId)?.name ?? item.productId;
        productQuantity.set(name, (productQuantity.get(name) ?? 0) + item.quantity);
      }
    }
    const topProducts = [...productQuantity.entries()]
      .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
      .slice(0, 3)
      .map(([name, quantity]) => `${name.replace(/[|:]/g, ' ')}:${quantity}`)
      .join('|');
    return buildOrderLevelSnapshot({
      organizationId: params.organizationId,
      dimension: 'regionMonthly',
      companyId: first.companyId,
      scopeId: city === 'UNKNOWN' ? first.region : `${first.region}:${city}`,
      periodKey: params.monthKey,
      facts: companyFacts,
      labels: {
        region: first.region,
        state: first.region,
        city,
        customerIds: [...new Set(companyFacts.map((fact) => fact.customerId))].join(','),
        orderIds: [...new Set(companyFacts.map((fact) => fact.id))].join(','),
        sellerIds: [...new Set(companyFacts.map((fact) => fact.sellerId))].join(','),
        topProducts,
      },
      generatedAt,
    });
  });
}

/**
 * Unlike the other four dimensions, `productMonthly` groups by *item*, not
 * by order — one order with three distinct products contributes to three
 * different snapshots. Order-level `discountAmount`/`surchargeAmount`/
 * `shippingAmount` are **not** allocated per item (no per-item discount
 * breakdown is persisted on `OrderItem` today — see
 * `functions/src/orders/submit-order.ts`'s `orderData.items` mapping), so
 * `revenueNet` here always equals `revenueGross` (sum of `item.subtotal`).
 * Documented limitation: if a future task starts persisting per-item
 * discount, this function must be revisited to stop assuming
 * `revenueNet === revenueGross`.
 */
export function buildProductMonthlySnapshots(params: {
  organizationId: string;
  monthKey: string;
  facts: readonly OrderAggregationFact[];
  productLabels?: ReadonlyMap<string, ProductLabel>;
  generatedAt?: Timestamp;
}): AggregateSnapshotDoc[] {
  const generatedAt = params.generatedAt ?? Timestamp.now();
  const recognized = params.facts.filter(isRevenueRecognized);

  interface ProductAccumulator {
    companyId: string;
    productId: string;
    revenue: number;
    quantity: number;
    orderIds: Set<string>;
  }
  const accumulators = new Map<string, ProductAccumulator>();
  for (const fact of recognized) {
    for (const item of fact.items) {
      const key = `${fact.companyId}::${item.productId}`;
      const accumulator = accumulators.get(key) ?? {
        companyId: fact.companyId,
        productId: item.productId,
        revenue: 0,
        quantity: 0,
        orderIds: new Set<string>(),
      };
      accumulator.revenue += item.subtotal;
      accumulator.quantity += item.quantity;
      accumulator.orderIds.add(fact.id);
      accumulators.set(key, accumulator);
    }
  }

  return [...accumulators.values()].map((accumulator) => {
    const label = params.productLabels?.get(accumulator.productId);
    const revenue = roundCurrency(accumulator.revenue);
    return {
      organizationId: params.organizationId,
      companyId: accumulator.companyId,
      dimension: 'productMonthly',
      scopeId: accumulator.productId,
      periodKey: params.monthKey,
      revenueGross: revenue,
      revenueNet: revenue,
      discountAmount: 0,
      orderCount: accumulator.orderIds.size,
      itemQuantity: accumulator.quantity,
      labels: {
        ...(label?.name ? { productName: label.name } : {}),
        ...(label?.categoryId ? { categoryId: label.categoryId } : {}),
        ...(label?.categoryName ? { categoryName: label.categoryName } : {}),
        ...(label?.collectionId ? { collectionId: label.collectionId } : {}),
        ...(label?.collectionName
          ? { collectionName: label.collectionName }
          : {}),
      },
      generatedAt,
      version: 1,
    } satisfies AggregateSnapshotDoc;
  });
}

function buildOrderLevelSnapshot(params: {
  organizationId: string;
  dimension: AggregateSnapshotDoc['dimension'];
  companyId: string;
  scopeId: string;
  periodKey: string;
  facts: readonly OrderAggregationFact[];
  labels: Readonly<Record<string, string>>;
  generatedAt: Timestamp;
}): AggregateSnapshotDoc {
  const revenueGross = roundCurrency(
    params.facts.reduce((sum, fact) => sum + fact.itemsSubtotal, 0),
  );
  const revenueNet = roundCurrency(
    params.facts.reduce((sum, fact) => sum + netRevenueOf(fact), 0),
  );
  const discountAmount = roundCurrency(
    params.facts.reduce((sum, fact) => sum + fact.discountAmount, 0),
  );
  const itemQuantity = params.facts.reduce(
    (sum, fact) => sum + fact.itemQuantity,
    0,
  );
  return {
    organizationId: params.organizationId,
    companyId: params.companyId,
    dimension: params.dimension,
    scopeId: params.scopeId,
    periodKey: params.periodKey,
    revenueGross,
    revenueNet,
    discountAmount,
    orderCount: params.facts.length,
    itemQuantity,
    labels: params.labels,
    generatedAt: params.generatedAt,
    version: 1,
  };
}

function groupBy<T>(
  items: readonly T[],
  keyOf: (item: T) => string,
): Map<string, T[]> {
  const grouped = new Map<string, T[]>();
  for (const item of items) {
    const key = keyOf(item);
    const current = grouped.get(key) ?? [];
    current.push(item);
    grouped.set(key, current);
  }
  return grouped;
}
