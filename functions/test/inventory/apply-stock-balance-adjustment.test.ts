import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  applyStockBalanceAdjustment,
  type ApplyStockBalanceAdjustmentRequest,
  type ApplyStockBalanceAdjustmentResponse,
} from '../../src/inventory/apply-stock-balance-adjustment';

const PROJECT_ID = 'demo-vestipro-inventory-adjustment-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: ApplyStockBalanceAdjustmentRequest,
  auth?: CallableRequest<ApplyStockBalanceAdjustmentRequest>['auth'],
): CallableRequest<ApplyStockBalanceAdjustmentRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<ApplyStockBalanceAdjustmentRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<ApplyStockBalanceAdjustmentRequest>['auth'] {
  return {
    uid,
    token,
    rawToken: 'raw-token',
  } as CallableRequest<ApplyStockBalanceAdjustmentRequest>['auth'];
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

describe('applyStockBalanceAdjustment', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('applies a delta incrementally and writes one audit entry', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    const wrapped = testEnv.wrap(applyStockBalanceAdjustment);

    const result = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          productId: 'product-1',
          variantId: 'variant-1',
          warehouseId: 'wh-1',
          source: 'manual_adjustment',
          idempotencyKey: 'adj-1',
          delta: {
            physicalQuantity: 12,
            reservedQuantity: 2,
            blockedQuantity: 1,
          },
        },
        authFor('owner-1', { name: 'Owner User' }),
      ),
    )) as ApplyStockBalanceAdjustmentResponse;

    expect(result.physicalQuantity).toBe(12);
    expect(result.reservedQuantity).toBe(2);
    expect(result.blockedQuantity).toBe(1);
    expect(result.sellableQuantity).toBe(9);
    expect(result.version).toBe(1);

    const balanceSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('inventory')
      .doc('variant-1_wh-1')
      .get();
    expect(balanceSnapshot.data()?.physicalQuantity).toBe(12);
    expect(balanceSnapshot.data()?.reservedQuantity).toBe(2);
    expect(balanceSnapshot.data()?.blockedQuantity).toBe(1);
    expect(balanceSnapshot.data()?.lastSource).toBe('manual_adjustment');
    expect(balanceSnapshot.data()?.version).toBe(1);

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.size).toBe(1);
    expect(auditSnapshot.docs[0].data().action).toBe('inventory.balanceAdjusted');
  });

  it('returns the stored result when the idempotency key is replayed', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    const wrapped = testEnv.wrap(applyStockBalanceAdjustment);

    const payload: ApplyStockBalanceAdjustmentRequest = {
      organizationId: 'org-1',
      companyId: 'company-1',
      productId: 'product-1',
      variantId: 'variant-1',
      warehouseId: 'wh-1',
      source: 'manual_adjustment',
      idempotencyKey: 'adj-replay',
      delta: {
        physicalQuantity: 5,
        reservedQuantity: 0,
        blockedQuantity: 0,
      },
    };

    const first = (await wrapped(
      buildRequest(payload, authFor('owner-1', { name: 'Owner User' })),
    )) as ApplyStockBalanceAdjustmentResponse;
    const second = (await wrapped(
      buildRequest(payload, authFor('owner-1', { name: 'Owner User' })),
    )) as ApplyStockBalanceAdjustmentResponse;

    expect(second).toEqual(first);

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.size).toBe(1);
  });

  it('blocks adjustments that would make sellable stock negative', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    const wrapped = testEnv.wrap(applyStockBalanceAdjustment);

    await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          productId: 'product-1',
          variantId: 'variant-1',
          warehouseId: 'wh-1',
          source: 'receipt',
          idempotencyKey: 'adj-seed',
          delta: {
            physicalQuantity: 2,
            reservedQuantity: 0,
            blockedQuantity: 0,
          },
        },
        authFor('owner-1'),
      ),
    );

    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            companyId: 'company-1',
            productId: 'product-1',
            variantId: 'variant-1',
            warehouseId: 'wh-1',
            source: 'manual_adjustment',
            idempotencyKey: 'adj-negative',
            delta: {
              physicalQuantity: 0,
              reservedQuantity: 3,
              blockedQuantity: 0,
            },
          },
          authFor('owner-1'),
        ),
      ),
    ).rejects.toMatchObject({
      code: 'failed-precondition',
      message: 'O ajuste deixaria o saldo vendável negativo.',
    });
  });
});
