/**
 * Server-side, shared domain service for EPIC-27's demand forecasting model
 * (TASK-185). Every function here is pure (no Firestore, no
 * `firebase-functions`) — the same "shared calculation core" shape already
 * established by `../inventory/stock-turnover-shared.ts` (TASK-094) and
 * `../replenishment/replenishment-calculation-shared.ts` (TASK-184).
 *
 * ## Método estatístico usado (documentação exigida por `tasks.md`/TASK-185)
 *
 * O modelo é **Holt's linear trend method** (suavização exponencial dupla):
 * mantém um nível (`level`) e uma tendência (`trend`) atualizados a cada
 * período observado, e projeta `predicted(h) = level + h * trend` para `h`
 * períodos à frente. É a opção mais simples das três sugeridas pelo escopo
 * técnico da task ("média móvel ponderada, suavização exponencial ou
 * regressão sazonal") que ainda captura tendência (não só nível), sem exigir
 * detecção de sazonalidade (que precisaria de pelo menos 2-3 ciclos anuais
 * completos de histórico mensal — dado que este projeto está em sua primeira
 * safra de dados comerciais reais, essa profundidade de histórico não existe
 * ainda).
 *
 * O intervalo de confiança é derivado do erro de previsão "um passo à
 * frente" (resíduo) observado durante o próprio ajuste do modelo sobre o
 * histórico: `margin(h) = z * stdDev(resíduos) * sqrt(h)` — a margem cresce
 * com a raiz do horizonte, refletindo que uma previsão para 3 meses à frente
 * é sempre menos confiável que uma para o mês seguinte.
 *
 * ## Premissas e limitações (documentação exigida por `tasks.md`/TASK-185)
 *
 * - **Não modela sazonalidade explicitamente.** Uma série com padrão sazonal
 *   forte (ex.: pico de vendas em dezembro todo ano) ainda produz uma
 *   previsão (nunca lança exceção nem retorna `insufficientData` por causa
 *   disso), mas o número não captura a repetição do padrão — apenas nível e
 *   tendência recentes. Ver `demand-forecast-shared.test.ts`, caso "série
 *   sazonal", que documenta esse comportamento esperado.
 * - **Não considera eventos externos** (campanhas, feriados, ruptura de
 *   fornecedor, concorrência, clima) — projeta estritamente a partir do
 *   próprio histórico de vendas agregado.
 * - **Sensível a poucos dados**: por isso {@link MIN_OBSERVED_PERIODS} exige
 *   um mínimo de meses com atividade real registrada antes de sequer tentar
 *   ajustar o modelo — abaixo disso, o resultado é sempre
 *   `insufficientData`, nunca um número fabricado (`tasks.md`/TASK-185:
 *   "Modelo nunca gera número para combinação... com histórico
 *   insuficiente").
 * - **Nunca prevê demanda negativa**: tanto o valor previsto quanto o limite
 *   inferior do intervalo de confiança são sempre `>= 0`.
 * - A janela de histórico (`DEFAULT_LOOKBACK_MONTHS`, 12 meses) é fixa, não
 *   configurável por organização — mesma decisão já tomada por
 *   `DEFAULT_TURNOVER_LOOKBACK_DAYS` em `replenishment-calculation-shared.ts`
 *   (TASK-184): revisitar apenas se uma organização real precisar de uma
 *   janela materialmente diferente.
 */

/** One chronological point of a scope's (produto/coleção/região) monthly
 * demand history. [observed] is `false` for a month synthesized as a
 * zero-quantity gap (no commercial aggregate row existed for that month) —
 * kept distinct from a real, observed zero-sales month so the sufficiency
 * gate below never counts a padding artifact as real evidence. */
export interface MonthlyDemandPoint {
  /** `YYYY-MM`, same format as `AggregateSnapshotDoc.periodKey`
   * (`functions/src/aggregations/aggregation-shared.ts`). */
  periodKey: string;
  quantity: number;
  observed: boolean;
}

export type DemandForecastScopeType = 'product' | 'collection' | 'region';

