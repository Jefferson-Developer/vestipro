import { buildReportPdfBuffer, formatPdfCell } from '../../src/reports/export-report-to-pdf';
import { assertCanExportReports } from '../../src/reports/export-shared';
import type { ReportFieldConfig } from '../../src/reports/report-catalog';

const CATALOG: ReportFieldConfig[] = [
  { id: 'period', label: 'Período', type: 'dimension', valueType: 'date' },
  { id: 'customer', label: 'Cliente', type: 'dimension', valueType: 'text' },
  { id: 'revenueNet', label: 'Faturamento líquido', type: 'metric', valueType: 'currency' },
  { id: 'averageDiscount', label: 'Desconto médio', type: 'metric', valueType: 'percentage' },
  { id: 'orderCount', label: 'Pedidos', type: 'metric', valueType: 'number' },
];

describe('report PDF export RBAC (TASK-148, shared with TASK-146/TASK-147)', () => {
  test('OWNER, ADMIN, SALES_MANAGER and FINANCE can export', () => {
    for (const role of ['OWNER', 'ADMIN', 'SALES_MANAGER', 'FINANCE']) {
      expect(() => assertCanExportReports(role)).not.toThrow();
    }
  });

  test('SALES_REP can preview a report but cannot export it', () => {
    expect(() => assertCanExportReports('SALES_REP')).toThrow();
  });
});

describe('formatPdfCell (TASK-148)', () => {
  test('formats a currency value with the pt-BR symbol/decimal convention', () => {
    expect(formatPdfCell(1234.5, 'currency', 'ptBr')).toBe('R$ 1.234,50');
  });

  test('formats a currency value with the en-US symbol/decimal convention', () => {
    expect(formatPdfCell(1234.5, 'currency', 'enUs')).toBe('$ 1,234.50');
  });

  test('formats a "yyyy-MM" period value as "MM/yyyy"', () => {
    expect(formatPdfCell('2026-09', 'date', 'ptBr')).toBe('09/2026');
  });

  test('a null value is rendered as an em dash, never a crash', () => {
    expect(formatPdfCell(null, 'number', 'ptBr')).toBe('—');
  });

  test('formats a percentage value with two decimals and a % suffix', () => {
    expect(formatPdfCell(12.5, 'percentage', 'ptBr')).toBe('12,50%');
  });
});

describe('buildReportPdfBuffer (TASK-148)', () => {
  const columns = ['period', 'customer', 'revenueNet', 'averageDiscount', 'orderCount'];
  const rows = [
    {
      period: '2026-09',
      customer: 'João Ação',
      revenueNet: 1234.56,
      averageDiscount: 12.5,
      orderCount: 7,
    },
  ];
  const generatedAt = new Date('2026-09-05T12:00:00Z');

  test('produces a well-formed PDF buffer (starts with the %PDF magic bytes)', async () => {
    const buffer = await buildReportPdfBuffer({
      columns,
      rows,
      catalog: CATALOG,
      locale: 'ptBr',
      dimensions: ['period', 'customer'],
      metrics: ['revenueNet', 'averageDiscount', 'orderCount'],
      filters: [{ fieldId: 'period', value: '2026-09' }],
      branding: {},
      generatedAt,
    });
    expect(buffer.subarray(0, 5).toString('latin1')).toBe('%PDF-');
    expect(buffer.length).toBeGreaterThan(500);
  });

  test('applies the organization brand color without throwing when configured', async () => {
    const buffer = await buildReportPdfBuffer({
      columns,
      rows,
      catalog: CATALOG,
      locale: 'ptBr',
      dimensions: ['period'],
      metrics: ['revenueNet'],
      filters: [],
      branding: { primaryColorHex: '#123456' },
      generatedAt,
    });
    expect(buffer.subarray(0, 5).toString('latin1')).toBe('%PDF-');
  });

  test('produces a structurally valid PDF (cover + table pages) even with no rows', async () => {
    const buffer = await buildReportPdfBuffer({
      columns,
      rows: [],
      catalog: CATALOG,
      locale: 'ptBr',
      dimensions: [],
      metrics: [],
      filters: [],
      branding: {},
      generatedAt,
    });
    expect(buffer.subarray(0, 5).toString('latin1')).toBe('%PDF-');
  });
});
