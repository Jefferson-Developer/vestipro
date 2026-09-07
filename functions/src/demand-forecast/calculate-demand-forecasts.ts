import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import {
  DEFAULT_DEMAND_FORECAST_PARAMETERS,
  DEFAULT_LOOKBACK_MONTHS,
  addMonthsToMonthKey,
  buildMonthKeyWindow,
  buildMonthlyDemandSeries,
  calculateDemandForecast,
  type DemandForecastParameters,
  type DemandForecastScopeType,
} from './demand-forecast-shared';
import {
  createFirestoreDemandForecastDataSource,
  demandForecastDocumentId,
  type DemandForecastPersistence,
} from './demand-forecast-data-source';

export interface DemandForecastCalculationOutcome {
  generatedCount: number;
  insufficientDataCount: number;
}

interface ScopeSeries {
  scopeType: DemandForecastScopeType;
  scopeId: string;
  scopeLabel: string;
  quantityByMonth: Map<string, number>;
}

/**
 * Calculates (and idempotently persists) one `DemandForecast` document per
 * produto/coleção/região with any commercial activity in the
 * `DEFAULT_LOOKBACK_MONTHS`-month window ending at [anchorMonthKey], for one
 * company. Exported separately from the `onSchedule` trigger so both a real
 * monthly run and a unit test can call it directly with an explicit
 * [anchorMonthKey]/[persistence] — same shape as
 * `../replenishment/calculate-replenishment-suggestions.ts`'s
 * `calculateReplenishmentSuggestionsForOrganization` (TASK-184).
 *
 * Always a full overwrite keyed by
 * `{companyId}_{scopeType}_{scopeId}_{anchorMonthKey}` (idempotent
 * re-execution for the same anchor month never duplicates a document) —
 * there is no human-decision workflow to "freeze" here (unlike
 * `ReplenishmentSuggestion`'s `FROZEN_REPLENISHMENT_STATUSES`): a
 * `DemandForecast` is a read-only, fully server-computed projection, never
 * mutated by a client action. Re-running with corrected upstream aggregates
 * simply produces a better forecast for the same anchor month.
 */
export async function calculateDemandForecastsForCompany(params: {
  organizationId: string;
  companyId: string;
  anchorMonthKey: string;
  persistence: DemandForecastPersistence;
  parameters?: DemandForecastParameters;
  generatedAt?: Timestamp;
}): Promise<DemandForecastCalculationOutcome> {
  const parameters = params.parameters ?? DEFAULT_DEMAND_FORECAST_PARAMETERS;
  const generatedAt = params.generatedAt ?? Timestamp.now();
  const monthKeys = buildMonthKeyWindow(
    params.anchorMonthKey,
    DEFAULT_LOOKBACK_MONTHS,
  );

  const productQuantityByMonth = new Map<string, Map<string, number>>();
  const productNameById = new Map<string, string>();
  const collectionQuantityByMonth = new Map<string, Map<string, number>>();
  const collectionNameById = new Map<string, string>();
  const regionQuantityByMonth = new Map<string, Map<string, number>>();

  // One pass over `DEFAULT_LOOKBACK_MONTHS` months builds every
  // product/collection/region scope's history at once — see
  // `DemandForecastPersistence`'s own doc comment for why this reads a whole
  // month at a time instead of one query per scope.
  for (const monthKey of monthKeys) {
    const productRows = await params.persistence.loadProductMonthlyRows(
      params.organizationId,
      params.companyId,
      monthKey,
    );
    for (const row of productRows) {
      accumulate(productQuantityByMonth, row.productId, monthKey, row.itemQuantity);
      if (row.productName) productNameById.set(row.productId, row.productName);
      if (row.collectionId) {
        accumulate(
          collectionQuantityByMonth,
          row.collectionId,
          monthKey,
          row.itemQuantity,
        );
        if (row.collectionName) {
          collectionNameById.set(row.collectionId, row.collectionName);
        }
      }
    }

    const regionRows = await params.persistence.loadRegionMonthlyRows(
      params.organizationId,
      params.companyId,
      monthKey,
    );
    for (const row of regionRows) {
      accumulate(regionQuantityByMonth, row.region, monthKey, row.itemQuantity);
    }
  }

  const scopes: ScopeSeries[] = [
    ...[...productQuantityByMonth.entries()].map(
      ([scopeId, quantityByMonth]): ScopeSeries => ({
        scopeType: 'product',
        scopeId,
        scopeLabel: productNameById.get(scopeId) ?? scopeId,
        quantityByMonth,
      }),
    ),
    ...[...collectionQuantityByMonth.entries()].map(
      ([scopeId, quantityByMonth]): ScopeSeries => ({
        scopeType: 'collection',
        scopeId,
        scopeLabel: collectionNameById.get(scopeId) ?? scopeId,
        quantityByMonth,
      }),
    ),
    ...[...regionQuantityByMonth.entries()].map(
      ([scopeId, quantityByMonth]): ScopeSeries => ({
        scopeType: 'region',
        scopeId,
        scopeLabel: scopeId,
        quantityByMonth,
      }),
    ),
  ];

  let generatedCount = 0;
  let insufficientDataCount = 0;

  for (const scope of scopes) {
    const history = buildMonthlyDemandSeries(monthKeys, scope.quantityByMonth);
    const result = calculateDemandForecast(history, parameters);
    const documentId = demandForecastDocumentId(
      params.companyId,
      scope.scopeType,
      scope.scopeId,
      params.anchorMonthKey,
    );

    await params.persistence.saveForecast(params.organizationId, documentId, {
      organizationId: params.organizationId,
      companyId: params.companyId,
      scopeType: scope.scopeType,
      scopeId: scope.scopeId,
      scopeLabel: scope.scopeLabel,
      anchorMonthKey: params.anchorMonthKey,
      status: result.status,
      // No period ever needs evaluating for an `insufficientData` doc (it
      // has no `forecastPeriods` at all) — marking it `fullyEvaluated: true`
      // up front keeps `evaluate-demand-forecast-accuracy.ts`'s
      // `fullyEvaluated === false` query from ever rescanning it.
      fullyEvaluated: result.status !== 'forecast',
      insufficientDataReason:
        result.status === 'insufficientData' ? result.reason : null,
      observedPeriodsCount: result.observedPeriodsCount,
      model: result.status === 'forecast' ? result.model : null,
      modelVersion: result.status === 'forecast' ? result.modelVersion : null,
      residualStdDev: result.status === 'forecast' ? result.residualStdDev : null,
      history: history.map((point) => ({
        periodKey: point.periodKey,
        quantity: point.quantity,
        observed: point.observed,
      })),
      forecastPeriods:
        result.status === 'forecast'
          ? result.forecastPeriods.map((period) => ({
              periodKey: period.periodKey,
              predictedQuantity: period.predictedQuantity,
              lowerBound: period.lowerBound,
              upperBound: period.upperBound,
              actualQuantity: null,
              absolutePercentageError: null,
            }))
          : [],
      generatedAt,
      updatedAt: generatedAt,
      version: 1,
    });

    if (result.status === 'forecast') {
      generatedCount += 1;
    } else {
      insufficientDataCount += 1;
    }
  }

  return { generatedCount, insufficientDataCount };
}

