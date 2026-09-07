import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';

import {
  decideReplenishmentSuggestion,
  type DecideReplenishmentSuggestionRequest,
  type DecideReplenishmentSuggestionResponse,
} from '../../src/replenishment/decide-replenishment-suggestion';

// Talks to the Firestore emulator via the real Admin SDK
// (`FIRESTORE_EMULATOR_HOST`, set by `firebase emulators:exec`), same
// contract as `functions/test/inventory/recompute-stock-turnover-metrics.test.ts`
// (TASK-094) and `functions/test/create-organization.test.ts` — **not
// executable in this sandbox** (no Java available for
// `firebase emulators:exec`, the same pre-existing limitation already
// documented in TASK-094/TASK-133's own CONCLUIDA docs). Must run in
// CI/an environment with the Firebase Emulator Suite before deploy.
const PROJECT_ID = 'demo-vestipro-replenishment-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: DecideReplenishmentSuggestionRequest,
  auth?: CallableRequest<DecideReplenishmentSuggestionRequest>['auth'],
): CallableRequest<DecideReplenishmentSuggestionRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<DecideReplenishmentSuggestionRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<DecideReplenishmentSuggestionRequest>['auth'] {
  return {
    uid,
    token,
    rawToken: 'raw-token',
  } as CallableRequest<DecideReplenishmentSuggestionRequest>['auth'];
}

async function clearFirestore(): Promise<void> {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
}

async function seedOrganization(organizationId: string): Promise<void> {
  const now = Timestamp.now();
  await db.collection('organizations').doc(organizationId).set({
    name: 'Grupo Fashion XPTO',
    slug: 'grupo-fashion-xpto',
    settings: { currency: 'BRL', country: 'BR', defaultLanguage: 'pt-BR' },
    status: 'active',
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
    deletedAt: null,
  });
}

async function seedMember(
  organizationId: string,
  uid: string,
  roleName: string,
): Promise<void> {
  const now = Timestamp.now();
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('members')
    .doc(uid)
    .set({
      organizationId,
      userId: uid,
      roleId: roleName,
      roleName,
      teamIds: [],
      status: 'active',
      version: 1,
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
      deletedAt: null,
    });
}

async function seedSuggestion(params: {
  organizationId: string;
  id: string;
  status: string;
  suggestedQuantity: number;
}): Promise<void> {
  const now = Timestamp.now();
  await db
    .collection('organizations')
    .doc(params.organizationId)
    .collection('replenishmentSuggestions')
    .doc(params.id)
    .set({
      organizationId: params.organizationId,
      companyId: 'company-1',
      warehouseId: 'warehouse-1',
      variantId: 'variant-1',
      productId: 'product-1',
      periodStart: '2026-08-01',
      periodEnd: '2026-09-07',
      status: params.status,
      insufficientDataReason: null,
      suggestedQuantity: params.suggestedQuantity,
      targetStockQuantity: params.suggestedQuantity,
      finalQuantity: null,
      currentSellableQuantity: 5,
      futureStockQuantity: 0,
      turnoverEvidence: {
        averageDailySalesQuantity: 2,
        stockCoverageDays: 2.5,
        turnoverRate: 0.4,
        coverageStatus: 'ready',
      },
      parametersSnapshot: { coverageTargetDays: 30, safetyStockQuantity: 0, seasonalityFactor: 1 },
      decidedBy: null,
      decidedByName: null,
      decidedAt: null,
      decisionAudit: [],
      generatedAt: now,
      updatedAt: now,
      version: 1,
    });
}