export interface DemandForecastParameters {
  /** Exponential smoothing factor for the level component (`0 < alpha <= 1`).
   * Higher values react faster to the most recent month, at the cost of
   * more noise-sensitivity. */
  alpha: number;
  /** Exponential smoothing factor for the trend component (`0 < beta <= 1`). */
  beta: number;
  /** How many future months to project. */
  horizonMonths: number;
  /** Z-score multiplier for the confidence interval width (`1.645` ≈ 90%
   * two-sided confidence under a normal-residual assumption). */
  confidenceZ: number;
  /** Minimum number of *observed* (non-padded) months required before a
   * forecast is attempted at all. */
  minObservedPeriods: number;
}

export const DEFAULT_LOOKBACK_MONTHS = 12;

export const MIN_OBSERVED_PERIODS = 6;

export const DEFAULT_DEMAND_FORECAST_PARAMETERS: DemandForecastParameters = {
  alpha: 0.4,
  beta: 0.2,
  horizonMonths: 3,
  confidenceZ: 1.645,
  minObservedPeriods: MIN_OBSERVED_PERIODS,
};

/** Identifies the exact statistical method + tuning used to generate a
 * `DemandForecast` — persisted on every document
 * (`tasks.md`/TASK-185: "Toda previsão registra a versão do modelo usada,
 * permitindo auditar por que um número foi gerado em determinada data").
 * Bump whenever the formula, parameters or lookback window change in a way
 * that would make an old forecast not reproducible with the new code. */
export const DEMAND_FORECAST_MODEL = 'holtLinearTrend';
export const DEMAND_FORECAST_MODEL_VERSION = 'holt-linear-trend-v1';

export type DemandForecastInsufficientDataReason = 'noHistory' | 'notEnoughHistory';

export interface DemandForecastPeriodProjection {
  /** `YYYY-MM` of the projected month. */
  periodKey: string;
  predictedQuantity: number;
  lowerBound: number;
  upperBound: number;
}

export type DemandForecastCalculationResult =
  | {
      status: 'insufficientData';
      reason: DemandForecastInsufficientDataReason;
      observedPeriodsCount: number;
    }
  | {
      status: 'forecast';
      model: typeof DEMAND_FORECAST_MODEL;
      modelVersion: typeof DEMAND_FORECAST_MODEL_VERSION;
      observedPeriodsCount: number;
      residualStdDev: number;
      forecastPeriods: DemandForecastPeriodProjection[];
    };

/**
 * Fits a Holt linear-trend model over [history] (already sorted
 * chronologically, zero-padded for gap months — see module doc comment) and
 * projects `parameters.horizonMonths` months ahead, each with a confidence
 * interval. Returns `insufficientData` (never a fabricated number) when
 * fewer than `parameters.minObservedPeriods` months in [history] are
 * actually {@link MonthlyDemandPoint.observed}.
 */
export function calculateDemandForecast(
  history: readonly MonthlyDemandPoint[],
  parameters: DemandForecastParameters = DEFAULT_DEMAND_FORECAST_PARAMETERS,
): DemandForecastCalculationResult {
  const sorted = [...history].sort((left, right) =>
    left.periodKey.localeCompare(right.periodKey),
  );
  const observedPeriodsCount = sorted.filter((point) => point.observed).length;

  if (sorted.length === 0) {
    return { status: 'insufficientData', reason: 'noHistory', observedPeriodsCount: 0 };
  }
  if (observedPeriodsCount < parameters.minObservedPeriods) {
    return {
      status: 'insufficientData',
      reason: 'notEnoughHistory',
      observedPeriodsCount,
    };
  }

  const { level, trend, residuals } = fitHoltLinearTrend(sorted, parameters);
  const residualStdDev = standardDeviation(residuals);
  const lastPeriodKey = sorted[sorted.length - 1].periodKey;

  const forecastPeriods: DemandForecastPeriodProjection[] = [];
  for (let horizon = 1; horizon <= parameters.horizonMonths; horizon += 1) {
    const predictedQuantity = nonNegative(level + horizon * trend);
    const marginOfError =
      parameters.confidenceZ * residualStdDev * Math.sqrt(horizon);
    forecastPeriods.push({
      periodKey: addMonthsToMonthKey(lastPeriodKey, horizon),
      predictedQuantity: roundQuantity(predictedQuantity),
      lowerBound: roundQuantity(nonNegative(predictedQuantity - marginOfError)),
      upperBound: roundQuantity(predictedQuantity + marginOfError),
    });
  }

  return {
    status: 'forecast',
    model: DEMAND_FORECAST_MODEL,
    modelVersion: DEMAND_FORECAST_MODEL_VERSION,
    observedPeriodsCount,
    residualStdDev: roundQuantity(residualStdDev),
    forecastPeriods,
  };
}

