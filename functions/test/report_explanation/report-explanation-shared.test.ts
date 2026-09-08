import {
  REPORT_EXPLANATION_MAX_ROWS,
  buildReportExplanationPayload,
  buildReportExplanationPrompt,
  computeDefinitionFingerprint,
  computePayloadHash,
  reportExplanationCacheKey,
  resolveReportExplanationReferences,
  validateGeneratedReportExplanation,
} from '../../src/report_explanation/report-explanation-shared';
import type { ReportExplanationPayload } from '../../src/report_explanation/report-explanation-types';
import type { ReportFieldConfig } from '../../src/reports/report-catalog';

const catalog: ReportFieldConfig[] = [
  { id: 'customer', label: 'Cliente', type: 'dimension', valueType: 'text' },
  { id: 'revenueNet', label: 'Faturamento líquido', type: 'metric', valueType: 'currency' },
  { id: 'orderCount', label: 'Pedidos', type: 'metric', valueType: 'number' },
  { id: 'averageDiscount', label: 'Desconto médio', type: 'metric', valueType: 'percentage' },
];

describe('buildReportExplanationPayload', () => {
  it('builds one data point per row/metric plus a total per metric', () => {
    const payload = buildReportExplanationPayload({
      organizationId: 'org-1',
      companyId: 'company-1',
      rows: [
        { customer: 'Loja A', revenueNet: 1000, orderCount: 4 },
        { customer: 'Loja B', revenueNet: 500, orderCount: 2 },
      ],
      dimensions: ['customer'],
      metrics: ['revenueNet', 'orderCount'],
      catalog,
      periodKey: '2026-09',
      comparisonPeriod: 'none',
    });

    expect(payload.periodKey).toBe('2026-09');
    expect(payload.periodLabel).toBe('setembro/2026');
    expect(payload.totalRowCount).toBe(2);
    expect(payload.omittedRowCount).toBe(0);
    expect(payload.rows).toHaveLength(2);
    // Highest revenueNet first (Loja A) since it's the primary metric.
    expect(payload.rows[0].dimensionLabel).toBe('Loja A');

    const totalRevenue = payload.dataPoints.find((point) => point.code === 'total_revenueNet');
    expect(totalRevenue?.numericValue).toBe(1500);
    expect(totalRevenue?.unit).toBe('BRL');
    const totalOrders = payload.dataPoints.find((point) => point.code === 'total_orderCount');
    expect(totalOrders?.numericValue).toBe(6);
  });

  it('caps individually-described rows at REPORT_EXPLANATION_MAX_ROWS, keeping the true total in omittedRowCount', () => {
    const rows = Array.from({ length: REPORT_EXPLANATION_MAX_ROWS + 5 }, (_, index) => ({
      customer: `Loja ${index}`,
      revenueNet: 100 - index,
    }));
    const payload = buildReportExplanationPayload({
      organizationId: 'org-1',
      companyId: 'company-1',
      rows,
      dimensions: ['customer'],
      metrics: ['revenueNet'],
      catalog,
      periodKey: '2026-09',
      comparisonPeriod: 'none',
    });

    expect(payload.totalRowCount).toBe(REPORT_EXPLANATION_MAX_ROWS + 5);
    expect(payload.rows).toHaveLength(REPORT_EXPLANATION_MAX_ROWS);
    expect(payload.omittedRowCount).toBe(5);
    // The total data point still sums every row, not just the described ones.
    const total = payload.dataPoints.find((point) => point.code === 'total_revenueNet');
    const expectedTotal = rows.reduce((sum, row) => sum + row.revenueNet, 0);
    expect(total?.numericValue).toBeCloseTo(expectedTotal);
  });

  it('includes a change-percent data point per row when the aggregation already computed one', () => {
    const payload = buildReportExplanationPayload({
      organizationId: 'org-1',
      companyId: 'company-1',
      rows: [
        { customer: 'Loja A', revenueNet: 150, revenueNetComparison: 100, revenueNetChangePercent: 50 },
      ],
      dimensions: ['customer'],
      metrics: ['revenueNet'],
      catalog,
      periodKey: '2026-09',
      comparisonPeriod: 'previousPeriod',
    });

    const changePoint = payload.dataPoints.find((point) => point.code === 'row_0_revenueNet_change_percent');
    expect(changePoint?.numericValue).toBe(50);
    expect(changePoint?.unit).toBe('percent');
  });

  it('never fabricates a change-percent data point when comparisonPeriod is none', () => {
    const payload = buildReportExplanationPayload({
      organizationId: 'org-1',
      companyId: 'company-1',
      rows: [{ customer: 'Loja A', revenueNet: 150 }],
      dimensions: ['customer'],
      metrics: ['revenueNet'],
      catalog,
      periodKey: '2026-09',
      comparisonPeriod: 'none',
    });

    expect(payload.dataPoints.some((point) => point.code.includes('change_percent'))).toBe(false);
  });

  it('handles an empty result set without throwing (dados insuficientes)', () => {
    const payload = buildReportExplanationPayload({
      organizationId: 'org-1',
      companyId: 'company-1',
      rows: [],
      dimensions: ['customer'],
      metrics: ['revenueNet'],
      catalog,
      periodKey: '2026-09',
      comparisonPeriod: 'none',
    });

    expect(payload.totalRowCount).toBe(0);
    expect(payload.rows).toEqual([]);
    const total = payload.dataPoints.find((point) => point.code === 'total_revenueNet');
    expect(total?.numericValue).toBe(0);
  });
});

