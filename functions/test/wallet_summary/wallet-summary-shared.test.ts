import { HttpsError } from 'firebase-functions/v2/https';

import {
  assertCanAccessSellerWallet,
  buildWalletSummaryPayload,
  buildWalletSummaryPrompt,
  computePayloadHash,
  extractCitedDataPointCodes,
  formatPeriodLabel,
  parseFlexibleNumber,
  resolveWalletSummaryReferences,
  validateGeneratedSummary,
  walletSummaryDocId,
} from '../../src/wallet_summary/wallet-summary-shared';
import type { WalletSummaryPayload } from '../../src/wallet_summary/wallet-summary-types';

// ---------------------------------------------------------------------------
// Minimal fake Firestore — just enough chainable surface
// (`collection().doc().get()` and `collection().where().where().limit().get()`)
// for `buildWalletSummaryPayload`/`assertCanAccessSellerWallet` to run against
// fully in-memory, deterministic fixtures — no emulator required. Mirrors the
// same "fake the exact seam the code under test uses" approach as
// `../replenishment/calculate-replenishment-suggestions.test.ts`'s fake
// `ReplenishmentSuggestionPersistence`, just expressed against the native
// Firestore chain instead of a bespoke interface, since
// `buildWalletSummaryPayload` reads straight from `Firestore` (no repository
// seam of its own — it is itself the data-access layer for this feature).
// ---------------------------------------------------------------------------

interface FakeDoc {
  id: string;
  data: Record<string, unknown>;
}

function fakeSnapshot(doc: FakeDoc | undefined) {
  return {
    exists: doc != null,
    id: doc?.id,
    data: () => doc?.data,
  };
}

function fakeQuerySnapshot(docs: FakeDoc[]) {
  return {
    docs: docs.map((doc) => ({ id: doc.id, data: () => doc.data })),
  };
}

class FakeFirestore {
  constructor(
    private readonly docsByPath: Map<string, FakeDoc>,
    private readonly collectionsByPath: Map<string, FakeDoc[]>,
  ) {}

  collection(name: string) {
    return this.buildCollection([name]);
  }

  private buildCollection(pathSegments: string[]): any {
    const path = pathSegments.join('/');
    return {
      doc: (id: string) => this.buildDoc([...pathSegments, id]),
      where: (field: string, op: string, value: unknown) =>
        this.buildQuery(path, [{ field, op, value }]),
      limit: () => this.buildQuery(path, []),
      get: async () => fakeQuerySnapshot(this.collectionsByPath.get(path) ?? []),
    };
  }

  private buildDoc(pathSegments: string[]): any {
    const path = pathSegments.join('/');
    return {
      collection: (name: string) => this.buildCollection([...pathSegments, name]),
      get: async () => fakeSnapshot(this.docsByPath.get(path)),
    };
  }

  private buildQuery(collectionPath: string, filters: { field: string; op: string; value: unknown }[]): any {
    return {
      where: (field: string, op: string, value: unknown) =>
        this.buildQuery(collectionPath, [...filters, { field, op, value }]),
      limit: () => this.buildQuery(collectionPath, filters),
      get: async () => {
        const docs = (this.collectionsByPath.get(collectionPath) ?? []).filter((doc) =>
          filters.every((filter) => (doc.data as Record<string, unknown>)[filter.field] === filter.value),
        );
        return fakeQuerySnapshot(docs);
      },
    };
  }
}

function buildFakeDb(params: {
  docs?: Record<string, Record<string, unknown>>;
  collections?: Record<string, FakeDoc[]>;
}): any {
  const docsByPath = new Map<string, FakeDoc>();
  for (const [path, data] of Object.entries(params.docs ?? {})) {
    docsByPath.set(path, { id: path.split('/').pop()!, data });
  }
  const collectionsByPath = new Map<string, FakeDoc[]>();
  for (const [path, docs] of Object.entries(params.collections ?? {})) {
    collectionsByPath.set(path, docs);
  }
  return new FakeFirestore(docsByPath, collectionsByPath);
}