function fitHoltLinearTrend(
  points: readonly MonthlyDemandPoint[],
  parameters: DemandForecastParameters,
): { level: number; trend: number; residuals: number[] } {
  let level = points[0].quantity;
  let trend = points.length > 1 ? points[1].quantity - points[0].quantity : 0;
  const residuals: number[] = [];

  for (let i = 1; i < points.length; i += 1) {
    const oneStepAheadForecast = level + trend;
    residuals.push(points[i].quantity - oneStepAheadForecast);

    const newLevel =
      parameters.alpha * points[i].quantity +
      (1 - parameters.alpha) * (level + trend);
    const newTrend =
      parameters.beta * (newLevel - level) + (1 - parameters.beta) * trend;
    level = newLevel;
    trend = newTrend;
  }

  return { level, trend, residuals };
}

function standardDeviation(values: readonly number[]): number {
  if (values.length === 0) return 0;
  const mean = values.reduce((sum, value) => sum + value, 0) / values.length;
  const variance =
    values.reduce((sum, value) => sum + (value - mean) ** 2, 0) / values.length;
  return Math.sqrt(variance);
}

function nonNegative(value: number): number {
  return Number.isFinite(value) && value > 0 ? value : 0;
}

function roundQuantity(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.round(value * 100) / 100;
}

/** Adds [delta] months (positive or negative) to a `YYYY-MM` key. */
export function addMonthsToMonthKey(monthKey: string, delta: number): string {
  const [yearStr, monthStr] = monthKey.split('-');
  const date = new Date(
    Date.UTC(Number(yearStr), Number(monthStr) - 1 + delta, 1),
  );
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, '0')}`;
}

/** Builds the [windowSize] chronological `YYYY-MM` keys ending at (and
 * including) [anchorMonthKey], ascending. */
export function buildMonthKeyWindow(
  anchorMonthKey: string,
  windowSize: number = DEFAULT_LOOKBACK_MONTHS,
): string[] {
  const keys: string[] = [];
  for (let i = windowSize - 1; i >= 0; i -= 1) {
    keys.push(addMonthsToMonthKey(anchorMonthKey, -i));
  }
  return keys;
}

/** Builds a zero-padded, chronologically ordered [MonthlyDemandPoint] series
 * for [monthKeys] out of a sparse map of observed quantities (only the
 * months a scope actually had commercial activity in). */
export function buildMonthlyDemandSeries(
  monthKeys: readonly string[],
  observedQuantityByMonthKey: ReadonlyMap<string, number>,
): MonthlyDemandPoint[] {
  return monthKeys.map((periodKey) => {
    const observedQuantity = observedQuantityByMonthKey.get(periodKey);
    return {
      periodKey,
      quantity: observedQuantity ?? 0,
      observed: observedQuantity != null,
    };
  });
}

/**
 * MAPE (Mean Absolute Percentage Error) of one forecasted period against its
 * now-known actual — the metric `tasks.md`/TASK-185's "Job de reavaliação
 * periódica do erro do modelo" is required to compute. `actualQuantity` of
 * `0` is treated as `1` in the denominator (documented edge case: a genuine
 * zero-demand month would otherwise make the percentage error undefined/
 * infinite) — consistent with the same "never divide by a real zero" caution
 * already applied elsewhere in this codebase
 * (`aggregation-shared.ts`'s `ratioOrZero`-style guards).
 */
export function absolutePercentageError(
  predictedQuantity: number,
  actualQuantity: number,
): number {
  const denominator = actualQuantity === 0 ? 1 : Math.abs(actualQuantity);
  return roundQuantity(
    (Math.abs(actualQuantity - predictedQuantity) / denominator) * 100,
  );
}
