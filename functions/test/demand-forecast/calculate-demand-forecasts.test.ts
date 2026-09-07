import type { DocumentData } from 'firebase-admin/firestore';

import {
  calculateDemandForecastsForCompany,
  calculateDemandForecastsScheduledHandler,
} from '../../src/demand-forecast/calculate-demand-forecasts';
import {
  buildMonthKeyWindow,
  DEFAULT_LOOKBACK_MONTHS,
} from '../../src/demand-forecast/demand-forecast-shared';
import type {
  DemandForecastPersistence,
  ProductMonthlyRow,
  RegionMonthlyRow,
} from '../../src/demand-forecast/demand-forecast-data-source';

const ANCHOR_MONTH_KEY = '2026-06';
const MONTH_KEYS = buildMonthKeyWindow(ANCHOR_MONTH_KEY, DEFAULT_LOOKBACK_MONTHS);

class InMemoryDemandForecastPersistence implements DemandForecastPersistence {
  organizationIds: string[] = [];
  companyIdsByOrganization = new Map<string, string[]>();
  productRowsByOrgCompanyMonth = new Map<string, ProductMonthlyRow[]>();
  regionRowsByOrgCompanyMonth = new Map<string, RegionMonthlyRow[]>();
  readonly savedForecasts = new Map<string, DocumentData>();

  private key(organizationId: string, companyId: string, monthKey: string): string {
    return `${organizationId}::${companyId}::${monthKey}`;
  }

  setProductRows(
    organizationId: string,
    companyId: string,
    monthKey: string,
    rows: ProductMonthlyRow[],
  ): void {
    this.productRowsByOrgCompanyMonth.set(
      this.key(organizationId, companyId, monthKey),
      rows,
    );
  }

  setRegionRows(
    organizationId: string,
    companyId: string,
    monthKey: string,
    rows: RegionMonthlyRow[],
  ): void {
    this.regionRowsByOrgCompanyMonth.set(
      this.key(organizationId, companyId, monthKey),
      rows,
    );
  }

  async listActiveOrganizationIds(): Promise<ReadonlyArray<string>> {
    return this.organizationIds;
  }

  async listActiveCompanyIds(organizationId: string): Promise<ReadonlyArray<string>> {
    return this.companyIdsByOrganization.get(organizationId) ?? [];
  }

  async loadProductMonthlyRows(
    organizationId: string,
    companyId: string,
    monthKey: string,
  ): Promise<ReadonlyArray<ProductMonthlyRow>> {
    return this.productRowsByOrgCompanyMonth.get(this.key(organizationId, companyId, monthKey)) ?? [];
  }

  async loadRegionMonthlyRows(
    organizationId: string,
    companyId: string,
    monthKey: string,
  ): Promise<ReadonlyArray<RegionMonthlyRow>> {
    return this.regionRowsByOrgCompanyMonth.get(this.key(organizationId, companyId, monthKey)) ?? [];
  }

  async saveForecast(
    organizationId: string,
    documentId: string,
    data: DocumentData,
  ): Promise<void> {
    this.savedForecasts.set(`${organizationId}/${documentId}`, data);
  }
}

/** Seeds a product's `productMonthlyAggregates` rows for every month in
 * [MONTH_KEYS] with a steadily increasing quantity (`baseQuantity + index`),
 * so it always has full, sufficient history. */
function seedTrendingProduct(
  persistence: InMemoryDemandForecastPersistence,
  organizationId: string,
  companyId: string,
  productId: string,
  productName: string,
  collectionId: string,
  collectionName: string,
  baseQuantity: number,
): void {
  MONTH_KEYS.forEach((monthKey, index) => {
    persistence.setProductRows(organizationId, companyId, monthKey, [
      ...(persistence.productRowsByOrgCompanyMonth.get(
        `${organizationId}::${companyId}::${monthKey}`,
      ) ?? []),
      {
        productId,
        itemQuantity: baseQuantity + index,
        productName,
        collectionId,
        collectionName,
      },
    ]);
  });
}

