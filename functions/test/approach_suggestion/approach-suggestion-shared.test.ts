import { HttpsError } from 'firebase-functions/v2/https';

import {
  approachSuggestionDocId,
  assertCanAccessCustomer,
  buildApproachSuggestionPayload,
  buildApproachSuggestionPrompt,
  computePayloadHash,
  resolveApproachSuggestionReferences,
  validateGeneratedApproachSuggestion,
} from '../../src/approach_suggestion/approach-suggestion-shared';
import type { ApproachSuggestionPayload } from '../../src/approach_suggestion/approach-suggestion-types';

// ---------------------------------------------------------------------------
// Minimal fake Firestore — same "fake the exact seam the code under test
// uses" approach as `../wallet_summary/wallet-summary-shared.test.ts`, with
// `orderBy` support added since `buildApproachSuggestionPayload` orders its
// orders/CRM-activities queries by recency.
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

interface Filter {
  field: string;
  op: string;
  value: unknown;
}

interface OrderBy {
  field: string;
  direction: 'asc' | 'desc';
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
    return this.buildQuery(path, [], null, undefined);
  }

  private buildDoc(pathSegments: string[]): any {
    const path = pathSegments.join('/');
    return {
      collection: (name: string) => this.buildCollection([...pathSegments, name]),
      get: async () => fakeSnapshot(this.docsByPath.get(path)),
    };
  }

  private buildQuery(
    collectionPath: string,
    filters: Filter[],
    orderBy: OrderBy | null,
    limitCount: number | undefined,
  ): any {
    return {
      doc: (id: string) => this.buildDoc([...collectionPath.split('/'), id]),
      where: (field: string, op: string, value: unknown) =>
        this.buildQuery(collectionPath, [...filters, { field, op, value }], orderBy, limitCount),
      orderBy: (field: string, direction: 'asc' | 'desc' = 'asc') =>
        this.buildQuery(collectionPath, filters, { field, direction }, limitCount),
      limit: (count: number) => this.buildQuery(collectionPath, filters, orderBy, count),
      get: async () => {
        let docs = (this.collectionsByPath.get(collectionPath) ?? []).filter((doc) =>
          filters.every((filter) => (doc.data as Record<string, unknown>)[filter.field] === filter.value),
        );
        if (orderBy) {
          const { field, direction } = orderBy;
          docs = [...docs].sort((left, right) => {
            const leftValue = toComparable((left.data as Record<string, unknown>)[field]);
            const rightValue = toComparable((right.data as Record<string, unknown>)[field]);
            const comparison = leftValue < rightValue ? -1 : leftValue > rightValue ? 1 : 0;
            return direction === 'desc' ? -comparison : comparison;
          });
        }
        if (limitCount != null) {
          docs = docs.slice(0, limitCount);
        }
        return fakeQuerySnapshot(docs);
      },
    };
  }
}

