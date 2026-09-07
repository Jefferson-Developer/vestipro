import {
  getFirestore,
  type DocumentData,
  type Firestore,
} from 'firebase-admin/firestore';

/** One row read from `productMonthlyAggregates` (TASK-133) for a single
 * company/month — the raw input {@link DemandForecastPersistence} exposes so
 * the orchestrator (`calculate-demand-forecasts.ts`) can build the
 * product-scope AND collection-scope history series out of the exact same
 * read, instead of querying twice. */
export interface ProductMonthlyRow {
  productId: string;
  itemQuantity: number;
  productName: string | null;
  collectionId: string | null;
  collectionName: string | null;
}

/** One row read from `regionMonthlyAggregates` (TASK-133) for a single
 * company/month, already collapsed to the `region` (state) level — a single
 * `regionMonthlyAggregates` document can be scoped to `region:city`, but
 * demand forecasting groups at the coarser `region` level only (documented
 * simplification, `calculate-demand-forecasts.ts`). */
export interface RegionMonthlyRow {
  region: string;
  itemQuantity: number;
}

/**
 * Injectable persistence port for the monthly demand-forecast calculation —
 * same "port + Firestore adapter + in-memory fake for unit tests" shape
 * already used by `../replenishment/calculate-replenishment-suggestions.ts`'s
 * `ReplenishmentPersistence` (TASK-184), letting
 * `functions/test/demand-forecast/calculate-demand-forecasts.test.ts`
 * exercise idempotency/multi-tenant isolation entirely without the Firestore
 * Emulator (unavailable in this sandbox — no Java, same documented
 * limitation as TASK-094/TASK-133/TASK-184).
 *
 * [loadProductMonthlyRows]/[loadRegionMonthlyRows] deliberately read one
 * whole month at a time (not one specific product/region's own time series)
 * — reusing `productMonthlyAggregates`/`regionMonthlyAggregates` exactly as
 * TASK-133 already indexes them (`companyId`+`periodKey` equality, no new
 * composite index required) and letting the orchestrator build every
 * product/collection/region's history out of the same `DEFAULT_LOOKBACK_MONTHS`
 * reads, instead of one query per scope. Documented trade-off: a company
 * with a very large product catalog makes each of these reads return one
 * row per active product for that month — acceptable for a monthly batch
 * job, revisit only if a real organization's catalog makes this too slow.
 */
export interface DemandForecastPersistence {
  listActiveOrganizationIds(): Promise<ReadonlyArray<string>>;
  listActiveCompanyIds(organizationId: string): Promise<ReadonlyArray<string>>;
  loadProductMonthlyRows(
    organizationId: string,
    companyId: string,
    monthKey: string,
  ): Promise<ReadonlyArray<ProductMonthlyRow>>;
  loadRegionMonthlyRows(
    organizationId: string,
    companyId: string,
    monthKey: string,
  ): Promise<ReadonlyArray<RegionMonthlyRow>>;
  saveForecast(
    organizationId: string,
    documentId: string,
    data: DocumentData,
  ): Promise<void>;
}

