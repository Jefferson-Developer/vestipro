import type {
  CustomerLabel,
  ProductLabel,
  SellerLabel,
} from '../../src/aggregations/aggregation-builders';
import type { AggregationDataSource } from '../../src/aggregations/aggregation-data-source';
import type {
  AggregateSnapshotDoc,
  AggregationDimension,
  OrderAggregationFact,
} from '../../src/aggregations/aggregation-shared';
import { buildAggregateDocId } from '../../src/aggregations/aggregation-shared';

/**
 * In-memory fake of {@link AggregationDataSource}, same
 * "inject a persistence port, test the orchestration without the emulator"
 * pattern already used by `InMemoryStockAlertPersistence`
 * (`functions/test/inventory/sync-stock-alerts.test.ts`) — every recompute
 * function in `functions/src/aggregations` accepts an
 * `AggregationDataSource`, so this exercises the exact same code path a
 * real Firestore-backed run would, without needing the Emulator Suite.
 */
export class InMemoryAggregationDataSource implements AggregationDataSource {
  orders: OrderAggregationFact[] = [];
  customerLabels = new Map<string, CustomerLabel>();
  sellerLabels = new Map<string, SellerLabel>();
  productLabels = new Map<string, ProductLabel>();
  activeCompanyIdsByOrganization = new Map<string, string[]>();
  activeOrganizationIds: string[] = [];

  readonly writesByDimension = new Map<
    AggregationDimension,
    Map<string, AggregateSnapshotDoc>
  >();

  async loadOrderFacts(params: {
    organizationId: string;
    companyId: string;
    start: Date;
    end: Date;
  }): Promise<OrderAggregationFact[]> {
    return this.orders.filter(
      (order) =>
        order.organizationId === params.organizationId &&
        order.companyId === params.companyId &&
        order.createdAt.toDate() >= params.start &&
        order.createdAt.toDate() <= params.end,
    );
  }

  async loadCustomerLabels(
    _organizationId: string,
    customerIds: readonly string[],
  ): Promise<Map<string, CustomerLabel>> {
    const result = new Map<string, CustomerLabel>();
    for (const id of customerIds) {
      const label = this.customerLabels.get(id);
      if (label) result.set(id, label);
    }
    return result;
  }

  async loadSellerLabels(
    _organizationId: string,
    sellerIds: readonly string[],
  ): Promise<Map<string, SellerLabel>> {
    const result = new Map<string, SellerLabel>();
    for (const id of sellerIds) {
      const label = this.sellerLabels.get(id);
      if (label) result.set(id, label);
    }
    return result;
  }

  async loadProductLabels(
    _organizationId: string,
    productIds: readonly string[],
  ): Promise<Map<string, ProductLabel>> {
    const result = new Map<string, ProductLabel>();
    for (const id of productIds) {
      const label = this.productLabels.get(id);
      if (label) result.set(id, label);
    }
    return result;
  }

  async listActiveCompanyIds(organizationId: string): Promise<string[]> {
    return this.activeCompanyIdsByOrganization.get(organizationId) ?? [];
  }

  async listActiveOrganizationIds(): Promise<string[]> {
    return this.activeOrganizationIds;
  }

  async upsertAggregates(
    _organizationId: string,
    dimension: AggregationDimension,
    docs: readonly AggregateSnapshotDoc[],
  ): Promise<void> {
    // Mirrors `createFirestoreAggregationDataSource`'s own early return for
    // an empty batch: writing nothing must leave no trace at all (not even
    // an empty bucket), so tests can assert "no snapshot for this
    // dimension" the same way against both the fake and the real
    // implementation.
    if (docs.length === 0) return;
    const bucket = this.writesByDimension.get(dimension) ?? new Map();
    for (const doc of docs) {
      const id = buildAggregateDocId(doc.companyId, doc.scopeId, doc.periodKey);
      bucket.set(id, doc);
    }
    this.writesByDimension.set(dimension, bucket);
  }
}