function toComparable(value: unknown): number {
  if (value instanceof Date) return value.getTime();
  if (typeof value === 'string') return new Date(value).getTime();
  return 0;
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

describe('approachSuggestionDocId', () => {
  it('is just the customerId', () => {
    expect(approachSuggestionDocId('customer-1')).toBe('customer-1');
  });
});

describe('buildApproachSuggestionPayload', () => {
  const organizationId = 'org-1';
  const companyId = 'company-1';
  const customerId = 'customer-1';

  it('builds order highlights from the customer\'s own real orders, newest first', async () => {
    const db = buildFakeDb({
      collections: {
        'organizations/org-1/orders': [
          {
            id: 'order-old',
            data: {
              companyId,
              deletedAt: null,
              customerId,
              orderNumber: 'PED-001',
              status: 'delivered',
              createdAt: new Date('2026-06-01T00:00:00.000Z'),
              items: [{ subtotal: 100 }],
              shippingAmount: 0,
              surchargeAmount: 0,
              discountAmount: 0,
            },
          },
          {
            id: 'order-new',
            data: {
              companyId,
              deletedAt: null,
              customerId,
              orderNumber: 'PED-002',
              status: 'submitted',
              createdAt: new Date('2026-09-01T00:00:00.000Z'),
              items: [{ subtotal: 200 }, { subtotal: 50 }],
              shippingAmount: 10,
              surchargeAmount: 0,
              discountAmount: 5,
            },
          },
          {
            id: 'order-other-customer',
            data: {
              companyId,
              deletedAt: null,
              customerId: 'customer-2',
              orderNumber: 'PED-999',
              status: 'submitted',
              createdAt: new Date('2026-09-02T00:00:00.000Z'),
              items: [{ subtotal: 999 }],
              shippingAmount: 0,
              surchargeAmount: 0,
              discountAmount: 0,
            },
          },
        ],
      },
    });

    const payload = await buildApproachSuggestionPayload({
      db,
      organizationId,
      companyId,
      customerId,
      customerName: 'Loja Exemplo',
      customerSegment: 'Varejo',
      customerPotential: 'Alto',
    });

    expect(payload.recentOrders).toHaveLength(2);
    expect(payload.recentOrders[0].orderNumber).toBe('PED-002');
    expect(payload.recentOrders[1].orderNumber).toBe('PED-001');
    const newOrderTotalCode = payload.recentOrders[0].totalAmountDataPointCode;
    const totalDataPoint = payload.dataPoints.find((point) => point.code === newOrderTotalCode);
    expect(totalDataPoint?.numericValue).toBeCloseTo(200 + 50 + 10 - 5);
  });

  it('never leaks another customer\'s order/activity/insight into the payload', async () => {
    const db = buildFakeDb({
      collections: {
        'organizations/org-1/orders': [
          {
            id: 'order-other-customer',
            data: {
              companyId,
              deletedAt: null,
              customerId: 'customer-2',
              orderNumber: 'PED-999',
              status: 'submitted',
              createdAt: new Date(),
              items: [],
              shippingAmount: 0,
              surchargeAmount: 0,
              discountAmount: 0,
            },
          },
        ],
        'organizations/org-1/crmActivities': [
          { id: 'activity-other', data: { customerId: 'customer-2', type: 'note', occurredAt: new Date(), description: 'x' } },
        ],
        'organizations/org-1/insights': [
          {
            id: 'insight-other',
            data: {
              customerId: 'customer-2',
              status: 'fresh',
              type: 'inactiveCustomer',
              title: 'x',
              description: 'x',
              severity: 'low',
              estimatedImpact: {},
              evidence: [],
            },
          },
        ],
      },
    });

    const payload = await buildApproachSuggestionPayload({
      db,
      organizationId,
      companyId,
      customerId,
      customerName: 'Loja Exemplo',
      customerSegment: null,
      customerPotential: null,
    });

    expect(payload.recentOrders).toHaveLength(0);
    expect(payload.recentActivities).toHaveLength(0);
    expect(payload.insights).toHaveLength(0);
  });

  it('always sets recentOutcomeReason to null (no Firestore-backed source today)', async () => {
    const db = buildFakeDb({});
    const payload = await buildApproachSuggestionPayload({
      db,
      organizationId,
      companyId,
      customerId,
      customerName: 'Loja Exemplo',
      customerSegment: null,
      customerPotential: null,
    });
    expect(payload.recentOutcomeReason).toBeNull();
  });

  it('sorts insights by highest estimated impact first', async () => {
    const db = buildFakeDb({
      collections: {
        'organizations/org-1/insights': [
          {
            id: 'insight-low',
            data: {
              customerId,
              status: 'fresh',
              type: 'crossSell',
              title: 'Baixo impacto',
              description: 'x',
              severity: 'low',
              estimatedImpact: { amount: 100 },
              evidence: [],
            },
          },
          {
            id: 'insight-high',
            data: {
              customerId,
              status: 'fresh',
              type: 'revenueDrop',
              title: 'Alto impacto',
              description: 'x',
              severity: 'high',
              estimatedImpact: { amount: 5000 },
              evidence: [],
            },
          },
        ],
      },
    });

    const payload = await buildApproachSuggestionPayload({
      db,
      organizationId,
      companyId,
      customerId,
      customerName: 'Loja Exemplo',
      customerSegment: null,
      customerPotential: null,
    });

    expect(payload.insights[0].insightId).toBe('insight-high');
    expect(payload.insights[1].insightId).toBe('insight-low');
  });
});

describe('computePayloadHash', () => {
  const basePayload: ApproachSuggestionPayload = {
    organizationId: 'org-1',
    companyId: 'company-1',
    customerId: 'customer-1',
    customerName: 'Loja Exemplo',
    customerSegment: null,
    customerPotential: null,
    recentOrders: [],
    recentActivities: [],
    insights: [],
    recentOutcomeReason: null,
    dataPoints: [{ code: 'a', label: 'A', value: '1', numericValue: 1 }],
  };

  it('is stable regardless of dataPoints order', () => {
    const reordered: ApproachSuggestionPayload = {
      ...basePayload,
      dataPoints: [
        { code: 'b', label: 'B', value: '2', numericValue: 2 },
        ...basePayload.dataPoints,
      ],
    };
    const reorderedAgain: ApproachSuggestionPayload = {
      ...basePayload,
      dataPoints: [...reordered.dataPoints].reverse(),
    };
    expect(computePayloadHash(reordered)).toBe(computePayloadHash(reorderedAgain));
  });

  it('changes when a numeric value changes', () => {
    const changed: ApproachSuggestionPayload = {
      ...basePayload,
      dataPoints: [{ code: 'a', label: 'A', value: '2', numericValue: 2 }],
    };
    expect(computePayloadHash(basePayload)).not.toBe(computePayloadHash(changed));
  });

  it('changes when customerName-only fields differ but a data point is added', () => {
    const withExtra: ApproachSuggestionPayload = {
      ...basePayload,
      dataPoints: [...basePayload.dataPoints, { code: 'extra', label: 'Extra', value: '9', numericValue: 9 }],
    };
    expect(computePayloadHash(basePayload)).not.toBe(computePayloadHash(withExtra));
  });
});

describe('validateGeneratedApproachSuggestion', () => {
  const payload: ApproachSuggestionPayload = {
    organizationId: 'org-1',
    companyId: 'company-1',
    customerId: 'customer-1',
    customerName: 'Loja Exemplo',
    customerSegment: 'Varejo',
    customerPotential: 'Alto',
    recentOrders: [],
    recentActivities: [],
    insights: [],
    recentOutcomeReason: null,
    dataPoints: [
      { code: 'order_1_total_amount', label: 'Valor do pedido PED-002', value: '255.00', numericValue: 255, unit: 'BRL' },
      { code: 'insight_x_impact_amount', label: 'Impacto estimado', value: '500.00', numericValue: 500, unit: 'BRL' },
    ],
  };

  it('accepts a suggestion whose numbers all exist in the payload and cites a reference', () => {
    const text =
      'O último pedido de Loja Exemplo foi de R$ 255,00 [refs: order_1_total_amount]. ' +
      'Vale explorar a oportunidade de R$ 500,00 identificada recentemente [refs: insight_x_impact_amount].';
    const outcome = validateGeneratedApproachSuggestion(text, payload);
    expect(outcome.ok).toBe(true);
  });

  it('rejects a suggestion with no [refs: ...] citation at all', () => {
    const text = 'O último pedido foi de R$ 255,00.';
    const outcome = validateGeneratedApproachSuggestion(text, payload);
    expect(outcome.ok).toBe(false);
    if (!outcome.ok) expect(outcome.reason).toBe('missing_references');
  });

  it('rejects a suggestion citing a reference code absent from the payload', () => {
    const text = 'Cliente com bom histórico [refs: made_up_code].';
    const outcome = validateGeneratedApproachSuggestion(text, payload);
    expect(outcome.ok).toBe(false);
    if (!outcome.ok) expect(outcome.reason).toBe('unknown_reference');
  });

  it('rejects a suggestion containing a number absent from the payload (hallucination)', () => {
    const text = 'O cliente já comprou 12 vezes este ano [refs: order_1_total_amount].';
    const outcome = validateGeneratedApproachSuggestion(text, payload);
    expect(outcome.ok).toBe(false);
    if (!outcome.ok) expect(outcome.reason).toBe('hallucinated_number');
  });

  it.each(['desconto', 'Podemos oferecer uma condição especial', 'isso é cortesia da loja', 'garantimos que'])(
    'rejects a suggestion mentioning a forbidden commercial term: %s',
    (fragment) => {
      const text = `${fragment} para reforçar o relacionamento [refs: order_1_total_amount] R$ 255,00.`;
      const outcome = validateGeneratedApproachSuggestion(text, payload);
      expect(outcome.ok).toBe(false);
      if (!outcome.ok) expect(outcome.reason).toBe('forbidden_commercial_term');
    },
  );

  it('rejects a forbidden term even when the rest of the text would otherwise pass validation', () => {
    const text = 'Podemos garantir um desconto especial [refs: order_1_total_amount] de R$ 255,00.';
    const outcome = validateGeneratedApproachSuggestion(text, payload);
    expect(outcome.ok).toBe(false);
    if (!outcome.ok) expect(outcome.reason).toBe('forbidden_commercial_term');
  });
});

describe('resolveApproachSuggestionReferences', () => {
  it('resolves cited codes to display-ready references, dropping unknown codes defensively', () => {
    const payload: ApproachSuggestionPayload = {
      organizationId: 'org-1',
      companyId: 'company-1',
      customerId: 'customer-1',
      customerName: 'Loja Exemplo',
      customerSegment: null,
      customerPotential: null,
      recentOrders: [],
      recentActivities: [],
      insights: [],
      recentOutcomeReason: null,
      dataPoints: [{ code: 'a', label: 'A', value: '1', unit: 'BRL', numericValue: 1 }],
    };
    const references = resolveApproachSuggestionReferences(payload, ['a', 'unknown']);
    expect(references).toEqual([{ code: 'a', label: 'A', value: '1', unit: 'BRL' }]);
  });
});

describe('buildApproachSuggestionPrompt', () => {
  it('never includes a data point label without also including its code', () => {
    const payload: ApproachSuggestionPayload = {
      organizationId: 'org-1',
      companyId: 'company-1',
      customerId: 'customer-1',
      customerName: 'Loja Exemplo',
      customerSegment: null,
      customerPotential: null,
      recentOrders: [],
      recentActivities: [],
      insights: [],
      recentOutcomeReason: null,
      dataPoints: [{ code: 'order_1_total_amount', label: 'Valor do pedido', value: '255.00', numericValue: 255 }],
    };
    const { userPrompt, systemPrompt } = buildApproachSuggestionPrompt(payload);
    expect(userPrompt).toContain('order_1_total_amount');
    expect(userPrompt).toContain('Valor do pedido');
    expect(systemPrompt.toLowerCase()).toContain('desconto');
  });
});

describe('assertCanAccessCustomer', () => {
  const organizationId = 'org-1';
  const customerId = 'customer-1';

  it('allows the customer\'s own responsible seller', async () => {
    const db = buildFakeDb({
      docs: { 'organizations/org-1/customers/customer-1': { responsibleSellerId: 'seller-1' } },
    });
    await expect(
      assertCanAccessCustomer({
        db,
        organizationId,
        requesterUid: 'seller-1',
        requesterRoleName: 'SALES_REP',
        customerId,
      }),
    ).resolves.toEqual({ responsibleSellerId: 'seller-1' });
  });

  it('allows OWNER/ADMIN to access any customer', async () => {
    const db = buildFakeDb({
      docs: { 'organizations/org-1/customers/customer-1': { responsibleSellerId: 'seller-1' } },
    });
    await expect(
      assertCanAccessCustomer({
        db,
        organizationId,
        requesterUid: 'owner-1',
        requesterRoleName: 'OWNER',
        customerId,
      }),
    ).resolves.toEqual({ responsibleSellerId: 'seller-1' });
  });

  it('allows a SALES_MANAGER who shares a team with the responsible seller', async () => {
    const db = buildFakeDb({
      docs: {
        'organizations/org-1/customers/customer-1': { responsibleSellerId: 'seller-1' },
        'organizations/org-1/members/manager-1': { teamIds: ['team-a'] },
        'organizations/org-1/members/seller-1': { teamIds: ['team-a', 'team-b'] },
      },
    });
    await expect(
      assertCanAccessCustomer({
        db,
        organizationId,
        requesterUid: 'manager-1',
        requesterRoleName: 'SALES_MANAGER',
        customerId,
      }),
    ).resolves.toEqual({ responsibleSellerId: 'seller-1' });
  });

  it('denies a SALES_MANAGER who does not share a team with the responsible seller', async () => {
    const db = buildFakeDb({
      docs: {
        'organizations/org-1/customers/customer-1': { responsibleSellerId: 'seller-1' },
        'organizations/org-1/members/manager-1': { teamIds: ['team-x'] },
        'organizations/org-1/members/seller-1': { teamIds: ['team-a'] },
      },
    });
    await expect(
      assertCanAccessCustomer({
        db,
        organizationId,
        requesterUid: 'manager-1',
        requesterRoleName: 'SALES_MANAGER',
        customerId,
      }),
    ).rejects.toThrow(HttpsError);
  });

  it('denies a SALES_REP who is not the responsible seller', async () => {
    const db = buildFakeDb({
      docs: { 'organizations/org-1/customers/customer-1': { responsibleSellerId: 'seller-1' } },
    });
    await expect(
      assertCanAccessCustomer({
        db,
        organizationId,
        requesterUid: 'other-rep',
        requesterRoleName: 'SALES_REP',
        customerId,
      }),
    ).rejects.toThrow(HttpsError);
  });

  it('throws not-found for a customer that does not exist in this organization', async () => {
    const db = buildFakeDb({});
    await expect(
      assertCanAccessCustomer({
        db,
        organizationId,
        requesterUid: 'seller-1',
        requesterRoleName: 'SALES_REP',
        customerId,
      }),
    ).rejects.toThrow(HttpsError);
  });
});
