import {
  DEFAULT_DEMAND_FORECAST_PARAMETERS,
  addMonthsToMonthKey,
  buildMonthKeyWindow,
  buildMonthlyDemandSeries,
  calculateDemandForecast,
  absolutePercentageError,
  type MonthlyDemandPoint,
} from '../../src/demand-forecast/demand-forecast-shared';

function observedSeries(quantities: number[], startMonthKey = '2025-01'): MonthlyDemandPoint[] {
  const monthKeys = buildMonthKeyWindow(
    addMonthsToMonthKey(startMonthKey, quantities.length - 1),
    quantities.length,
  );
  return monthKeys.map((periodKey, index) => ({
    periodKey,
    quantity: quantities[index],
    observed: true,
  }));
}

describe('addMonthsToMonthKey', () => {
  it('rolls forward across a year boundary', () => {
    expect(addMonthsToMonthKey('2025-11', 3)).toBe('2026-02');
  });

  it('rolls backward across a year boundary', () => {
    expect(addMonthsToMonthKey('2026-01', -2)).toBe('2025-11');
  });
});

describe('buildMonthKeyWindow', () => {
  it('builds an ascending, inclusive window ending at the anchor', () => {
    expect(buildMonthKeyWindow('2026-03', 4)).toEqual([
      '2025-12',
      '2026-01',
      '2026-02',
      '2026-03',
    ]);
  });
});

describe('buildMonthlyDemandSeries', () => {
  it('zero-pads gap months and marks them unobserved', () => {
    const monthKeys = buildMonthKeyWindow('2026-03', 3);
    const quantityByMonth = new Map<string, number>([['2026-01', 10], ['2026-03', 8]]);

    const series = buildMonthlyDemandSeries(monthKeys, quantityByMonth);

    expect(series).toEqual([
      { periodKey: '2026-01', quantity: 10, observed: true },
      { periodKey: '2026-02', quantity: 0, observed: false },
      { periodKey: '2026-03', quantity: 8, observed: true },
    ]);
  });
});