describe('computePayloadHash', () => {
  const basePayload: ReportExplanationPayload = {
    organizationId: 'org-1',
    companyId: 'company-1',
    periodKey: '2026-09',
    periodLabel: 'setembro/2026',
    dimensionLabels: ['Cliente'],
    metricLabels: ['Faturamento líquido'],
    comparisonPeriod: 'none',
    totalRowCount: 1,
    omittedRowCount: 0,
    rows: [{ dimensionLabel: 'Loja A', dataPointCodes: ['row_0_revenueNet'] }],
    dataPoints: [
      { code: 'row_0_revenueNet', label: 'x', value: '100.00', numericValue: 100, unit: 'BRL' },
      { code: 'total_revenueNet', label: 'x', value: '100.00', numericValue: 100, unit: 'BRL' },
    ],
  };

  it('is stable regardless of dataPoints order', () => {
    const reordered: ReportExplanationPayload = { ...basePayload, dataPoints: [...basePayload.dataPoints].reverse() };
    expect(computePayloadHash(basePayload)).toBe(computePayloadHash(reordered));
  });

  it('changes when a numeric value changes', () => {
    const changed: ReportExplanationPayload = {
      ...basePayload,
      dataPoints: basePayload.dataPoints.map((point) =>
        point.code === 'total_revenueNet' ? { ...point, numericValue: 101, value: '101.00' } : point,
      ),
    };
    expect(computePayloadHash(basePayload)).not.toBe(computePayloadHash(changed));
  });
});

describe('validateGeneratedReportExplanation', () => {
  const payload: ReportExplanationPayload = {
    organizationId: 'org-1',
    companyId: 'company-1',
    periodKey: '2026-09',
    periodLabel: 'setembro/2026',
    dimensionLabels: ['Cliente'],
    metricLabels: ['Faturamento líquido'],
    comparisonPeriod: 'none',
    totalRowCount: 1,
    omittedRowCount: 0,
    rows: [{ dimensionLabel: 'Loja A', dataPointCodes: ['row_0_revenueNet'] }],
    dataPoints: [
      { code: 'row_0_revenueNet', label: 'Faturamento — Loja A', value: '1000.00', numericValue: 1000, unit: 'BRL' },
      { code: 'total_revenueNet', label: 'Total de faturamento', value: '1000.00', numericValue: 1000, unit: 'BRL' },
    ],
  };

  it('accepts an explanation whose numbers all exist in the payload and cites a reference', () => {
    const text = 'Em setembro/2026, o faturamento total foi de R$ 1000,00 [refs: total_revenueNet].';
    const outcome = validateGeneratedReportExplanation(text, payload);
    expect(outcome.ok).toBe(true);
  });

  it('rejects an explanation with no [refs: ...] citation', () => {
    const outcome = validateGeneratedReportExplanation('O faturamento foi de R$ 1000,00.', payload);
    expect(outcome.ok).toBe(false);
    if (!outcome.ok) expect(outcome.reason).toBe('missing_references');
  });

  it('rejects an explanation citing an unknown code', () => {
    const outcome = validateGeneratedReportExplanation(
      'Total de R$ 1000,00 [refs: total_revenueNet, codigo_inventado].',
      payload,
    );
    expect(outcome.ok).toBe(false);
    if (!outcome.ok) expect(outcome.reason).toBe('unknown_reference');
  });

  it('rejects an explanation containing a hallucinated number', () => {
    const outcome = validateGeneratedReportExplanation(
      'O faturamento total foi de R$ 999999,00 [refs: total_revenueNet].',
      payload,
    );
    expect(outcome.ok).toBe(false);
    if (!outcome.ok) expect(outcome.reason).toBe('hallucinated_number');
  });
});