/**
 * Loops every active organization/company, isolating failures per company
 * (same "one tenant's failure never aborts the batch" contract as
 * `../aggregations/recompute-monthly-aggregates.ts`/
 * `../replenishment/calculate-replenishment-suggestions.ts`).
 */
export async function calculateDemandForecastsScheduledHandler(
  now: Date = new Date(),
  persistence?: DemandForecastPersistence,
): Promise<void> {
  const adapter = persistence ?? createFirestoreDemandForecastDataSource();
  // The anchor is the last *fully completed* calendar month relative to
  // `now` — a month still in progress has an incomplete
  // `productMonthlyAggregates`/`regionMonthlyAggregates` snapshot for itself,
  // so it is never used as the most-recent history point nor forecasted
  // "from".
  const anchorMonthKey = addMonthsToMonthKey(formatMonthKey(now), -1);
  const organizationIds = await adapter.listActiveOrganizationIds();

  for (const organizationId of organizationIds) {
    const companyIds = await adapter.listActiveCompanyIds(organizationId);
    for (const companyId of companyIds) {
      try {
        const outcome = await calculateDemandForecastsForCompany({
          organizationId,
          companyId,
          anchorMonthKey,
          persistence: adapter,
        });
        logger.info('calculateDemandForecasts processed company', {
          organizationId,
          companyId,
          anchorMonthKey,
          generatedCount: outcome.generatedCount,
          insufficientDataCount: outcome.insufficientDataCount,
        });
      } catch (error) {
        logger.error('calculateDemandForecasts failed for company', {
          organizationId,
          companyId,
          anchorMonthKey,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    }
  }
}

function accumulate(
  byScope: Map<string, Map<string, number>>,
  scopeId: string,
  monthKey: string,
  quantity: number,
): void {
  const quantityByMonth = byScope.get(scopeId) ?? new Map<string, number>();
  quantityByMonth.set(monthKey, (quantityByMonth.get(monthKey) ?? 0) + quantity);
  byScope.set(scopeId, quantityByMonth);
}

function formatMonthKey(date: Date): string {
  return date.toISOString().slice(0, 7);
}

/**
 * Monthly demand-forecast calculation (TASK-185, EPIC-27) — runs a few days
 * into the new month (day 2, after `recomputeMonthlyAggregatesScheduled`'s
 * nightly run has had time to settle the previous month's aggregates) so
 * `anchorMonthKey`'s `productMonthlyAggregates`/`regionMonthlyAggregates` are
 * complete before this reads them.
 */
export const calculateDemandForecasts = onSchedule(
  {
    schedule: '0 5 2 * *',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',
  },
  async () => {
    await calculateDemandForecastsScheduledHandler();
  },
);
