import { Timestamp, type DocumentData } from 'firebase-admin/firestore';

export type StockTurnoverScopeType =
  | 'product'
  | 'variant'
  | 'collection'
  | 'warehouse';

export type StockCoverageStatus = 'ready' | 'noRecentSales' | 'noStockBaseline';

export interface StockTurnoverDailyFact {
  id: string;
  organizationId: string;
  dateAt: Timestamp;
  productId: string;
  variantId: string | null;
  collectionId: string | null;
  warehouseId: string | null;
  openingStockQuantity: number;
  receivedQuantity: number;
  soldQuantity: number;
  closingStockQuantity: number;
}

export interface StockTurnoverMetricSnapshot {
  organizationId: string;
  scopeType: StockTurnoverScopeType;
  scopeId: string;
  periodStart: string;
  periodEnd: string;
  coveredDays: number;
  sellThroughRate: number;
  stockCoverageDays: number;
  turnoverRate: number;
  openingStockQuantity: number;
  receivedQuantity: number;
  soldQuantity: number;
  closingStockQuantity: number;
  averageStockQuantity: number;
  averageDailySalesQuantity: number;
  coverageStatus: StockCoverageStatus;
  generatedAt: Timestamp;
}

export function asStockTurnoverDailyFact(
  id: string,
  data: DocumentData | undefined,
): StockTurnoverDailyFact | null {
  if (!data) return null;
  if (
    typeof data.organizationId !== 'string' ||
    !(data.dateAt instanceof Timestamp) ||
    typeof data.productId !== 'string' ||
    (data.variantId != null && typeof data.variantId !== 'string') ||
    (data.collectionId != null && typeof data.collectionId !== 'string') ||
    (data.warehouseId != null && typeof data.warehouseId !== 'string') ||
    typeof data.openingStockQuantity !== 'number' ||
    typeof data.receivedQuantity !== 'number' ||
    typeof data.soldQuantity !== 'number' ||
    typeof data.closingStockQuantity !== 'number'
  ) {
    return null;
  }

  return {
    id,
    organizationId: data.organizationId,
    dateAt: data.dateAt,
    productId: data.productId,
    variantId: data.variantId ?? null,
    collectionId: data.collectionId ?? null,
    warehouseId: data.warehouseId ?? null,
    openingStockQuantity: data.openingStockQuantity,
    receivedQuantity: data.receivedQuantity,
    soldQuantity: data.soldQuantity,
    closingStockQuantity: data.closingStockQuantity,
  };
}

export function buildMetricSnapshot(params: {
  organizationId: string;
  scopeType: StockTurnoverScopeType;
  scopeId: string;
  periodStart: string;
  periodEnd: string;
  facts: ReadonlyArray<StockTurnoverDailyFact>;
  generatedAt?: Timestamp;
}): StockTurnoverMetricSnapshot {
  const sortedFacts = [...params.facts].sort(
    (left, right) => left.dateAt.toMillis() - right.dateAt.toMillis(),
  );
  const days = collapseFactsByDay(sortedFacts);
  const openingStockQuantity =
    days.length === 0 ? 0 : sumQuantities(days[0].facts, 'openingStockQuantity');
  const closingStockQuantity =
    days.length === 0
      ? 0
      : sumQuantities(days[days.length - 1].facts, 'closingStockQuantity');
  const receivedQuantity = sumQuantities(sortedFacts, 'receivedQuantity');
  const soldQuantity = sumQuantities(sortedFacts, 'soldQuantity');
  const coveredDays = days.length;
  const averageStockQuantity =
    coveredDays == 0
      ? 0
      : roundMetric(
          days.reduce((sum, day) => {
            const opening = sumQuantities(day.facts, 'openingStockQuantity');
            const closing = sumQuantities(day.facts, 'closingStockQuantity');
            return sum + (opening + closing) / 2;
          }, 0) / coveredDays,
        );
  const averageDailySalesQuantity =
    coveredDays == 0 ? 0 : roundMetric(soldQuantity / coveredDays);

  const sellThroughRate = roundMetric(
    ratioOrZero(soldQuantity, openingStockQuantity + receivedQuantity),
  );
  const turnoverRate = roundMetric(ratioOrZero(soldQuantity, averageStockQuantity));

  const coverageStatus =
    openingStockQuantity + receivedQuantity <= 0
      ? 'noStockBaseline'
      : averageDailySalesQuantity <= 0
        ? 'noRecentSales'
        : 'ready';

  const stockCoverageDays = roundMetric(
    averageDailySalesQuantity <= 0
      ? 0
      : closingStockQuantity / averageDailySalesQuantity,
  );

  return {
    organizationId: params.organizationId,
    scopeType: params.scopeType,
    scopeId: params.scopeId,
    periodStart: params.periodStart,
    periodEnd: params.periodEnd,
    coveredDays,
    sellThroughRate,
    stockCoverageDays,
    turnoverRate,
    openingStockQuantity,
    receivedQuantity,
    soldQuantity,
    closingStockQuantity,
    averageStockQuantity,
    averageDailySalesQuantity,
    coverageStatus,
    generatedAt: params.generatedAt ?? Timestamp.now(),
  };
}

export function buildMetricDocumentId(
  scopeType: StockTurnoverScopeType,
  scopeId: string,
  periodStart: string,
  periodEnd: string,
): string {
  return `${scopeType}_${scopeId}_${periodStart}_${periodEnd}`;
}

function collapseFactsByDay(
  facts: ReadonlyArray<StockTurnoverDailyFact>,
): Array<{ key: string; facts: StockTurnoverDailyFact[] }> {
  const grouped = new Map<string, StockTurnoverDailyFact[]>();
  for (const fact of facts) {
    const key = fact.dateAt.toDate().toISOString().slice(0, 10);
    const current = grouped.get(key) ?? [];
    current.push(fact);
    grouped.set(key, current);
  }
  return [...grouped.entries()]
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([key, items]) => ({ key, facts: items }));
}

function sumQuantities<T extends StockTurnoverDailyFact>(
  facts: ReadonlyArray<T>,
  field:
    | 'openingStockQuantity'
    | 'receivedQuantity'
    | 'soldQuantity'
    | 'closingStockQuantity',
): number {
  return facts.reduce((sum, fact) => sum + fact[field], 0);
}

function ratioOrZero(numerator: number, denominator: number): number {
  if (!Number.isFinite(numerator) || !Number.isFinite(denominator) || denominator <= 0) {
    return 0;
  }
  return numerator / denominator;
}

function roundMetric(value: number): number {
  return Math.round(value * 10000) / 10000;
}

