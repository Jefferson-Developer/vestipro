import {
  Timestamp,
  getFirestore,
  type DocumentData,
  type Firestore,
} from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { absolutePercentageError, type DemandForecastScopeType } from './demand-forecast-shared';
import {
  createFirestoreDemandForecastDataSource,
  resolveActualQuantity,
  type DemandForecastPersistence,
} from './demand-forecast-data-source';

/**
 * `tasks.md`/TASK-185's "Job de reavaliação periódica do erro do modelo (ex.:
 * MAPE), comparando previsão passada vs. realizado, exposto internamente
 * para calibração". Runs monthly, a few days after
 * `calculate-demand-forecasts.ts`'s own monthly run (so last month's
 * `productMonthlyAggregates`/`regionMonthlyAggregates` are settled), and
 * fills in `actualQuantity`/`absolutePercentageError` on every
 * `DemandForecast.forecastPeriods` entry whose `periodKey` has now actually
 * happened — never touching a still-future period. This is read-only
 * calibration data (`demandForecastModelStats/{modelVersion}`): nothing here
 * changes what a `DemandForecast` predicted, only records how accurate it
 * turned out to be, for whoever tunes {@link DEFAULT_DEMAND_FORECAST_PARAMETERS}
 * next.
 */
export interface DemandForecastPeriodRecord {
  periodKey: string;
  predictedQuantity: number;
  lowerBound: number;
  upperBound: number;
  actualQuantity: number | null;
  absolutePercentageError: number | null;
}

export interface DemandForecastRecordForEvaluation {
  id: string;
  scopeType: DemandForecastScopeType;
  scopeId: string;
  modelVersion: string;
  forecastPeriods: DemandForecastPeriodRecord[];
}

export interface DemandForecastAccuracyPersistence extends DemandForecastPersistence {
  /** Every `DemandForecast` for [companyId] with `status === 'forecast'`
   * that still has at least one period awaiting evaluation
   * (`fullyEvaluated === false`, set by `calculate-demand-forecasts.ts` and
   * flipped to `true` here once every period has a known actual) — never
   * rescans a forecast whose entire horizon is already evaluated. */
  listForecastsToEvaluate(
    organizationId: string,
    companyId: string,
  ): Promise<ReadonlyArray<DemandForecastRecordForEvaluation>>;
  updateForecastPeriods(
    organizationId: string,
    documentId: string,
    forecastPeriods: ReadonlyArray<DemandForecastPeriodRecord>,
    fullyEvaluated: boolean,
  ): Promise<void>;
  upsertModelStats(
    organizationId: string,
    modelVersion: string,
    delta: { sampleCount: number; apeSum: number; evaluatedAt: Timestamp },
  ): Promise<void>;
}

export interface DemandForecastAccuracyOutcome {
  evaluatedPeriodsCount: number;
}

/**
 * Evaluates every forecastable period whose `periodKey <= asOfMonthKey` and
 * still lacks a known actual, for one company. Exported separately from the
 * `onSchedule` trigger so a unit test can call it directly with an
 * in-memory [persistence] fake — same shape as
 * `calculate-demand-forecasts.ts`'s own `calculateDemandForecastsForCompany`.
 */
export async function evaluateDemandForecastAccuracyForCompany(params: {
  organizationId: string;
  companyId: string;
  asOfMonthKey: string;
  persistence: DemandForecastAccuracyPersistence;
  now?: Timestamp;
}): Promise<DemandForecastAccuracyOutcome> {
  const now = params.now ?? Timestamp.now();
  const records = await params.persistence.listForecastsToEvaluate(
    params.organizationId,
    params.companyId,
  );

  let evaluatedPeriodsCount = 0;
  const apeListByModelVersion = new Map<string, number[]>();

  for (const record of records) {
    let changed = false;
    const updatedPeriods: DemandForecastPeriodRecord[] = [];

    for (const period of record.forecastPeriods) {
      if (period.actualQuantity != null || period.periodKey > params.asOfMonthKey) {
        updatedPeriods.push(period);
        continue;
      }

      const actualQuantity = await resolveActualQuantity({
        persistence: params.persistence,
        organizationId: params.organizationId,
        companyId: params.companyId,
        scopeType: record.scopeType,
        scopeId: record.scopeId,
        monthKey: period.periodKey,
      });
      const ape = absolutePercentageError(period.predictedQuantity, actualQuantity);
      updatedPeriods.push({
        ...period,
        actualQuantity,
        absolutePercentageError: ape,
      });
      changed = true;
      evaluatedPeriodsCount += 1;

      const apeList = apeListByModelVersion.get(record.modelVersion) ?? [];
      apeList.push(ape);
      apeListByModelVersion.set(record.modelVersion, apeList);
    }

    if (!changed) continue;
    const fullyEvaluated = updatedPeriods.every(
      (period) => period.actualQuantity != null,
    );
    await params.persistence.updateForecastPeriods(
      params.organizationId,
      record.id,
      updatedPeriods,
      fullyEvaluated,
    );
  }

  for (const [modelVersion, apeList] of apeListByModelVersion) {
    await params.persistence.upsertModelStats(params.organizationId, modelVersion, {
      sampleCount: apeList.length,
      apeSum: apeList.reduce((sum, value) => sum + value, 0),
      evaluatedAt: now,
    });
  }

  return { evaluatedPeriodsCount };
}

