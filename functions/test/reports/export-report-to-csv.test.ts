import { HttpsError } from 'firebase-functions/v2/https';

import {
  assertCanExportReports,
  buildExportFileName,
  rowsToCsv,
} from '../../src/reports/export-report-to-csv';

describe('report CSV export RBAC (TASK-146)', () => {
  test('OWNER, ADMIN, SALES_MANAGER and FINANCE can export', () => {
    for (const role of ['OWNER', 'ADMIN', 'SALES_MANAGER', 'FINANCE']) {
      expect(() => assertCanExportReports(role)).not.toThrow();
    }
  });

  test('SALES_REP can preview a report but cannot export it', () => {
    expect(() => assertCanExportReports('SALES_REP')).toThrow(HttpsError);
  });

  test('SALES_ASSISTANT and unknown roles fail closed', () => {
    expect(() => assertCanExportReports('SALES_ASSISTANT')).toThrow(HttpsError);
    expect(() => assertCanExportReports('READ_ONLY')).toThrow(HttpsError);
    expect(() => assertCanExportReports('anything-else')).toThrow(HttpsError);
  });
});

describe('rowsToCsv (TASK-146)', () => {
  test('encodes a UTF-8 BOM and pt-BR delimiter/decimal so Excel opens it correctly', () => {
    const csv = rowsToCsv(
      ['cliente', 'faturamento'],
      [{ cliente: 'Joao & Cia', faturamento: 1234.5 }],
      'ptBr',
    );
    expect(csv.startsWith('﻿')).toBe(true);
    expect(csv).toContain('cliente;faturamento');
    expect(csv).toContain('Joao & Cia;1234,50');
  });

  test('uses comma delimiter and dot decimal for en-US locale', () => {
    const csv = rowsToCsv(['revenue'], [{ revenue: 99.9 }], 'enUs');
    expect(csv).toContain('99.90');
    expect(csv.split('\r\n')[0]).toBe('﻿revenue');
  });

  test('escapes fields containing the delimiter, quotes or line breaks', () => {
    const csv = rowsToCsv(
      ['cliente'],
      [{ cliente: 'Loja "Central"; Filial\nSul' }],
      'ptBr',
    );
    expect(csv).toContain('"Loja ""Central""; Filial\nSul"');
  });

  test('renders null/undefined values as an empty field and integers without decimals', () => {
    const csv = rowsToCsv(
      ['pedidos', 'observacao'],
      [{ pedidos: 12, observacao: null }],
      'ptBr',
    );
    const [, dataLine] = csv.split('\r\n');
    expect(dataLine).toBe('12;');
  });

  test('preserves accented pt-BR characters untouched', () => {
    const csv = rowsToCsv(['regiao'], [{ regiao: 'Região Sul — São Paulo' }], 'ptBr');
    expect(csv).toContain('Região Sul — São Paulo');
  });
});

describe('buildExportFileName (TASK-146)', () => {
  test('is deterministic for the same inputs and identifies report/organization/date', () => {
    const params = {
      dimensions: ['customer'],
      metrics: ['revenueNet'],
      organizationId: 'org-a',
      generatedAt: new Date(Date.UTC(2026, 8, 4, 12, 30, 0)),
    };
    const first = buildExportFileName(params);
    const second = buildExportFileName(params);
    expect(first).toBe(second);
    expect(first).toBe('customer-revenuenet_org-a_20260904-123000.csv');
  });

  test('produces a different, still-deterministic name for a different generation moment', () => {
    const base = {
      dimensions: ['customer'],
      metrics: ['revenueNet'],
      organizationId: 'org-a',
    };
    const first = buildExportFileName({ ...base, generatedAt: new Date(Date.UTC(2026, 8, 4, 12, 0, 0)) });
    const second = buildExportFileName({ ...base, generatedAt: new Date(Date.UTC(2026, 8, 4, 12, 0, 1)) });
    expect(first).not.toBe(second);
  });
});