describe('formatPeriodLabel', () => {
  it('formats a YYYY-MM key as "month/year" in Portuguese', () => {
    expect(formatPeriodLabel('2026-09')).toBe('setembro/2026');
    expect(formatPeriodLabel('2026-01')).toBe('janeiro/2026');
  });
});

describe('walletSummaryDocId', () => {
  it('combines sellerId and periodKey deterministically', () => {
    expect(walletSummaryDocId('seller-1', '2026-09')).toBe('seller-1_2026-09');
  });
});

describe('buildWalletSummaryPayload', () => {
  const organizationId = 'org-1';
  const companyId = 'company-1';
  const sellerId = 'seller-1';
  const now = new Date('2026-09-15T12:00:00.000Z');

  it('builds revenue data points from the current and previous month aggregates', async () => {
    const db = buildFakeDb({
      docs: {
        'organizations/org-1/representativeMonthlyAggregates/company-1_seller-1_2026-09': {
          revenueNet: 12500.5,
          orderCount: 8,
        },
        'organizations/org-1/representativeMonthlyAggregates/company-1_seller-1_2026-08': {
          revenueNet: 9800,
          orderCount: 6,
        },
      },
    });

    const payload = await buildWalletSummaryPayload({
      db,
      organizationId,
      companyId,
      sellerId,
      sellerName: 'Ana Vendedora',
      now,
    });

    expect(payload.periodKey).toBe('2026-09');
    expect(payload.periodLabel).toBe('setembro/2026');
    expect(payload.revenuePreviousMonthDataPointCode).toBe('revenue_previous_month');
    const revenueCurrent = payload.dataPoints.find((point) => point.code === 'revenue_current_month');
    const revenuePrevious = payload.dataPoints.find((point) => point.code === 'revenue_previous_month');
    expect(revenueCurrent?.numericValue).toBe(12500.5);
    expect(revenuePrevious?.numericValue).toBe(9800);
  });

  it('never includes a previous-month data point when no aggregate exists for it', async () => {
    const db = buildFakeDb({
      docs: {
        'organizations/org-1/representativeMonthlyAggregates/company-1_seller-1_2026-09': {
          revenueNet: 1000,
          orderCount: 1,
        },
      },
    });

    const payload = await buildWalletSummaryPayload({
      db,
      organizationId,
      companyId,
      sellerId,
      sellerName: 'Ana Vendedora',
      now,
    });

    expect(payload.revenuePreviousMonthDataPointCode).toBeNull();
    expect(payload.dataPoints.some((point) => point.code === 'revenue_previous_month')).toBe(false);
  });

  it('scopes insights strictly to this seller, never leaking another seller/org', async () => {
    const db = buildFakeDb({
      docs: {
        'organizations/org-1/representativeMonthlyAggregates/company-1_seller-1_2026-09': {
          revenueNet: 1000,
          orderCount: 1,
        },
      },
      collections: {
        'organizations/org-1/insights': [
          {
            id: 'insight-own',
            data: {
              recipientUserId: 'seller-1',
              status: 'fresh',
              type: 'inactiveCustomer',
              title: 'Cliente inativo',
              description: 'Descricao',
              severity: 'high',
              estimatedImpact: { amount: 500 },
              evidence: [{ code: 'days_inactive', label: 'Dias inativo', value: '60', numericValue: 60 }],
            },
          },
          {
            id: 'insight-other-seller',
            data: {
              recipientUserId: 'seller-2',
              status: 'fresh',
              type: 'inactiveCustomer',
              title: 'Nao deve aparecer',
              description: 'x',
              severity: 'low',
              estimatedImpact: { amount: 1 },
              evidence: [{ code: 'x', label: 'x', value: '1', numericValue: 1 }],
            },
          },
        ],
      },
    });

    const payload = await buildWalletSummaryPayload({
      db,
      organizationId,
      companyId,
      sellerId,
      sellerName: 'Ana Vendedora',
      now,
    });

    expect(payload.insights).toHaveLength(1);
    expect(payload.insights[0].insightId).toBe('insight-own');
    expect(payload.dataPoints.some((point) => point.code.includes('insight-other-seller'))).toBe(false);
  });

  it('extracts target-risk context from an active sellerBelowTarget insight', async () => {
    const db = buildFakeDb({
      docs: {
        'organizations/org-1/representativeMonthlyAggregates/company-1_seller-1_2026-09': {
          revenueNet: 1000,
          orderCount: 1,
        },
      },
      collections: {
        'organizations/org-1/insights': [
          {
            id: 'target-risk-1',
            data: {
              sellerId: 'seller-1',
              recipientUserId: 'manager-1',
              status: 'fresh',
              type: 'sellerBelowTarget',
              title: 'Risco alto de meta',
              description: 'Projetado abaixo da meta',
              severity: 'high',
              estimatedImpact: { amount: 2000 },
              evidence: [
                { code: 'target_value', label: 'Meta', value: '10000.00', numericValue: 10000 },
                { code: 'realized_value', label: 'Realizado', value: '6000.00', numericValue: 6000 },
                {
                  code: 'projected_achievement_percentage',
                  label: 'Percentual projetado',
                  value: '70.0',
                  numericValue: 70,
                },
              ],
            },
          },
        ],
      },
    });

    const payload = await buildWalletSummaryPayload({
      db,
      organizationId,
      companyId,
      sellerId,
      sellerName: 'Ana Vendedora',
      now,
    });

    expect(payload.targetRisk).not.toBeNull();
    expect(payload.targetRisk?.targetValue).toBe(10000);
    expect(payload.targetRisk?.realizedValue).toBe(6000);
    expect(payload.targetRisk?.projectedAchievementPercentage).toBe(70);
    expect(payload.targetRisk?.dataPointCodes.length).toBe(3);
  });
});