export async function evaluateDemandForecastAccuracyScheduledHandler(
  now: Date = new Date(),
  persistence?: DemandForecastAccuracyPersistence,
): Promise<void> {
  const adapter = persistence ?? createFirestoreDemandForecastAccuracyDataSource();
  const asOfMonthKey = addMonthsToMonthKey(formatMonthKey(now), -1);
  const organizationIds = await adapter.listActiveOrganizationIds();

  for (const organizationId of organizationIds) {
    const companyIds = await adapter.listActiveCompanyIds(organizationId);
    for (const companyId of companyIds) {
      try {
        const outcome = await evaluateDemandForecastAccuracyForCompany({
          organizationId,
          companyId,
          asOfMonthKey,
          persistence: adapter,
        });
        logger.info('evaluateDemandForecastAccuracy processed company', {
          organizationId,
          companyId,
          asOfMonthKey,
          evaluatedPeriodsCount: outcome.evaluatedPeriodsCount,
        });
      } catch (error) {
        logger.error('evaluateDemandForecastAccuracy failed for company', {
          organizationId,
          companyId,
          asOfMonthKey,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    }
  }
}

function formatMonthKey(date: Date): string {
  return date.toISOString().slice(0, 7);
}

function addMonthsToMonthKey(monthKey: string, delta: number): string {
  const [yearStr, monthStr] = monthKey.split('-');
  const date = new Date(
    Date.UTC(Number(yearStr), Number(monthStr) - 1 + delta, 1),
  );
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, '0')}`;
}

function createFirestoreDemandForecastAccuracyDataSource(
  db: Firestore = getFirestore(),
): DemandForecastAccuracyPersistence {
  const base = createFirestoreDemandForecastDataSource(db);

  return {
    ...base,

    async listForecastsToEvaluate(
      organizationId: string,
      companyId: string,
    ): Promise<ReadonlyArray<DemandForecastRecordForEvaluation>> {
      const snapshot = await db
        .collection('organizations')
        .doc(organizationId)
        .collection('demandForecasts')
        .where('companyId', '==', companyId)
        .where('status', '==', 'forecast')
        .where('fullyEvaluated', '==', false)
        .get();
      return snapshot.docs
        .map((doc) => asRecordForEvaluation(doc.id, doc.data()))
        .filter(
          (record): record is DemandForecastRecordForEvaluation => record != null,
        );
    },

    async updateForecastPeriods(
      organizationId: string,
      documentId: string,
      forecastPeriods: ReadonlyArray<DemandForecastPeriodRecord>,
      fullyEvaluated: boolean,
    ): Promise<void> {
      await db
        .collection('organizations')
        .doc(organizationId)
        .collection('demandForecasts')
        .doc(documentId)
        .update({
          forecastPeriods,
          fullyEvaluated,
          updatedAt: Timestamp.now(),
        });
    },

    async upsertModelStats(
      organizationId: string,
      modelVersion: string,
      delta: { sampleCount: number; apeSum: number; evaluatedAt: Timestamp },
    ): Promise<void> {
      const ref = db
        .collection('organizations')
        .doc(organizationId)
        .collection('demandForecastModelStats')
        .doc(modelVersion);
      await db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(ref);
        const previous = snapshot.exists ? snapshot.data() : undefined;
        const sampleCount = (previous?.sampleCount ?? 0) + delta.sampleCount;
        const apeSum = (previous?.apeSum ?? 0) + delta.apeSum;
        transaction.set(
          ref,
          {
            modelVersion,
            sampleCount,
            apeSum,
            averageMapePercent:
              sampleCount > 0 ? Math.round((apeSum / sampleCount) * 100) / 100 : 0,
            updatedAt: delta.evaluatedAt,
          },
          { merge: true },
        );
      });
    },
  };
}

function asRecordForEvaluation(
  id: string,
  data: DocumentData | undefined,
): DemandForecastRecordForEvaluation | null {
  if (!data) return null;
  const scopeType = data.scopeType;
  const scopeId = data.scopeId;
  const modelVersion = data.modelVersion;
  if (
    (scopeType !== 'product' && scopeType !== 'collection' && scopeType !== 'region') ||
    typeof scopeId !== 'string' ||
    typeof modelVersion !== 'string' ||
    !Array.isArray(data.forecastPeriods)
  ) {
    return null;
  }
  const forecastPeriods = (data.forecastPeriods as DocumentData[])
    .map((period) => asPeriodRecord(period))
    .filter((period): period is DemandForecastPeriodRecord => period != null);
  return { id, scopeType, scopeId, modelVersion, forecastPeriods };
}

function asPeriodRecord(period: DocumentData): DemandForecastPeriodRecord | null {
  if (
    typeof period.periodKey !== 'string' ||
    typeof period.predictedQuantity !== 'number' ||
    typeof period.lowerBound !== 'number' ||
    typeof period.upperBound !== 'number'
  ) {
    return null;
  }
  return {
    periodKey: period.periodKey,
    predictedQuantity: period.predictedQuantity,
    lowerBound: period.lowerBound,
    upperBound: period.upperBound,
    actualQuantity: typeof period.actualQuantity === 'number' ? period.actualQuantity : null,
    absolutePercentageError:
      typeof period.absolutePercentageError === 'number'
        ? period.absolutePercentageError
        : null,
  };
}

/**
 * Monthly evaluation run (TASK-185, EPIC-27) — the 5th of the month, three
 * days after `calculate-demand-forecasts.ts`'s own run, giving
 * `productMonthlyAggregates`/`regionMonthlyAggregates` time to settle for
 * the month(s) being evaluated.
 */
export const evaluateDemandForecastAccuracy = onSchedule(
  {
    schedule: '0 5 5 * *',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',
  },
  async () => {
    await evaluateDemandForecastAccuracyScheduledHandler();
  },
);