export function createFirestoreDemandForecastDataSource(
  db: Firestore = getFirestore(),
): DemandForecastPersistence {
  return {
    async listActiveOrganizationIds(): Promise<ReadonlyArray<string>> {
      const snapshot = await db.collection('organizations').get();
      return snapshot.docs
        .filter((doc) => {
          const data = doc.data();
          return data.status === 'active' && data.deletedAt == null;
        })
        .map((doc) => doc.id);
    },

    async listActiveCompanyIds(organizationId: string): Promise<ReadonlyArray<string>> {
      const snapshot = await db
        .collection('organizations')
        .doc(organizationId)
        .collection('companies')
        .where('status', '==', 'active')
        .get();
      return snapshot.docs.map((doc) => doc.id);
    },

    async loadProductMonthlyRows(
      organizationId: string,
      companyId: string,
      monthKey: string,
    ): Promise<ReadonlyArray<ProductMonthlyRow>> {
      const snapshot = await db
        .collection('organizations')
        .doc(organizationId)
        .collection('productMonthlyAggregates')
        .where('companyId', '==', companyId)
        .where('periodKey', '==', monthKey)
        .get();
      return snapshot.docs
        .map((doc) => asProductMonthlyRow(doc.data()))
        .filter((row): row is ProductMonthlyRow => row != null);
    },

    async loadRegionMonthlyRows(
      organizationId: string,
      companyId: string,
      monthKey: string,
    ): Promise<ReadonlyArray<RegionMonthlyRow>> {
      const snapshot = await db
        .collection('organizations')
        .doc(organizationId)
        .collection('regionMonthlyAggregates')
        .where('companyId', '==', companyId)
        .where('periodKey', '==', monthKey)
        .get();
      const byRegion = new Map<string, number>();
      for (const doc of snapshot.docs) {
        const data = doc.data();
        const region =
          typeof data.labels?.region === 'string' && data.labels.region.trim()
            ? (data.labels.region as string)
            : null;
        const itemQuantity = data.itemQuantity;
        if (region == null || typeof itemQuantity !== 'number') continue;
        byRegion.set(region, (byRegion.get(region) ?? 0) + itemQuantity);
      }
      return [...byRegion.entries()].map(([region, itemQuantity]) => ({
        region,
        itemQuantity,
      }));
    },

    async saveForecast(
      organizationId: string,
      documentId: string,
      data: DocumentData,
    ): Promise<void> {
      await db
        .collection('organizations')
        .doc(organizationId)
        .collection('demandForecasts')
        .doc(documentId)
        .set(data);
    },
  };
}

function asProductMonthlyRow(data: DocumentData | undefined): ProductMonthlyRow | null {
  if (!data) return null;
  const productId = data.scopeId;
  const itemQuantity = data.itemQuantity;
  if (typeof productId !== 'string' || typeof itemQuantity !== 'number') {
    return null;
  }
  const labels = data.labels ?? {};
  return {
    productId,
    itemQuantity,
    productName: typeof labels.productName === 'string' ? labels.productName : null,
    collectionId: typeof labels.collectionId === 'string' ? labels.collectionId : null,
    collectionName:
      typeof labels.collectionName === 'string' ? labels.collectionName : null,
  };
}

/**
 * Reads the single month/scope actual quantity needed by
 * `evaluate-demand-forecast-accuracy.ts` to fill in a past forecast period's
 * `actualQuantity` — reuses the exact same monthly rows
 * [DemandForecastPersistence.loadProductMonthlyRows]/[loadRegionMonthlyRows]
 * already read for the forecast calculation itself (never a third,
 * duplicated aggregation query shape). A scope with no matching row for
 * [monthKey] is treated as `0` actual demand (consistent with the
 * zero-padding rule `demand-forecast-shared.ts`'s `buildMonthlyDemandSeries`
 * already applies when *building* history), never `null`/"unknown".
 */
export async function resolveActualQuantity(params: {
  persistence: DemandForecastPersistence;
  organizationId: string;
  companyId: string;
  scopeType: 'product' | 'collection' | 'region';
  scopeId: string;
  monthKey: string;
}): Promise<number> {
  const { persistence, organizationId, companyId, scopeType, scopeId, monthKey } =
    params;

  if (scopeType === 'region') {
    const rows = await persistence.loadRegionMonthlyRows(
      organizationId,
      companyId,
      monthKey,
    );
    return rows.find((row) => row.region === scopeId)?.itemQuantity ?? 0;
  }

  const rows = await persistence.loadProductMonthlyRows(
    organizationId,
    companyId,
    monthKey,
  );
  if (scopeType === 'product') {
    return rows.find((row) => row.productId === scopeId)?.itemQuantity ?? 0;
  }
  // scopeType === 'collection'
  return rows
    .filter((row) => row.collectionId === scopeId)
    .reduce((sum, row) => sum + row.itemQuantity, 0);
}

export function demandForecastDocumentId(
  companyId: string,
  scopeType: string,
  scopeId: string,
  anchorMonthKey: string,
): string {
  return `${companyId}_${scopeType}_${scopeId}_${anchorMonthKey}`;
}
