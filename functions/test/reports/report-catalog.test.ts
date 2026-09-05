import { HttpsError } from 'firebase-functions/v2/https';
import { catalogForRole } from '../../src/reports/report-catalog';

describe('report catalog RBAC', () => {
  test('SALES_REP only receives seller dimension and no financial metric', () => {
    const available = catalogForRole('SALES_REP').filter((field) => field.isAvailable !== false);
    expect(available.filter((field) => field.type === 'dimension').map((field) => field.id)).toEqual(['seller']);
    expect(available.some((field) => field.id === 'revenueNet')).toBe(false);
  });

  test('FINANCE receives sensitive metrics', () => {
    const revenue = catalogForRole('FINANCE').find((field) => field.id === 'revenueNet');
    expect(revenue?.isAvailable).toBe(true);
  });

  test('unknown role fails closed', () => {
    expect(() => catalogForRole('READ_ONLY')).toThrow(HttpsError);
  });
});