describe('calculateDemandForecastsForCompany', () => {
  it('generates a forecast for a product with a full trending history', async () => {
    const persistence = new InMemoryDemandForecastPersistence();
    seedTrendingProduct(
      persistence,
      'org-1',
      'company-1',
      'product-1',
      'Camisa Polo',
      'collection-1',
      'Verão 2026',
      10,
    );

    const outcome = await calculateDemandForecastsForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      anchorMonthKey: ANCHOR_MONTH_KEY,
      persistence,
    });

    expect(outcome.generatedCount).toBeGreaterThan(0);
    const saved = persistence.savedForecasts.get(
      `org-1/company-1_product_product-1_${ANCHOR_MONTH_KEY}`,
    );
    expect(saved).toBeDefined();
    expect(saved?.status).toBe('forecast');
    expect(saved?.scopeLabel).toBe('Camisa Polo');
    expect(Array.isArray(saved?.forecastPeriods)).toBe(true);
    expect((saved?.forecastPeriods as unknown[]).length).toBeGreaterThan(0);
  });

  it('also forecasts the collection the product belongs to, aggregating quantities', async () => {
    const persistence = new InMemoryDemandForecastPersistence();
    seedTrendingProduct(
      persistence,
      'org-1',
      'company-1',
      'product-1',
      'Camisa Polo',
      'collection-1',
      'Verão 2026',
      10,
    );
    seedTrendingProduct(
      persistence,
      'org-1',
      'company-1',
      'product-2',
      'Bermuda',
      'collection-1',
      'Verão 2026',
      5,
    );

    await calculateDemandForecastsForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      anchorMonthKey: ANCHOR_MONTH_KEY,
      persistence,
    });

    const saved = persistence.savedForecasts.get(
      `org-1/company-1_collection_collection-1_${ANCHOR_MONTH_KEY}`,
    );
    expect(saved).toBeDefined();
    expect(saved?.scopeLabel).toBe('Verão 2026');
    expect(saved?.status).toBe('forecast');
  });

  it('marks a scope with fewer than 6 months of real activity as insufficientData, never fabricating a number', async () => {
    const persistence = new InMemoryDemandForecastPersistence();
    // Only 3 months (out of the 12-month window) have any row at all.
    const recentMonths = MONTH_KEYS.slice(-3);
    for (const monthKey of recentMonths) {
      persistence.setProductRows('org-1', 'company-1', monthKey, [
        {
          productId: 'product-new',
          itemQuantity: 4,
          productName: 'Produto novo',
          collectionId: null,
          collectionName: null,
        },
      ]);
    }

    await calculateDemandForecastsForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      anchorMonthKey: ANCHOR_MONTH_KEY,
      persistence,
    });

    const saved = persistence.savedForecasts.get(
      `org-1/company-1_product_product-new_${ANCHOR_MONTH_KEY}`,
    );
    expect(saved).toBeDefined();
    expect(saved?.status).toBe('insufficientData');
    expect(saved?.insufficientDataReason).toBe('notEnoughHistory');
    expect(saved?.forecastPeriods).toEqual([]);
  });

  it('forecasts by region, summing across cities of the same state', async () => {
    const persistence = new InMemoryDemandForecastPersistence();
    MONTH_KEYS.forEach((monthKey, index) => {
      persistence.setRegionRows('org-1', 'company-1', monthKey, [
        { region: 'SC', itemQuantity: 3 + index },
        { region: 'SP', itemQuantity: 20 + index },
      ]);
    });

    await calculateDemandForecastsForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      anchorMonthKey: ANCHOR_MONTH_KEY,
      persistence,
    });

    const savedSc = persistence.savedForecasts.get(
      `org-1/company-1_region_SC_${ANCHOR_MONTH_KEY}`,
    );
    const savedSp = persistence.savedForecasts.get(
      `org-1/company-1_region_SP_${ANCHOR_MONTH_KEY}`,
    );
    expect(savedSc?.status).toBe('forecast');
    expect(savedSp?.status).toBe('forecast');
  });

  it('is idempotent: re-running for the same anchor month overwrites the same document, never duplicating it', async () => {
    const persistence = new InMemoryDemandForecastPersistence();
    seedTrendingProduct(
      persistence,
      'org-1',
      'company-1',
      'product-1',
      'Camisa Polo',
      'collection-1',
      'Verão 2026',
      10,
    );

    await calculateDemandForecastsForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      anchorMonthKey: ANCHOR_MONTH_KEY,
      persistence,
    });
    const firstRunCount = persistence.savedForecasts.size;
    await calculateDemandForecastsForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      anchorMonthKey: ANCHOR_MONTH_KEY,
      persistence,
    });

    expect(persistence.savedForecasts.size).toBe(firstRunCount);
  });
});

