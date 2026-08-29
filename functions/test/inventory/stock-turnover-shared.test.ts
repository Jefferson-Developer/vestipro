import { Timestamp } from 'firebase-admin/firestore';

import {
  buildMetricSnapshot,
  type StockTurnoverDailyFact,
} from '../../src/inventory/stock-turnover-shared';

function fact(params: {
  id: string;
  dateAt: string;
  openingStockQuantity: number;
  receivedQuantity: number;
  soldQuantity: number;
  closingStockQuantity: number;
}): StockTurnoverDailyFact {
  return {
    id: params.id,
    organizationId: 'org-1',
    dateAt: Timestamp.fromDate(new Date(`${params.dateAt}T00:00:00.000Z`)),
    productId: 'product-1',
    variantId: 'variant-1',
    collectionId: 'collection-1',
    warehouseId: 'warehouse-1',
    openingStockQuantity: params.openingStockQuantity,
    receivedQuantity: params.receivedQuantity,
    soldQuantity: params.soldQuantity,
    closingStockQuantity: params.closingStockQuantity,
  };
}

describe('buildMetricSnapshot', () => {
  it('calculates sell-through, coverage and turnover for a valid period', () => {
    const snapshot = buildMetricSnapshot({
      organizationId: 'org-1',
      scopeType: 'product',
      scopeId: 'product-1',
      periodStart: '2026-08-01',
      periodEnd: '2026-08-02',
      facts: [
        fact({
          id: 'fact-1',
          dateAt: '2026-08-01',
          openingStockQuantity: 100,
          receivedQuantity: 20,
          soldQuantity: 30,
          closingStockQuantity: 90,
        }),
        fact({
          id: 'fact-2',
          dateAt: '2026-08-02',
          openingStockQuantity: 90,
          receivedQuantity: 10,
          soldQuantity: 20,
          closingStockQuantity: 80,
        }),
      ],
      generatedAt: Timestamp.fromDate(new Date('2026-08-03T00:00:00.000Z')),
    });

    expect(snapshot.sellThroughRate).toBeCloseTo(0.3846, 4);
    expect(snapshot.turnoverRate).toBeCloseTo(0.5556, 4);
    expect(snapshot.stockCoverageDays).toBeCloseTo(3.2, 4);
    expect(snapshot.coverageStatus).toBe('ready');
    expect(snapshot.coveredDays).toBe(2);
  });

  it('returns zeroed metrics without dividing by zero when there is no sale', () => {
    const snapshot = buildMetricSnapshot({
      organizationId: 'org-1',
      scopeType: 'variant',
      scopeId: 'variant-1',
      periodStart: '2026-08-01',
      periodEnd: '2026-08-01',
      facts: [
        fact({
          id: 'fact-1',
          dateAt: '2026-08-01',
          openingStockQuantity: 50,
          receivedQuantity: 0,
          soldQuantity: 0,
          closingStockQuantity: 50,
        }),
      ],
    });

    expect(snapshot.turnoverRate).toBe(0);
    expect(snapshot.stockCoverageDays).toBe(0);
    expect(snapshot.averageDailySalesQuantity).toBe(0);
    expect(snapshot.coverageStatus).toBe('noRecentSales');
  });

  it('handles periods without stock baseline explicitly', () => {
    const snapshot = buildMetricSnapshot({
      organizationId: 'org-1',
      scopeType: 'warehouse',
      scopeId: 'warehouse-1',
      periodStart: '2026-08-01',
      periodEnd: '2026-08-01',
      facts: [
        fact({
          id: 'fact-1',
          dateAt: '2026-08-01',
          openingStockQuantity: 0,
          receivedQuantity: 0,
          soldQuantity: 5,
          closingStockQuantity: 0,
        }),
      ],
    });

    expect(snapshot.sellThroughRate).toBe(0);
    expect(snapshot.turnoverRate).toBe(0);
    expect(snapshot.coverageStatus).toBe('noStockBaseline');
  });
});

