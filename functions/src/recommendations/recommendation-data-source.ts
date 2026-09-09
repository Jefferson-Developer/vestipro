import {
  getFirestore,
  type DocumentData,
  type Firestore,
} from 'firebase-admin/firestore';

import {
  createFirestoreAggregationDataSource,
  type AggregationDataSource,
} from '../aggregations/aggregation-data-source';
import type { OrderAggregationFact } from '../aggregations/aggregation-shared';
import type { ProductLabel } from '../aggregations/aggregation-builders';

/** One active customer row, already carrying the exact visibility fields
 * `firestore.rules`' `canReadProductRecommendation` needs to enforce the
 * same carteira-visibility rule already applied to the `Customer` document
 * itself (`primarySalesRepId`/`teamId`, TASK-045/TASK-051). A customer
 * document missing either field (legacy/incomplete data) is skipped —
 * `listActiveCustomers` never returns a row a Security Rule could not
 * evaluate deterministically. */
export interface RecommendationCustomerRow {
  customerId: string;
  primarySalesRepId: string;
  teamId: string;
}

/**
 * Injectable persistence port for the weekly product-recommendation
 * calculation — same "port + Firestore adapter + in-memory fake for unit
 * tests" shape already used by `../demand-forecast/demand-forecast-data-source.ts`
 * (TASK-185) and `../replenishment/calculate-replenishment-suggestions.ts`
 * (TASK-184).
 *
 * [loadOrderFacts]/[loadProductLabels]/[listActiveCompanyIds]/
 * [listActiveOrganizationIds] are never reimplemented here — the Firestore
 * adapter below composes `AggregationDataSource` (TASK-133) for those, since
 * the exact same raw-order-with-items read it already exposes is precisely
 * what basket/co-occurrence analysis needs (never a duplicated order parser).
 */
export interface ProductRecommendationPersistence {
  listActiveOrganizationIds(): Promise<ReadonlyArray<string>>;
  listActiveCompanyIds(organizationId: string): Promise<ReadonlyArray<string>>;
  loadOrderFacts(params: {
    organizationId: string;
    companyId: string;
    start: Date;
    end: Date;
  }): Promise<OrderAggregationFact[]>;
  loadProductLabels(
    organizationId: string,
    productIds: readonly string[],
  ): Promise<Map<string, ProductLabel>>;
  /** Every active (non-deleted) customer of the company — read once, fully
   * (no filter beyond `companyId`/`status`/`deletedAt`, applied in-memory),
   * same accepted "whole collection scan per company/org batch job" shape
   * already used by `../customers/recalculate-customer-scores.ts`. Includes
   * customers with zero orders — a `customer`-scope recommendation document
   * must exist even for a brand-new customer (fallback, never a missing
   * document, `tasks.md`/TASK-190). */
  listActiveCustomers(
    organizationId: string,
    companyId: string,
  ): Promise<ReadonlyArray<RecommendationCustomerRow>>;
  saveRecommendation(
    organizationId: string,
    documentId: string,
    data: DocumentData,
  ): Promise<void>;
}

export function createFirestoreProductRecommendationDataSource(
  db: Firestore = getFirestore(),
): ProductRecommendationPersistence {
  const aggregationDataSource: AggregationDataSource =
    createFirestoreAggregationDataSource(db);

  return {
    listActiveOrganizationIds: aggregationDataSource.listActiveOrganizationIds,
    listActiveCompanyIds: aggregationDataSource.listActiveCompanyIds,
    loadOrderFacts: aggregationDataSource.loadOrderFacts,
    loadProductLabels: aggregationDataSource.loadProductLabels,

    async listActiveCustomers(organizationId, companyId) {
      const snapshot = await db
        .collection('organizations')
        .doc(organizationId)
        .collection('customers')
        .get();

      const rows: RecommendationCustomerRow[] = [];
      for (const doc of snapshot.docs) {
        const data = doc.data();
        if (
          data.companyId !== companyId ||
          data.status !== 'active' ||
          data.deletedAt != null
        ) {
          continue;
        }
        const primarySalesRepId = data.primarySalesRepId;
        const teamId = data.teamId;
        if (
          typeof primarySalesRepId !== 'string' ||
          primarySalesRepId.trim().length === 0 ||
          typeof teamId !== 'string' ||
          teamId.trim().length === 0
        ) {
          continue;
        }
        rows.push({ customerId: doc.id, primarySalesRepId, teamId });
      }
      return rows;
    },

    async saveRecommendation(organizationId, documentId, data) {
      await db
        .collection('organizations')
        .doc(organizationId)
        .collection('productRecommendations')
        .doc(documentId)
        .set(data);
    },
  };
}