describe('computePayloadHash', () => {
  const basePayload: WalletSummaryPayload = {
    organizationId: 'org-1',
    companyId: 'company-1',
    sellerId: 'seller-1',
    sellerName: 'Ana',
    periodKey: '2026-09',
    periodLabel: 'setembro/2026',
    revenueCurrentMonthDataPointCode: 'revenue_current_month',
    revenueOrderCountDataPointCode: 'order_count_current_month',
    revenuePreviousMonthDataPointCode: null,
    targetRisk: null,
    insights: [],
    dataPoints: [
      { code: 'revenue_current_month', label: 'Faturamento', value: '1000.00', numericValue: 1000 },
      { code: 'order_count_current_month', label: 'Pedidos', value: '3', numericValue: 3 },
    ],
  };

  it('is stable regardless of dataPoints order', () => {
    const reordered: WalletSummaryPayload = {
      ...basePayload,
      dataPoints: [...basePayload.dataPoints].reverse(),
    };
    expect(computePayloadHash(basePayload)).toBe(computePayloadHash(reordered));
  });

  it('changes when a numeric value changes', () => {
    const changed: WalletSummaryPayload = {
      ...basePayload,
      dataPoints: basePayload.dataPoints.map((point) =>
        point.code === 'revenue_current_month' ? { ...point, numericValue: 1001, value: '1001.00' } : point,
      ),
    };
    expect(computePayloadHash(basePayload)).not.toBe(computePayloadHash(changed));
  });

  it('changes when a sellerName-only field changes are irrelevant but a data point is added', () => {
    const withExtra: WalletSummaryPayload = {
      ...basePayload,
      dataPoints: [...basePayload.dataPoints, { code: 'extra', label: 'Extra', value: '1', numericValue: 1 }],
    };
    expect(computePayloadHash(basePayload)).not.toBe(computePayloadHash(withExtra));
  });
});

