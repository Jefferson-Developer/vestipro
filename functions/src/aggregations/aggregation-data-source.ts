import {
  Timestamp,
  getFirestore,
  type Firestore,
} from 'firebase-admin/firestore';

import {
  AGGREGATE_COLLECTION_BY_DIMENSION,
  buildAggregateDocId,
  extractOrderFact,
  type AggregateSnapshotDoc,
  type AggregationDimension,
  type OrderAggregationFact,
} from './aggregation-shared';
import type {
  CustomerLabel,
  ProductLabel,
  SellerLabel,
} from './aggregation-builders';

const ID_BATCH_SIZE = 30;
const WRITE_BATCH_SIZE = 450;

/**
 * Everything an aggregator needs from Firestore, behind one interface — the
 * same "inject a persistence port, test the orchestration in-memory"
 * pattern `functions/src/inventory/sync-stock-alerts.ts` already
 * established for `StockAlertPersistence`. Lets
 * `recompute-sales-daily-on-order-write.ts`/`recompute-monthly-aggregates.ts`
 * be unit-tested (create/idempotent-recompute/multi-tenant isolation) with
 * an in-memory fake, with the Firebase Emulator Suite test reserved for the
 * thin Cloud Functions glue itself.
 */
export interface AggregationDataSource {
  /** Every order whose `createdAt` falls within [start, end] (inclusive) for
   * one organization/company — the exact same `companyId` equality +
   * `deletedAt` equality + `createdAt` range shape already indexed for order
   * listing (`firestore.indexes.json`), so no new composite index is
   * required. */
  loadOrderFacts(params: {
    organizationId: string;
    companyId: string;
    start: Date;
    end: Date;
  }): Promise<OrderAggregationFact[]>;
  loadCustomerLabels(
    organizationId: string,
    customerIds: readonly string[],
  ): Promise<Map<string, CustomerLabel>>;
  loadSellerLabels(
    organizationId: string,
    sellerIds: readonly string[],
  ): Promise<Map<string, SellerLabel>>;
  loadProductLabels(
    organizationId: string,
    productIds: readonly string[],
  ): Promise<Map<string, ProductLabel>>;
  /** Active companies of the organization — used only when a manual/batch
   * recompute is not scoped to a single company. */
  listActiveCompanyIds(organizationId: string): Promise<string[]>;
  listActiveOrganizationIds(): Promise<string[]>;
  upsertAggregates(
    organizationId: string,
    dimension: AggregationDimension,
    docs: readonly AggregateSnapshotDoc[],
  ): Promise<void>;
}

