import { comparisonMonth, mergeComparison } from '../../src/reports/execute-report-query';

describe('report query server calculations', () => {
  test('resolves previous month across year boundary and previous year', () => {
    expect(comparisonMonth('2026-01', 'previousPeriod')).toBe('2025-12');
    expect(comparisonMonth('2026-09', 'previousYear')).toBe('2025-09');
  });

  test('merges comparison values and percentage on the server', () => {
    const rows = mergeComparison(
      [{ seller: 'Ana', revenueNet: 150 }],
      [{ seller: 'Ana', revenueNet: 100 }],
      ['seller'],
      ['revenueNet'],
    );
    expect(rows).toEqual([{
      seller: 'Ana',
      revenueNet: 150,
      revenueNetComparison: 100,
      revenueNetChangePercent: 50,
    }]);
  });
});
