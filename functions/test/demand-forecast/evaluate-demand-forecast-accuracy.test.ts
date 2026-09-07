import { Timestamp } from 'firebase-admin/firestore';

import {
  evaluateDemandForecastAccuracyForCompany,
  type DemandForecastAccuracyPersistence,
  type DemandForecastRecordForEvaluation,
} from '../../src/demand-forecast/evaluate-demand-forecast-accuracy';
import type {
  ProductMonthlyRow,
  RegionMonthlyRow,
} from '../../src/demand-forecast/demand-forecast-data-source';

class InMemoryAccuracyPersistence implements DemandForecastAccuracyPersistence {
  organizationIds: string[] = [];
  companyIdsByOrganization = new Map<string, string[]>();
  productRowsByMonth = new Map<string, ProductMonthlyRow[]>();
  regionRowsByMonth = new Map<string, RegionMonthlyRow[]>();
  records: DemandForecastRecordForEvaluation[] = [];
  readonly updatedPeriodsByDocumentId = new Map<
    string,
    { forecastPeriods: unknown[]; fullyEvaluated: boolean }
  >();
  readonly modelStats = new Map<
    string,
    { sampleCount: number; apeSum: number }
  >();

  private key(companyId: string, monthKey: string): string {
    return `${companyId}::${monthKey}`;
  }

  setProductRows(companyId: string, monthKey: string, rows: ProductMonthlyRow[]): void {
    this.productRowsByMonth.set(this.key(companyId, monthKey), rows);
  }

  setRegionRows(companyId: string, monthKey: string, rows: RegionMonthlyRow[]): void {
    this.regionRowsByMonth.set(this.key(companyId, monthKey), rows);
  }

  async listActiveOrganizationIds(): Promise<ReadonlyArray<string>> {
    return this.organizationIds;
  }

  async listActiveCompanyIds(organizationId: string): Promise<ReadonlyArray<string>> {
    return this.companyIdsByOrganization.get(organizationId) ?? [];
  }

  async loadProductMonthlyRows(
    _organizationId: string,
    companyId: string,
    monthKey: string,
  ): Promise<ReadonlyArray<ProductMonthlyRow>> {
    return this.productRowsByMonth.get(this.key(companyId, monthKey)) ?? [];
  }

  async loadRegionMonthlyRows(
    _organizationId: string,
    companyId: string,
    monthKey: string,
  ): Promise<ReadonlyArray<RegionMonthlyRow>> {
    return this.regionRowsByMonth.get(this.key(companyId, monthKey)) ?? [];
  }

  async saveForecast(): Promise<void> {
    throw new Error('not used by the evaluation job');
  }

  async listForecastsToEvaluate(): Promise<ReadonlyArray<DemandForecastRecordForEvaluation>> {
    return this.records;
  }

  async updateForecastPeriods(
    _organizationId: string,
    documentId: string,
    forecastPeriods: readonly unknown[],
    fullyEvaluated: boolean,
  ): Promise<void> {
    this.updatedPeriodsByDocumentId.set(documentId, {
      forecastPeriods: [...forecastPeriods],
      fullyEvaluated,
    });
  }

  async upsertModelStats(
    _organizationId: string,
    modelVersion: string,
    delta: { sampleCount: number; apeSum: number; evaluatedAt: Timestamp },
  ): Promise<void> {
    const previous = this.modelStats.get(modelVersion) ?? { sampleCount: 0, apeSum: 0 };
    this.modelStats.set(modelVersion, {
      sampleCount: previous.sampleCount + delta.sampleCount,
      apeSum: previous.apeSum + delta.apeSum,
    });
  }
}