describe('validateGeneratedSummary', () => {
  const payload: WalletSummaryPayload = {
    organizationId: 'org-1',
    companyId: 'company-1',
    sellerId: 'seller-1',
    sellerName: 'Ana',
    periodKey: '2026-09',
    periodLabel: 'setembro/2026',
    revenueCurrentMonthDataPointCode: 'revenue_current_month',
    revenueOrderCountDataPointCode: 'order_count_current_month',
    revenuePreviousMonthDataPointCode: 'revenue_previous_month',
    targetRisk: null,
    insights: [],
    dataPoints: [
      { code: 'revenue_current_month', label: 'Faturamento do mês', value: '12500.50', numericValue: 12500.5, unit: 'BRL' },
      { code: 'revenue_previous_month', label: 'Faturamento do mês anterior', value: '9800.00', numericValue: 9800, unit: 'BRL' },
      { code: 'order_count_current_month', label: 'Pedidos', value: '8', numericValue: 8 },
    ],
  };

  it('accepts a summary whose numbers all exist in the payload and cites a reference', () => {
    const text =
      'O faturamento do mês foi de R$ 12500,50, um crescimento em relação aos R$ 9800,00 do mês anterior ' +
      '[refs: revenue_current_month, revenue_previous_month].';
    const outcome = validateGeneratedSummary(text, payload);
    expect(outcome.ok).toBe(true);
    if (outcome.ok) {
      expect(outcome.citedDataPointCodes).toEqual(
        expect.arrayContaining(['revenue_current_month', 'revenue_previous_month']),
      );
    }
  });

  it('rejects a summary with no [refs: ...] citation at all', () => {
    const text = 'O faturamento do mês foi de R$ 12500,50.';
    const outcome = validateGeneratedSummary(text, payload);
    expect(outcome.ok).toBe(false);
    if (!outcome.ok) expect(outcome.reason).toBe('missing_references');
  });

  it('rejects a summary citing a reference code absent from the payload', () => {
    const text = 'Foram 8 pedidos no mês [refs: order_count_current_month, made_up_code].';
    const outcome = validateGeneratedSummary(text, payload);
    expect(outcome.ok).toBe(false);
    if (!outcome.ok) expect(outcome.reason).toBe('unknown_reference');
  });

  it('rejects a summary containing a number absent from the payload (hallucination)', () => {
    const text = 'O faturamento do mês foi de R$ 99999,99 [refs: revenue_current_month].';
    const outcome = validateGeneratedSummary(text, payload);
    expect(outcome.ok).toBe(false);
    if (!outcome.ok) expect(outcome.reason).toBe('hallucinated_number');
  });

  it('accepts a plain-decimal formatting of the same number the payload carries', () => {
    const text = 'Foram registrados 8 pedidos neste período [refs: order_count_current_month].';
    const outcome = validateGeneratedSummary(text, payload);
    expect(outcome.ok).toBe(true);
  });
});

describe('extractCitedDataPointCodes', () => {
  it('collects every distinct code across multiple citation blocks', () => {
    const text = 'Frase um [refs: a, b]. Frase dois [refs: b, c].';
    expect(extractCitedDataPointCodes(text)).toEqual(expect.arrayContaining(['a', 'b', 'c']));
  });

  it('returns an empty array when there is no citation block', () => {
    expect(extractCitedDataPointCodes('Sem citacoes aqui.')).toEqual([]);
  });
});

describe('parseFlexibleNumber', () => {
  it('parses a pt-BR formatted number (thousands "." decimal ",")', () => {
    expect(parseFlexibleNumber('12.500,50')).toBeCloseTo(12500.5);
  });

  it('parses a plain-decimal number', () => {
    expect(parseFlexibleNumber('12500.50')).toBeCloseTo(12500.5);
  });

  it('parses an integer', () => {
    expect(parseFlexibleNumber('8')).toBe(8);
  });

  it('returns null for a non-numeric token', () => {
    expect(parseFlexibleNumber('')).toBeNull();
  });
});