export function createFirestoreAggregationDataSource(
  db: Firestore = getFirestore(),
): AggregationDataSource {
  return {
    async loadOrderFacts({ organizationId, companyId, start, end }) {
      const snapshot = await db
        .collection('organizations')
        .doc(organizationId)
        .collection('orders')
        .where('companyId', '==', companyId)
        .where('deletedAt', '==', null)
        .where('createdAt', '>=', Timestamp.fromDate(start))
        .where('createdAt', '<=', Timestamp.fromDate(end))
        .get();
      return snapshot.docs
        .map((doc) => extractOrderFact(doc.id, doc.data()))
        .filter((fact): fact is OrderAggregationFact => fact != null);
    },

    async loadCustomerLabels(organizationId, customerIds) {
      const result = new Map<string, CustomerLabel>();
      const collectionRef = db
        .collection('organizations')
        .doc(organizationId)
        .collection('customers');
      for (const chunk of chunkIds(customerIds)) {
        if (chunk.length === 0) continue;
        const snapshot = await collectionRef
          .where('__name__', 'in', chunk)
          .get();
        for (const doc of snapshot.docs) {
          const data = doc.data();
          if (typeof data.name === 'string') {
            result.set(doc.id, {
              name: data.name,
              segment:
                typeof data.segment === 'string' ? data.segment : null,
            });
          }
        }
      }
      return result;
    },

    async loadSellerLabels(organizationId, sellerIds) {
      // Seller display names live on the top-level `users/{uid}` profile
      // (`name` field) — same source `resolveActorName`
      // (`functions/src/invites/invite-shared.ts`) already reads from,
      // never on the per-organization `members` document itself (which only
      // carries `roleName`/`teamIds`/`status`).
      const result = new Map<string, SellerLabel>();
      const collectionRef = db.collection('users');
      const membershipRef = db
        .collection('organizations')
        .doc(organizationId)
        .collection('members');
      for (const chunk of chunkIds(sellerIds)) {
        if (chunk.length === 0) continue;
        const snapshot = await collectionRef
          .where('__name__', 'in', chunk)
          .get();
        for (const doc of snapshot.docs) {
          const data = doc.data();
          if (typeof data.name === 'string' && data.name.trim().length > 0) {
            result.set(doc.id, { name: data.name, teamIds: [] });
          }
        }
        const memberships = await membershipRef.where('__name__', 'in', chunk).get();
        for (const member of memberships.docs) {
          const current = result.get(member.id) ?? { name: member.id };
          const rawTeamIds = member.data().teamIds;
          result.set(member.id, {
            ...current,
            teamIds: Array.isArray(rawTeamIds)
              ? rawTeamIds.filter((value): value is string => typeof value === 'string')
              : [],
          });
        }
      }
      return result;
    },

    async loadProductLabels(organizationId, productIds) {
      const result = new Map<string, ProductLabel>();
      const collectionRef = db
        .collection('organizations')
        .doc(organizationId)
        .collection('products');
      for (const chunk of chunkIds(productIds)) {
        if (chunk.length === 0) continue;
        const snapshot = await collectionRef
          .where('__name__', 'in', chunk)
          .get();
        for (const doc of snapshot.docs) {
          const data = doc.data();
          if (typeof data.name === 'string') {
            result.set(doc.id, {
              name: data.name,
              categoryId:
                typeof data.categoryId === 'string' ? data.categoryId : null,
              categoryName:
                typeof data.categoryName === 'string'
                  ? data.categoryName
                  : null,
              collectionId:
                typeof data.collectionId === 'string'
                  ? data.collectionId
                  : null,
              collectionName:
                typeof data.collectionName === 'string'
                  ? data.collectionName
                  : null,
            });
          }
        }
      }
      return result;
    },

    async listActiveCompanyIds(organizationId) {
      const snapshot = await db
        .collection('organizations')
        .doc(organizationId)
        .collection('companies')
        .where('status', '==', 'active')
        .get();
      return snapshot.docs.map((doc) => doc.id);
    },

    async listActiveOrganizationIds() {
      const snapshot = await db
        .collection('organizations')
        .where('status', '==', 'active')
        .get();
      return snapshot.docs
        .filter((doc) => doc.data().deletedAt == null)
        .map((doc) => doc.id);
    },

    async upsertAggregates(organizationId, dimension, docs) {
      if (docs.length === 0) return;
      const collectionRef = db
        .collection('organizations')
        .doc(organizationId)
        .collection(AGGREGATE_COLLECTION_BY_DIMENSION[dimension]);
      let batch = db.batch();
      let pending = 0;
      for (const snapshotDoc of docs) {
        const id = buildAggregateDocId(
          snapshotDoc.companyId,
          snapshotDoc.scopeId,
          snapshotDoc.periodKey,
        );
        batch.set(collectionRef.doc(id), snapshotDoc);
        pending += 1;
        if (pending >= WRITE_BATCH_SIZE) {
          await batch.commit();
          batch = db.batch();
          pending = 0;
        }
      }
      if (pending > 0) {
        await batch.commit();
      }
    },
  };
}

function chunkIds(ids: readonly string[]): string[][] {
  const unique = [...new Set(ids.filter((id) => id.trim().length > 0))];
  const chunks: string[][] = [];
  for (let i = 0; i < unique.length; i += ID_BATCH_SIZE) {
    chunks.push(unique.slice(i, i + ID_BATCH_SIZE));
  }
  return chunks;
}
