import { aggregateRows, comparisonMonth, mergeComparison } from '../../src/reports/execute-report-query';

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

  describe('aggregateRows currency handling (TASK-175)', () => {
    test('sums snapshots sharing one currency and exposes it per row', () => {
      const rows = aggregateRows(
        [
          { scopeId: 'seller-1', labels: { sellerName: 'Ana' }, currency: 'BRL', revenueNet: 100, revenueGross: 120, discountAmount: 20, orderCount: 1, itemQuantity: 3 },
          { scopeId: 'seller-1', labels: { sellerName: 'Ana' }, currency: 'BRL', revenueNet: 50, revenueGross: 60, discountAmount: 10, orderCount: 1, itemQuantity: 2 },
        ],
        ['seller'],
        ['revenueNet'],
      );
      expect(rows).toEqual([{ seller: 'Ana', currency: 'BRL', revenueNet: 150 }]);
    });

    test('never blends two currencies for the same dimension group into one total', () => {
      expect(() =>
        aggregateRows(
          [
            { scopeId: 'seller-1', labels: { sellerName: 'Ana' }, currency: 'BRL', revenueNet: 100, revenueGross: 120, discountAmount: 20, orderCount: 1, itemQuantity: 3 },
            { scopeId: 'seller-1', labels: { sellerName: 'Ana' }, currency: 'USD', revenueNet: 50, revenueGross: 60, discountAmount: 10, orderCount: 1, itemQuantity: 2 },
          ],
          ['seller'],
          ['revenueNet'],
        ),
      ).toThrow(/BRL e USD/);
    });

    test('defaults a snapshot missing currency to BRL (pre-TASK-175 data)', () => {
      const rows = aggregateRows(
        [{ scopeId: 'seller-1', labels: { sellerName: 'Ana' }, revenueNet: 100, revenueGross: 120, discountAmount: 20, orderCount: 1, itemQuantity: 3 }],
        ['seller'],
        ['revenueNet'],
      );
      expect(rows).toEqual([{ seller: 'Ana', currency: 'BRL', revenueNet: 100 }]);
    });
  });
});