describe('evaluateDemandForecastAccuracyForCompany', () => {
  it('fills actualQuantity/absolutePercentageError for a matured period and marks fullyEvaluated', async () => {
    const persistence = new InMemoryAccuracyPersistence();
    persistence.setProductRows('company-1', '2026-01', [
      {
        productId: 'product-1',
        itemQuantity: 90,
        productName: 'Camisa Polo',
        collectionId: null,
        collectionName: null,
      },
    ]);
    persistence.records = [
      {
        id: 'company-1_product_product-1_2025-12',
        scopeType: 'product',
        scopeId: 'product-1',
        modelVersion: 'holt-linear-trend-v1',
        forecastPeriods: [
          {
            periodKey: '2026-01',
            predictedQuantity: 100,
            lowerBound: 80,
            upperBound: 120,
            actualQuantity: null,
            absolutePercentageError: null,
          },
        ],
      },
    ];

    const outcome = await evaluateDemandForecastAccuracyForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      asOfMonthKey: '2026-01',
      persistence,
    });

    expect(outcome.evaluatedPeriodsCount).toBe(1);
    const updated = persistence.updatedPeriodsByDocumentId.get(
      'company-1_product_product-1_2025-12',
    );
    expect(updated?.fullyEvaluated).toBe(true);
    const period = updated?.forecastPeriods[0] as {
      actualQuantity: number;
      absolutePercentageError: number;
    };
    expect(period.actualQuantity).toBe(90);
    // |90 - 100| / 90 * 100 = 11.11...
    expect(period.absolutePercentageError).toBeCloseTo(11.11, 2);
  });

  it('treats a scope with no matching aggregate row as zero actual demand, never as unknown', async () => {
    const persistence = new InMemoryAccuracyPersistence();
    // No rows seeded for '2026-01' at all.
    persistence.records = [
      {
        id: 'company-1_product_product-1_2025-12',
        scopeType: 'product',
        scopeId: 'product-1',
        modelVersion: 'holt-linear-trend-v1',
        forecastPeriods: [
          {
            periodKey: '2026-01',
            predictedQuantity: 20,
            lowerBound: 10,
            upperBound: 30,
            actualQuantity: null,
            absolutePercentageError: null,
          },
        ],
      },
    ];

    await evaluateDemandForecastAccuracyForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      asOfMonthKey: '2026-01',
      persistence,
    });

    const updated = persistence.updatedPeriodsByDocumentId.get(
      'company-1_product_product-1_2025-12',
    );
    const period = updated?.forecastPeriods[0] as { actualQuantity: number };
    expect(period.actualQuantity).toBe(0);
  });

  it('never evaluates a period whose periodKey is still in the future relative to asOfMonthKey', async () => {
    const persistence = new InMemoryAccuracyPersistence();
    persistence.records = [
      {
        id: 'company-1_product_product-1_2025-12',
        scopeType: 'product',
        scopeId: 'product-1',
        modelVersion: 'holt-linear-trend-v1',
        forecastPeriods: [
          {
            periodKey: '2026-02',
            predictedQuantity: 20,
            lowerBound: 10,
            upperBound: 30,
            actualQuantity: null,
            absolutePercentageError: null,
          },
        ],
      },
    ];

    const outcome = await evaluateDemandForecastAccuracyForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      asOfMonthKey: '2026-01',
      persistence,
    });

    expect(outcome.evaluatedPeriodsCount).toBe(0);
    expect(persistence.updatedPeriodsByDocumentId.has('company-1_product_product-1_2025-12')).toBe(
      false,
    );
  });

  it('aggregates sampleCount/apeSum per modelVersion across every evaluated period', async () => {
    const persistence = new InMemoryAccuracyPersistence();
    persistence.setProductRows('company-1', '2026-01', [
      {
        productId: 'product-1',
        itemQuantity: 100,
        productName: 'Camisa Polo',
        collectionId: null,
        collectionName: null,
      },
      {
        productId: 'product-2',
        itemQuantity: 50,
        productName: 'Bermuda',
        collectionId: null,
        collectionName: null,
      },
    ]);
    persistence.records = [
      {
        id: 'doc-1',
        scopeType: 'product',
        scopeId: 'product-1',
        modelVersion: 'holt-linear-trend-v1',
        forecastPeriods: [
          {
            periodKey: '2026-01',
            predictedQuantity: 100,
            lowerBound: 80,
            upperBound: 120,
            actualQuantity: null,
            absolutePercentageError: null,
          },
        ],
      },
      {
        id: 'doc-2',
        scopeType: 'product',
        scopeId: 'product-2',
        modelVersion: 'holt-linear-trend-v1',
        forecastPeriods: [
          {
            periodKey: '2026-01',
            predictedQuantity: 40,
            lowerBound: 20,
            upperBound: 60,
            actualQuantity: null,
            absolutePercentageError: null,
          },
        ],
      },
    ];

    await evaluateDemandForecastAccuracyForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      asOfMonthKey: '2026-01',
      persistence,
    });

    const stats = persistence.modelStats.get('holt-linear-trend-v1');
    expect(stats?.sampleCount).toBe(2);
    // product-1: |100-100|/100*100 = 0 ; product-2: |40-50|/50*100 = 20
    expect(stats?.apeSum).toBeCloseTo(20, 5);
  });

  it('sums collection-scope actuals across every product sharing the collection', async () => {
    const persistence = new InMemoryAccuracyPersistence();
    persistence.setProductRows('company-1', '2026-01', [
      {
        productId: 'product-1',
        itemQuantity: 30,
        productName: 'Camisa Polo',
        collectionId: 'collection-1',
        collectionName: 'Verão',
      },
      {
        productId: 'product-2',
        itemQuantity: 20,
        productName: 'Bermuda',
        collectionId: 'collection-1',
        collectionName: 'Verão',
      },
    ]);
    persistence.records = [
      {
        id: 'doc-collection',
        scopeType: 'collection',
        scopeId: 'collection-1',
        modelVersion: 'holt-linear-trend-v1',
        forecastPeriods: [
          {
            periodKey: '2026-01',
            predictedQuantity: 45,
            lowerBound: 30,
            upperBound: 60,
            actualQuantity: null,
            absolutePercentageError: null,
          },
        ],
      },
    ];

    await evaluateDemandForecastAccuracyForCompany({
      organizationId: 'org-1',
      companyId: 'company-1',
      asOfMonthKey: '2026-01',
      persistence,
    });

    const updated = persistence.updatedPeriodsByDocumentId.get('doc-collection');
    const period = updated?.forecastPeriods[0] as { actualQuantity: number };
    expect(period.actualQuantity).toBe(50);
  });
});