describe('calculateDemandForecast', () => {
  it('returns insufficientData with reason noHistory for an empty series', () => {
    const result = calculateDemandForecast([]);
    expect(result).toEqual({
      status: 'insufficientData',
      reason: 'noHistory',
      observedPeriodsCount: 0,
    });
  });

  it('returns insufficientData with reason notEnoughHistory below the minimum observed periods', () => {
    const history = observedSeries([10, 12, 11, 13]); // 4 observed points, below MIN_OBSERVED_PERIODS (6)
    const result = calculateDemandForecast(history);
    expect(result.status).toBe('insufficientData');
    if (result.status === 'insufficientData') {
      expect(result.reason).toBe('notEnoughHistory');
      expect(result.observedPeriodsCount).toBe(4);
    }
  });

  it('never counts zero-padded (unobserved) months toward the sufficiency gate', () => {
    const monthKeys = buildMonthKeyWindow('2026-06', 12);
    // Only 5 real months of activity scattered across a 12-month window —
    // still insufficient even though the zero-padded array itself has 12
    // entries.
    const quantityByMonth = new Map<string, number>([
      [monthKeys[0], 5],
      [monthKeys[2], 6],
      [monthKeys[4], 7],
      [monthKeys[6], 8],
      [monthKeys[8], 9],
    ]);
    const history = buildMonthlyDemandSeries(monthKeys, quantityByMonth);
    const result = calculateDemandForecast(history);
    expect(result.status).toBe('insufficientData');
    if (result.status === 'insufficientData') {
      expect(result.observedPeriodsCount).toBe(5);
    }
  });

  it('forecasts an upward trend with an increasing predicted quantity', () => {
    const history = observedSeries([10, 12, 14, 16, 18, 20, 22]);
    const result = calculateDemandForecast(history);

    expect(result.status).toBe('forecast');
    if (result.status !== 'forecast') return;
    expect(result.model).toBe('holtLinearTrend');
    expect(result.modelVersion).toBe('holt-linear-trend-v1');
    expect(result.observedPeriodsCount).toBe(7);
    expect(result.forecastPeriods).toHaveLength(
      DEFAULT_DEMAND_FORECAST_PARAMETERS.horizonMonths,
    );
    // Trend is clearly positive: each successive forecasted period should
    // predict at least as much as the previous one.
    for (let i = 1; i < result.forecastPeriods.length; i += 1) {
      expect(result.forecastPeriods[i].predictedQuantity).toBeGreaterThanOrEqual(
        result.forecastPeriods[i - 1].predictedQuantity,
      );
    }
    // Chronologically ordered, continuing right after the last history month.
    expect(result.forecastPeriods[0].periodKey).toBe(
      addMonthsToMonthKey(history[history.length - 1].periodKey, 1),
    );
  });

  it('still produces a bounded forecast for a seasonal (non-monotonic) series without crashing', () => {
    // Documented limitation: Holt linear trend does not model seasonality —
    // this test only asserts the algorithm degrades gracefully (finite,
    // non-negative, internally consistent bounds), never that it captures
    // the repeating pattern.
    const history = observedSeries([5, 20, 5, 20, 5, 20, 5, 20]);
    const result = calculateDemandForecast(history);

    expect(result.status).toBe('forecast');
    if (result.status !== 'forecast') return;
    for (const period of result.forecastPeriods) {
      expect(Number.isFinite(period.predictedQuantity)).toBe(true);
      expect(period.predictedQuantity).toBeGreaterThanOrEqual(0);
      expect(period.lowerBound).toBeGreaterThanOrEqual(0);
      expect(period.lowerBound).toBeLessThanOrEqual(period.predictedQuantity);
      expect(period.upperBound).toBeGreaterThanOrEqual(period.predictedQuantity);
    }
  });

  it('never predicts negative demand even for a sharply declining series', () => {
    const history = observedSeries([100, 60, 30, 10, 2, 0, 0]);
    const result = calculateDemandForecast(history);
    expect(result.status).toBe('forecast');
    if (result.status !== 'forecast') return;
    for (const period of result.forecastPeriods) {
      expect(period.predictedQuantity).toBeGreaterThanOrEqual(0);
      expect(period.lowerBound).toBeGreaterThanOrEqual(0);
    }
  });

  it('widens the confidence interval for a farther horizon than for the next period', () => {
    const history = observedSeries([10, 14, 9, 16, 8, 18, 11]);
    const result = calculateDemandForecast(history, {
      ...DEFAULT_DEMAND_FORECAST_PARAMETERS,
      horizonMonths: 3,
    });
    expect(result.status).toBe('forecast');
    if (result.status !== 'forecast') return;
    const widthAt = (index: number) =>
      result.forecastPeriods[index].upperBound - result.forecastPeriods[index].lowerBound;
    expect(widthAt(2)).toBeGreaterThan(widthAt(0));
  });

  it('produces a wider confidence interval for a noisier series than a stable one, at the same horizon', () => {
    const stable = observedSeries([10, 10, 10, 10, 10, 10]);
    const noisy = observedSeries([2, 18, 4, 16, 3, 17]);

    const stableResult = calculateDemandForecast(stable);
    const noisyResult = calculateDemandForecast(noisy);
    expect(stableResult.status).toBe('forecast');
    expect(noisyResult.status).toBe('forecast');
    if (stableResult.status !== 'forecast' || noisyResult.status !== 'forecast') return;

    const stableWidth =
      stableResult.forecastPeriods[0].upperBound - stableResult.forecastPeriods[0].lowerBound;
    const noisyWidth =
      noisyResult.forecastPeriods[0].upperBound - noisyResult.forecastPeriods[0].lowerBound;
    expect(noisyWidth).toBeGreaterThan(stableWidth);
  });
});

describe('absolutePercentageError', () => {
  it('computes a plain percentage error against a nonzero actual', () => {
    expect(absolutePercentageError(110, 100)).toBe(10);
    expect(absolutePercentageError(80, 100)).toBe(20);
  });

  it('treats a zero actual as a denominator of 1 instead of dividing by zero', () => {
    expect(absolutePercentageError(5, 0)).toBe(500);
    expect(absolutePercentageError(0, 0)).toBe(0);
  });
});
