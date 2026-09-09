import { HttpsError } from 'firebase-functions/v2/https';

import {
  CAMPAIGN_ASSIST_MAX_AUDIENCE_LENGTH,
  CAMPAIGN_ASSIST_MAX_PRODUCTS,
  assertCanAssistCampaignCreation,
  buildCampaignAssistPayload,
  buildCampaignAssistPrompt,
  campaignAssistCacheKey,
  computePayloadHash,
  formatCampaignAssistPeriod,
  loadCampaignAssistProductReferences,
  validateGeneratedCampaignAssist,
} from '../../src/campaign_assist/campaign-assist-shared';
import type { CampaignAssistPayload } from '../../src/campaign_assist/campaign-assist-types';

// ---------------------------------------------------------------------------
// Minimal fake Firestore — only the `collection(...).where('__name__', 'in',
// chunk).get()` seam `loadCampaignAssistProductReferences` actually uses.
// Same "fake the exact seam the code under test uses" approach as
// `../approach_suggestion/approach-suggestion-shared.test.ts`.
// ---------------------------------------------------------------------------

interface FakeProductDoc {
  id: string;
  data: Record<string, unknown>;
}

function buildFakeDb(productsByOrg: Record<string, FakeProductDoc[]>): any {
  return {
    collection: (name: string) => {
      if (name !== 'organizations') throw new Error(`unexpected top-level collection ${name}`);
      return {
        doc: (organizationId: string) => ({
          collection: (sub: string) => {
            if (sub !== 'products') throw new Error(`unexpected sub-collection ${sub}`);
            const docs = productsByOrg[organizationId] ?? [];
            return {
              where: (field: string, op: string, value: unknown) => {
                if (field !== '__name__' || op !== 'in') {
                  throw new Error(`unexpected query ${field} ${op}`);
                }
                const ids = value as string[];
                return {
                  get: async () => ({
                    docs: docs
                      .filter((doc) => ids.includes(doc.id))
                      .map((doc) => ({ id: doc.id, data: () => doc.data })),
                  }),
                };
              },
            };
          },
        }),
      };
    },
  };
}

describe('loadCampaignAssistProductReferences', () => {
  it('resolves only ids that exist in this organization\'s own products collection, preserving caller order', async () => {
    const db = buildFakeDb({
      'org-1': [
        { id: 'p2', data: { name: 'Vestido Floral', categoryName: 'Vestidos', collectionName: 'Verão 2026' } },
        { id: 'p1', data: { name: 'Camisa Linho', categoryName: 'Camisas', collectionName: null } },
      ],
    });

    const references = await loadCampaignAssistProductReferences(db, 'org-1', [
      'p1',
      'p-missing',
      'p2',
    ]);

    expect(references).toEqual([
      { productId: 'p1', name: 'Camisa Linho', categoryName: 'Camisas', collectionName: null },
      { productId: 'p2', name: 'Vestido Floral', categoryName: 'Vestidos', collectionName: 'Verão 2026' },
    ]);
  });

  it('never resolves a product id from another organization', async () => {
    const db = buildFakeDb({
      'org-1': [],
      'org-2': [{ id: 'p1', data: { name: 'Produto de outra org' } }],
    });

    const references = await loadCampaignAssistProductReferences(db, 'org-1', ['p1']);
    expect(references).toEqual([]);
  });

  it('returns an empty list for an empty input without querying anything', async () => {
    const db = buildFakeDb({});
    const references = await loadCampaignAssistProductReferences(db, 'org-1', []);
    expect(references).toEqual([]);
  });
});

describe('formatCampaignAssistPeriod', () => {
  it('formats a full range', () => {
    expect(
      formatCampaignAssistPeriod(new Date('2026-12-01T00:00:00.000Z'), new Date('2027-01-31T00:00:00.000Z')),
    ).toBe('01/12/2026 a 31/01/2027');
  });

  it('formats a start-only period', () => {
    expect(formatCampaignAssistPeriod(new Date('2026-12-01T00:00:00.000Z'), null)).toBe(
      'a partir de 01/12/2026',
    );
  });

  it('formats an end-only period', () => {
    expect(formatCampaignAssistPeriod(null, new Date('2027-01-31T00:00:00.000Z'))).toBe(
      'até 31/01/2027',
    );
  });

  it('returns null when neither date is set', () => {
    expect(formatCampaignAssistPeriod(null, null)).toBeNull();
  });
});