describe('calculateDemandForecastsScheduledHandler', () => {
  it('never leaks one organization/company scope into another', async () => {
    const persistence = new InMemoryDemandForecastPersistence();
    persistence.organizationIds = ['org-a', 'org-b'];
    persistence.companyIdsByOrganization.set('org-a', ['company-a']);
    persistence.companyIdsByOrganization.set('org-b', ['company-b']);
    seedTrendingProduct(
      persistence,
      'org-a',
      'company-a',
      'shared-product-id',
      'Produto A',
      'collection-a',
      'Coleção A',
      50,
    );
    seedTrendingProduct(
      persistence,
      'org-b',
      'company-b',
      'shared-product-id',
      'Produto B',
      'collection-b',
      'Coleção B',
      1,
    );

    const now = new Date(`${ANCHOR_MONTH_KEY}-15T00:00:00.000Z`);
    // Anchor resolves to the previous month relative to `now`, so seed at
    // `now`'s next month to make ANCHOR_MONTH_KEY the resolved anchor.
    const nextMonth = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 15));
    await calculateDemandForecastsScheduledHandler(nextMonth, persistence);

    const savedA = persistence.savedForecasts.get(
      `org-a/company-a_product_shared-product-id_${ANCHOR_MONTH_KEY}`,
    );
    const savedB = persistence.savedForecasts.get(
      `org-b/company-b_product_shared-product-id_${ANCHOR_MONTH_KEY}`,
    );
    expect(savedA?.scopeLabel).toBe('Produto A');
    expect(savedB?.scopeLabel).toBe('Produto B');
    expect(savedA?.organizationId).toBe('org-a');
    expect(savedB?.organizationId).toBe('org-b');
  });

  it('continues processing remaining companies when one company fails', async () => {
    const persistence = new InMemoryDemandForecastPersistence();
    persistence.organizationIds = ['org-1'];
    persistence.companyIdsByOrganization.set('org-1', ['company-broken', 'company-ok']);
    seedTrendingProduct(
      persistence,
      'org-1',
      'company-ok',
      'product-1',
      'Produto OK',
      'collection-1',
      'Coleção',
      10,
    );
    const originalLoad = persistence.loadProductMonthlyRows.bind(persistence);
    persistence.loadProductMonthlyRows = async (organizationId, companyId, monthKey) => {
      if (companyId === 'company-broken') {
        throw new Error('boom');
      }
      return originalLoad(organizationId, companyId, monthKey);
    };

    const now = new Date(`${ANCHOR_MONTH_KEY}-15T00:00:00.000Z`);
    const nextMonth = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 15));
    await expect(
      calculateDemandForecastsScheduledHandler(nextMonth, persistence),
    ).resolves.toBeUndefined();

    const savedOk = persistence.savedForecasts.get(
      `org-1/company-ok_product_product-1_${ANCHOR_MONTH_KEY}`,
    );
    expect(savedOk?.status).toBe('forecast');
  });
});
