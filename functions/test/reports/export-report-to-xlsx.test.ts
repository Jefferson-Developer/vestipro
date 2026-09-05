import ExcelJS from 'exceljs';

import {
  resolveColumnValueType,
  rowsToXlsxBuffer,
} from '../../src/reports/export-report-to-xlsx';
import { assertCanExportReports } from '../../src/reports/export-shared';
import type { ReportFieldConfig } from '../../src/reports/report-catalog';

const CATALOG: ReportFieldConfig[] = [
  { id: 'period', label: 'Período', type: 'dimension', valueType: 'date' },
  { id: 'customer', label: 'Cliente', type: 'dimension', valueType: 'text' },
  { id: 'revenueNet', label: 'Faturamento líquido', type: 'metric', valueType: 'currency' },
  { id: 'averageDiscount', label: 'Desconto médio', type: 'metric', valueType: 'percentage' },
  { id: 'orderCount', label: 'Pedidos', type: 'metric', valueType: 'number' },
];

describe('report XLSX export RBAC (TASK-147, shared with TASK-146)', () => {
  test('OWNER, ADMIN, SALES_MANAGER and FINANCE can export', () => {
    for (const role of ['OWNER', 'ADMIN', 'SALES_MANAGER', 'FINANCE']) {
      expect(() => assertCanExportReports(role)).not.toThrow();
    }
  });

  test('SALES_REP can preview a report but cannot export it', () => {
    expect(() => assertCanExportReports('SALES_REP')).toThrow();
  });
});

describe('resolveColumnValueType (TASK-147)', () => {
  test('resolves a direct catalog field id to its own valueType', () => {
    expect(resolveColumnValueType('period', CATALOG)).toBe('date');
    expect(resolveColumnValueType('customer', CATALOG)).toBe('text');
    expect(resolveColumnValueType('revenueNet', CATALOG)).toBe('currency');
    expect(resolveColumnValueType('orderCount', CATALOG)).toBe('number');
  });

  test('a "<metric>ChangePercent" comparison column is always a percentage', () => {
    expect(resolveColumnValueType('revenueNetChangePercent', CATALOG)).toBe('percentage');
  });

  test('a "<metric>Comparison" column mirrors its base metric\'s own valueType', () => {
    expect(resolveColumnValueType('revenueNetComparison', CATALOG)).toBe('currency');
    expect(resolveColumnValueType('orderCountComparison', CATALOG)).toBe('number');
  });

  test('falls back to number/text for an id the catalog never lists', () => {
    expect(resolveColumnValueType('somethingUnknownComparison', CATALOG)).toBe('number');
    expect(resolveColumnValueType('somethingUnknown', CATALOG)).toBe('text');
  });
});

describe('rowsToXlsxBuffer (TASK-147)', () => {
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

  test('writes every column with its real (non-text) cell type', async () => {
    const buffer = await rowsToXlsxBuffer(columns, rows, CATALOG, 'ptBr');
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(buffer as unknown as ExcelJS.Buffer);
    const sheet = workbook.worksheets[0];

    expect(sheet.getCell('A1').value).toBe('period');
    expect(sheet.getRow(1).getCell(1).font?.bold).toBe(true);

    const period = sheet.getCell('A2').value;
    expect(period).toBeInstanceOf(Date);
    expect((period as Date).getUTCFullYear()).toBe(2026);
    expect((period as Date).getUTCMonth()).toBe(8); // 0-based -> September

    expect(sheet.getCell('B2').value).toBe('João Ação');

    expect(sheet.getCell('C2').value).toBeCloseTo(1234.56, 2);

    // averageDiscount (12.5 "human" percent) is stored as the 0.125
    // fraction Excel's own `%` format expects.
    expect(sheet.getCell('D2').value).toBeCloseTo(0.125, 4);

    expect(sheet.getCell('E2').value).toBe(7);
  });

  test('produces a structurally valid workbook (header only) when there are no rows', async () => {
    const buffer = await rowsToXlsxBuffer(columns, [], CATALOG, 'ptBr');
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(buffer as unknown as ExcelJS.Buffer);
    const sheet = workbook.worksheets[0];
    expect(sheet.getCell('A1').value).toBe('period');
    expect(sheet.rowCount).toBe(1);
  });

  test('a null value is written as an empty cell, never a crash', async () => {
    const buffer = await rowsToXlsxBuffer(
      ['customer', 'revenueNet'],
      [{ customer: null, revenueNet: 10 }],
      CATALOG,
      'ptBr',
    );
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(buffer as unknown as ExcelJS.Buffer);
    const sheet = workbook.worksheets[0];
    expect(sheet.getCell('A2').value).toBe('');
  });

  test('applies a frozen header row and a native AutoFilter over the full data range', async () => {
    const buffer = await rowsToXlsxBuffer(columns, rows, CATALOG, 'ptBr');
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(buffer as unknown as ExcelJS.Buffer);
    const sheet = workbook.worksheets[0];
    expect(sheet.views).toEqual(
      expect.arrayContaining([expect.objectContaining({ state: 'frozen', ySplit: 1 })]),
    );
    // 5 columns (A..E), 1 header + 1 data row = 2 rows.
    expect(sheet.autoFilter).toBe('A1:E2');
  });
});