describe('buildCampaignAssistPayload', () => {
  it('truncates audience/tone defensively and caps the product list', () => {
    const longAudience = 'a'.repeat(CAMPAIGN_ASSIST_MAX_AUDIENCE_LENGTH + 50);
    const manyProducts = Array.from({ length: CAMPAIGN_ASSIST_MAX_PRODUCTS + 5 }, (_, index) => ({
      productId: `p${index}`,
      name: `Produto ${index}`,
      categoryName: null,
      collectionName: null,
    }));

    const payload = buildCampaignAssistPayload({
      organizationId: 'org-1',
      audienceDescription: longAudience,
      tone: 'sofisticado',
      startAt: null,
      endAt: null,
      productReferences: manyProducts,
    });

    expect(payload.audienceDescription.length).toBeLessThanOrEqual(
      CAMPAIGN_ASSIST_MAX_AUDIENCE_LENGTH + 1,
    );
    expect(payload.productReferences).toHaveLength(CAMPAIGN_ASSIST_MAX_PRODUCTS);
  });
});

describe('computePayloadHash', () => {
  const basePayload: CampaignAssistPayload = {
    organizationId: 'org-1',
    audienceDescription: 'Clientes urbanos',
    tone: 'sofisticado',
    periodLabel: null,
    productReferences: [
      { productId: 'p1', name: 'Camisa Linho', categoryName: 'Camisas', collectionName: null },
    ],
  };

  it('is stable regardless of productReferences order', () => {
    const withExtra: CampaignAssistPayload = {
      ...basePayload,
      productReferences: [
        { productId: 'p2', name: 'Calça Alfaiataria', categoryName: 'Calças', collectionName: null },
        ...basePayload.productReferences,
      ],
    };
    const reordered: CampaignAssistPayload = {
      ...withExtra,
      productReferences: [...withExtra.productReferences].reverse(),
    };
    expect(computePayloadHash(withExtra)).toBe(computePayloadHash(reordered));
  });

  it('changes when the audience description changes', () => {
    const changed: CampaignAssistPayload = { ...basePayload, audienceDescription: 'Outro público' };
    expect(computePayloadHash(basePayload)).not.toBe(computePayloadHash(changed));
  });

  it('changes when a product is added', () => {
    const withExtra: CampaignAssistPayload = {
      ...basePayload,
      productReferences: [
        ...basePayload.productReferences,
        { productId: 'p2', name: 'Calça Alfaiataria', categoryName: null, collectionName: null },
      ],
    };
    expect(computePayloadHash(basePayload)).not.toBe(computePayloadHash(withExtra));
  });
});

describe('campaignAssistCacheKey', () => {
  it('differs for different requesters with the same payload hash', () => {
    const keyA = campaignAssistCacheKey({ requesterUid: 'user-a', payloadHash: 'hash-1' });
    const keyB = campaignAssistCacheKey({ requesterUid: 'user-b', payloadHash: 'hash-1' });
    expect(keyA).not.toBe(keyB);
  });

  it('differs for different payload hashes with the same requester', () => {
    const keyA = campaignAssistCacheKey({ requesterUid: 'user-a', payloadHash: 'hash-1' });
    const keyB = campaignAssistCacheKey({ requesterUid: 'user-a', payloadHash: 'hash-2' });
    expect(keyA).not.toBe(keyB);
  });
});

describe('buildCampaignAssistPrompt', () => {
  it('always instructs a JSON-only response and never omits a product id from the user prompt', () => {
    const payload: CampaignAssistPayload = {
      organizationId: 'org-1',
      audienceDescription: 'Clientes urbanos',
      tone: 'sofisticado',
      periodLabel: '01/12/2026 a 31/01/2027',
      productReferences: [
        { productId: 'p1', name: 'Camisa Linho', categoryName: 'Camisas', collectionName: 'Verão 2026' },
      ],
    };
    const { systemPrompt, userPrompt } = buildCampaignAssistPrompt(payload);
    expect(systemPrompt).toContain('JSON');
    expect(systemPrompt.toLowerCase()).toContain('desconto');
    expect(userPrompt).toContain('p1');
    expect(userPrompt).toContain('Camisa Linho');
  });
});

describe('assertCanAssistCampaignCreation', () => {
  it.each(['OWNER', 'ADMIN'])('allows %s', (roleName) => {
    expect(() => assertCanAssistCampaignCreation(roleName)).not.toThrow();
  });

  it.each(['SALES_MANAGER', 'SALES_REP', 'SALES_ASSISTANT', 'FINANCE', 'READ_ONLY'])(
    'denies %s',
    (roleName) => {
      expect(() => assertCanAssistCampaignCreation(roleName)).toThrow(HttpsError);
    },
  );
});