describe('resolveReportExplanationReferences', () => {
  it('resolves cited codes to display-ready references, dropping unknown codes defensively', () => {
    const payload: ReportExplanationPayload = {
      organizationId: 'org-1',
      companyId: 'company-1',
      periodKey: '2026-09',
      periodLabel: 'setembro/2026',
      dimensionLabels: ['Cliente'],
      metricLabels: ['Faturamento líquido'],
      comparisonPeriod: 'none',
      totalRowCount: 1,
      omittedRowCount: 0,
      rows: [],
      dataPoints: [
        { code: 'total_revenueNet', label: 'Total de faturamento', value: '1000.00', numericValue: 1000, unit: 'BRL' },
      ],
    };
    const references = resolveReportExplanationReferences(payload, ['total_revenueNet', 'unknown_code']);
    expect(references).toEqual([
      { code: 'total_revenueNet', label: 'Total de faturamento', value: '1000.00', unit: 'BRL' },
    ]);
  });
});

describe('buildReportExplanationPrompt', () => {
  it('never includes a data point label without also including its code', () => {
    const payload: ReportExplanationPayload = {
      organizationId: 'org-1',
      companyId: 'company-1',
      periodKey: '2026-09',
      periodLabel: 'setembro/2026',
      dimensionLabels: ['Cliente'],
      metricLabels: ['Faturamento líquido'],
      comparisonPeriod: 'none',
      totalRowCount: 1,
      omittedRowCount: 0,
      rows: [],
      dataPoints: [
        { code: 'total_revenueNet', label: 'Total de faturamento', value: '1000.00', numericValue: 1000, unit: 'BRL' },
      ],
    };
    const { userPrompt, systemPrompt } = buildReportExplanationPrompt(payload);
    expect(userPrompt).toContain('total_revenueNet');
    expect(userPrompt).toContain('setembro/2026');
    expect(systemPrompt).toContain('período de referência');
  });
});

describe('reportExplanationCacheKey / computeDefinitionFingerprint', () => {
  it('is deterministic for the same inputs', () => {
    const fingerprintA = computeDefinitionFingerprint({
      dimensions: ['customer'],
      metrics: ['revenueNet'],
      filters: [{ fieldId: 'period', operator: 'equals', value: '2026-09' }],
      groupBy: [],
      sortBy: null,
      comparisonPeriod: 'none',
    });
    const fingerprintB = computeDefinitionFingerprint({
      dimensions: ['customer'],
      metrics: ['revenueNet'],
      filters: [{ fieldId: 'period', operator: 'equals', value: '2026-09' }],
      groupBy: [],
      sortBy: null,
      comparisonPeriod: 'none',
    });
    expect(fingerprintA).toBe(fingerprintB);

    const keyA = reportExplanationCacheKey({
      requesterUid: 'user-1',
      savedReportId: null,
      definitionFingerprint: fingerprintA,
    });
    const keyB = reportExplanationCacheKey({
      requesterUid: 'user-1',
      savedReportId: null,
      definitionFingerprint: fingerprintB,
    });
    expect(keyA).toBe(keyB);
  });

  it('scopes the cache key per requester, never shared across different users', () => {
    const fingerprint = computeDefinitionFingerprint({
      dimensions: ['customer'],
      metrics: ['revenueNet'],
      filters: [],
      groupBy: [],
      sortBy: null,
      comparisonPeriod: 'none',
    });
    const keyUserA = reportExplanationCacheKey({
      requesterUid: 'user-a',
      savedReportId: null,
      definitionFingerprint: fingerprint,
    });
    const keyUserB = reportExplanationCacheKey({
      requesterUid: 'user-b',
      savedReportId: null,
      definitionFingerprint: fingerprint,
    });
    expect(keyUserA).not.toBe(keyUserB);
  });

  it('prefers a stable savedReportId over the ad-hoc definition fingerprint', () => {
    const keyWithSavedReport = reportExplanationCacheKey({
      requesterUid: 'user-a',
      savedReportId: 'report-1',
      definitionFingerprint: 'irrelevant-because-saved-report-wins',
    });
    const keyWithSameSavedReportDifferentFingerprint = reportExplanationCacheKey({
      requesterUid: 'user-a',
      savedReportId: 'report-1',
      definitionFingerprint: 'another-irrelevant-value',
    });
    expect(keyWithSavedReport).toBe(keyWithSameSavedReportDifferentFingerprint);
  });
});