describe('decideReplenishmentSuggestion', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('accepts a suggestion and creates a draft order with the suggested quantity', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER');
    await seedSuggestion({
      organizationId: 'org-1',
      id: 'warehouse-1_variant-1_2026-09-07',
      status: 'suggested',
      suggestedQuantity: 30,
    });

    const wrapped = testEnv.wrap(decideReplenishmentSuggestion);
    const response = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          suggestionId: 'warehouse-1_variant-1_2026-09-07',
          action: 'accept',
        },
        authFor('manager-1'),
      ),
    )) as DecideReplenishmentSuggestionResponse;

    expect(response.status).toBe('accepted');
    expect(response.finalQuantity).toBe(30);
    expect(response.draftOrderId).not.toBeNull();

    const suggestion = await db
      .collection('organizations')
      .doc('org-1')
      .collection('replenishmentSuggestions')
      .doc('warehouse-1_variant-1_2026-09-07')
      .get();
    expect(suggestion.data()?.status).toBe('accepted');
    expect(suggestion.data()?.decisionAudit).toHaveLength(1);

    const draftOrder = await db
      .collection('organizations')
      .doc('org-1')
      .collection('replenishmentDraftOrders')
      .doc(response.draftOrderId!)
      .get();
    expect(draftOrder.exists).toBe(true);
    expect(draftOrder.data()?.items).toEqual([
      { variantId: 'variant-1', productId: 'product-1', quantity: 30 },
    ]);
    expect(draftOrder.data()?.originType).toBe('replenishment');
  });

  it('adjusts a suggestion with a manually chosen quantity', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER');
    await seedSuggestion({
      organizationId: 'org-1',
      id: 'warehouse-1_variant-1_2026-09-07',
      status: 'suggested',
      suggestedQuantity: 30,
    });

    const wrapped = testEnv.wrap(decideReplenishmentSuggestion);
    const response = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          suggestionId: 'warehouse-1_variant-1_2026-09-07',
          action: 'adjust',
          adjustedQuantity: 50,
        },
        authFor('manager-1'),
      ),
    )) as DecideReplenishmentSuggestionResponse;

    expect(response.status).toBe('adjusted');
    expect(response.finalQuantity).toBe(50);

    const draftOrder = await db
      .collection('organizations')
      .doc('org-1')
      .collection('replenishmentDraftOrders')
      .doc(response.draftOrderId!)
      .get();
    expect(draftOrder.data()?.items[0].quantity).toBe(50);
  });

  it('discards a suggestion without creating any draft order', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER');
    await seedSuggestion({
      organizationId: 'org-1',
      id: 'warehouse-1_variant-1_2026-09-07',
      status: 'suggested',
      suggestedQuantity: 30,
    });

    const wrapped = testEnv.wrap(decideReplenishmentSuggestion);
    const response = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          suggestionId: 'warehouse-1_variant-1_2026-09-07',
          action: 'discard',
          note: 'Estoque será descontinuado.',
        },
        authFor('manager-1'),
      ),
    )) as DecideReplenishmentSuggestionResponse;

    expect(response.status).toBe('discarded');
    expect(response.finalQuantity).toBeNull();
    expect(response.draftOrderId).toBeNull();

    const draftOrders = await db
      .collection('organizations')
      .doc('org-1')
      .collection('replenishmentDraftOrders')
      .get();
    expect(draftOrders.empty).toBe(true);
  });

  it('rejects a SALES_REP trying to decide a suggestion (RBAC re-validated server-side)', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedSuggestion({
      organizationId: 'org-1',
      id: 'warehouse-1_variant-1_2026-09-07',
      status: 'suggested',
      suggestedQuantity: 30,
    });

    const wrapped = testEnv.wrap(decideReplenishmentSuggestion);
    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            suggestionId: 'warehouse-1_variant-1_2026-09-07',
            action: 'accept',
          },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toThrow();
  });

  it('never lets a second decision overwrite an already-decided suggestion', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER');
    await seedSuggestion({
      organizationId: 'org-1',
      id: 'warehouse-1_variant-1_2026-09-07',
      status: 'accepted',
      suggestedQuantity: 30,
    });

    const wrapped = testEnv.wrap(decideReplenishmentSuggestion);
    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            suggestionId: 'warehouse-1_variant-1_2026-09-07',
            action: 'discard',
          },
          authFor('manager-1'),
        ),
      ),
    ).rejects.toThrow();
  });
});