describe('resolveWalletSummaryReferences', () => {
  it('resolves cited codes to display-ready references, dropping unknown codes defensively', () => {
    const payload: WalletSummaryPayload = {
      organizationId: 'org-1',
      companyId: 'company-1',
      sellerId: 'seller-1',
      sellerName: 'Ana',
      periodKey: '2026-09',
      periodLabel: 'setembro/2026',
      revenueCurrentMonthDataPointCode: 'revenue_current_month',
      revenueOrderCountDataPointCode: 'order_count_current_month',
      revenuePreviousMonthDataPointCode: null,
      targetRisk: null,
      insights: [],
      dataPoints: [
        { code: 'revenue_current_month', label: 'Faturamento', value: '1000.00', numericValue: 1000, unit: 'BRL' },
      ],
    };
    const references = resolveWalletSummaryReferences(payload, ['revenue_current_month', 'unknown_code']);
    expect(references).toEqual([
      { code: 'revenue_current_month', label: 'Faturamento', value: '1000.00', unit: 'BRL' },
    ]);
  });
});

describe('buildWalletSummaryPrompt', () => {
  it('never includes a data point label without also including its code', () => {
    const payload: WalletSummaryPayload = {
      organizationId: 'org-1',
      companyId: 'company-1',
      sellerId: 'seller-1',
      sellerName: 'Ana',
      periodKey: '2026-09',
      periodLabel: 'setembro/2026',
      revenueCurrentMonthDataPointCode: 'revenue_current_month',
      revenueOrderCountDataPointCode: 'order_count_current_month',
      revenuePreviousMonthDataPointCode: null,
      targetRisk: null,
      insights: [],
      dataPoints: [
        { code: 'revenue_current_month', label: 'Faturamento', value: '1000.00', numericValue: 1000, unit: 'BRL' },
      ],
    };
    const { userPrompt } = buildWalletSummaryPrompt(payload);
    expect(userPrompt).toContain('revenue_current_month');
    expect(userPrompt).toContain('Faturamento');
  });
});

describe('assertCanAccessSellerWallet', () => {
  const organizationId = 'org-1';
  const sellerId = 'seller-1';

  it('allows a seller to access their own wallet', async () => {
    const db = buildFakeDb({});
    await expect(
      assertCanAccessSellerWallet({
        db,
        organizationId,
        requesterUid: sellerId,
        requesterRoleName: 'SALES_REP',
        sellerId,
      }),
    ).resolves.toBeUndefined();
  });

  it('allows OWNER/ADMIN to access any seller wallet', async () => {
    const db = buildFakeDb({});
    await expect(
      assertCanAccessSellerWallet({
        db,
        organizationId,
        requesterUid: 'owner-1',
        requesterRoleName: 'OWNER',
        sellerId,
      }),
    ).resolves.toBeUndefined();
  });

  it('allows a SALES_MANAGER who shares a team with the seller', async () => {
    const db = buildFakeDb({
      docs: {
        'organizations/org-1/members/manager-1': { teamIds: ['team-a'] },
        'organizations/org-1/members/seller-1': { teamIds: ['team-a', 'team-b'] },
      },
    });
    await expect(
      assertCanAccessSellerWallet({
        db,
        organizationId,
        requesterUid: 'manager-1',
        requesterRoleName: 'SALES_MANAGER',
        sellerId,
      }),
    ).resolves.toBeUndefined();
  });

  it('denies a SALES_MANAGER who does not share a team with the seller', async () => {
    const db = buildFakeDb({
      docs: {
        'organizations/org-1/members/manager-1': { teamIds: ['team-x'] },
        'organizations/org-1/members/seller-1': { teamIds: ['team-a'] },
      },
    });
    await expect(
      assertCanAccessSellerWallet({
        db,
        organizationId,
        requesterUid: 'manager-1',
        requesterRoleName: 'SALES_MANAGER',
        sellerId,
      }),
    ).rejects.toThrow(HttpsError);
  });

  it('denies a SALES_REP requesting a wallet other than their own', async () => {
    const db = buildFakeDb({});
    await expect(
      assertCanAccessSellerWallet({
        db,
        organizationId,
        requesterUid: 'other-rep',
        requesterRoleName: 'SALES_REP',
        sellerId,
      }),
    ).rejects.toThrow(HttpsError);
  });
});