describe('validateGeneratedCampaignAssist', () => {
  const payload: CampaignAssistPayload = {
    organizationId: 'org-1',
    audienceDescription: 'Clientes urbanos que buscam moda casual premium',
    tone: 'sofisticado e aspiracional',
    periodLabel: '01/12/2026 a 31/01/2027',
    productReferences: [
      { productId: 'p1', name: 'Camisa Linho', categoryName: 'Camisas', collectionName: 'Verão 2026' },
      { productId: 'p2', name: 'Calça Alfaiataria', categoryName: 'Calças', collectionName: 'Verão 2026' },
    ],
  };

  function validJson(overrides: Record<string, unknown> = {}): string {
    return JSON.stringify({
      title: 'Verão em Movimento',
      subtitle: 'Leveza e sofisticação para a nova estação',
      description: 'Uma seleção que combina a Camisa Linho com a Calça Alfaiataria para um look urbano premium.',
      citedProductIds: ['p1', 'p2'],
      ...overrides,
    });
  }

  it('accepts a well-formed draft citing real products actually mentioned in the text', () => {
    const outcome = validateGeneratedCampaignAssist(validJson(), payload);
    expect(outcome.ok).toBe(true);
    if (outcome.ok) {
      expect(outcome.title).toBe('Verão em Movimento');
      expect(outcome.citedProductIds).toEqual(['p1', 'p2']);
    }
  });

  it('accepts a draft with no cited products when none were provided', () => {
    const emptyPayload: CampaignAssistPayload = { ...payload, productReferences: [] };
    const outcome = validateGeneratedCampaignAssist(
      validJson({
        description: 'Uma narrativa de estação para o público certo.',
        citedProductIds: [],
      }),
      emptyPayload,
    );
    expect(outcome.ok).toBe(true);
  });

  it('tolerates a response wrapped in a markdown code fence', () => {
    const fenced = '```json\n' + validJson() + '\n```';
    const outcome = validateGeneratedCampaignAssist(fenced, payload);
    expect(outcome.ok).toBe(true);
  });

  it('rejects a response that is not valid JSON', () => {
    const outcome = validateGeneratedCampaignAssist('isto não é json', payload);
    expect(outcome.ok).toBe(false);
    if (!outcome.ok) expect(outcome.reason).toBe('invalid_json');
  });

  it('rejects a title exceeding the maximum length', () => {
    const outcome = validateGeneratedCampaignAssist(
      validJson({ title: 'x'.repeat(200) }),
      payload,
    );
    expect(outcome.ok).toBe(false);
    if (!outcome.ok) expect(outcome.reason).toBe('invalid_shape');
  });

  it('rejects an empty description', () => {
    const outcome = validateGeneratedCampaignAssist(validJson({ description: '' }), payload);
    expect(outcome.ok).toBe(false);
    if (!outcome.ok) expect(outcome.reason).toBe('invalid_shape');
  });

  it('rejects a citedProductIds entry that does not exist in the payload', () => {
    const outcome = validateGeneratedCampaignAssist(
      validJson({ citedProductIds: ['p1', 'p-made-up'] }),
      payload,
    );
    expect(outcome.ok).toBe(false);
    if (!outcome.ok) expect(outcome.reason).toBe('unknown_reference');
  });

  it('rejects citedProductIds whose products are never actually mentioned in the text', () => {
    const outcome = validateGeneratedCampaignAssist(
      validJson({
        description: 'Uma narrativa genérica sem citar nenhum item específico.',
        citedProductIds: ['p1'],
      }),
      payload,
    );
    expect(outcome.ok).toBe(false);
    if (!outcome.ok) expect(outcome.reason).toBe('unreferenced_citation');
  });

  it.each(['desconto', 'Podemos oferecer uma condição especial', 'isso é cortesia da loja'])(
    'rejects a draft mentioning a forbidden commercial term: %s',
    (fragment) => {
      const outcome = validateGeneratedCampaignAssist(
        validJson({ description: `${fragment} para quem comprar a Camisa Linho.` }),
        payload,
      );
      expect(outcome.ok).toBe(false);
      if (!outcome.ok) expect(outcome.reason).toBe('forbidden_commercial_term');
    },
  );
});
