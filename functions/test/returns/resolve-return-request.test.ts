import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  resolveReturnRequest,
  type ResolveReturnRequestRequest,
  type ResolveReturnRequestResponse,
} from '../../src/returns/resolve-return-request';

const PROJECT_ID = 'demo-vestipro-resolve-return-request-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: ResolveReturnRequestRequest,
  auth?: CallableRequest<ResolveReturnRequestRequest>['auth'],
): CallableRequest<ResolveReturnRequestRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<ResolveReturnRequestRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<ResolveReturnRequestRequest>['auth'] {
  return { uid, token, rawToken: 'raw-token' } as CallableRequest<ResolveReturnRequestRequest>['auth'];
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
  teamIds: string[] = [],
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
      teamIds,
      status: 'active',
      version: 1,
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
      deletedAt: null,
    });
}

async function seedInventoryBalance(
  organizationId: string,
  variantId: string,
  warehouseId: string,
  physicalQuantity: number,
): Promise<void> {
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('inventory')
    .doc(`${variantId}_${warehouseId}`)
    .set({
      organizationId,
      productId: 'product-1',
      variantId,
      warehouseId,
      physicalQuantity,
      reservedQuantity: 0,
      blockedQuantity: 0,
    });
}

async function seedOrder(
  organizationId: string,
  companyId: string,
  orderId: string,
  overrides: { status?: string; sellerId?: string; itemQuantity?: number } = {},
): Promise<void> {
  const now = Timestamp.now();
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('orders')
    .doc(orderId)
    .set({
      organizationId,
      companyId,
      customerId: 'customer-1',
      sellerId: overrides.sellerId ?? 'rep-1',
      orderNumber: '000001',
      currency: 'BRL',
      status: overrides.status ?? 'delivered',
      items: [
        {
          id: 'item-1',
          variantId: 'variant-1',
          productId: 'product-1',
          quantity: overrides.itemQuantity ?? 4,
          unitPrice: 100,
          subtotal: 400,
          warehouseId: 'wh-1',
        },
      ],
      statusHistory: [],
      createdAt: now,
      createdBy: 'rep-1',
      updatedAt: now,
      updatedBy: 'rep-1',
      version: 1,
    });
}

async function seedReturnRequest(
  organizationId: string,
  companyId: string,
  returnRequestId: string,
  overrides: {
    orderId?: string;
    sellerId?: string;
    status?: string;
    quantity?: number;
  } = {},
): Promise<void> {
  const now = Timestamp.now();
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('returnRequests')
    .doc(returnRequestId)
    .set({
      organizationId,
      companyId,
      orderId: overrides.orderId ?? 'order-1',
      orderNumber: '000001',
      customerId: 'customer-1',
      sellerId: overrides.sellerId ?? 'rep-1',
      currency: 'BRL',
      items: [
        {
          orderItemId: 'item-1',
          productId: 'product-1',
          variantId: 'variant-1',
          quantity: overrides.quantity ?? 2,
          unitPrice: 100,
          subtotal: (overrides.quantity ?? 2) * 100,
          warehouseId: 'wh-1',
        },
      ],
      reasonCategory: 'defect',
      reasonDetails: null,
      evidenceUrls: [],
      status: overrides.status ?? 'requested',
      refundAmount: (overrides.quantity ?? 2) * 100,
      requestedBy: 'rep-1',
      requestedByName: 'Rep One',
      requestedAt: now,
      decisions: [],
      decidedBy: null,
      decidedAt: null,
      decisionReason: null,
      createdAt: now,
      createdBy: 'rep-1',
      updatedAt: now,
      updatedBy: 'rep-1',
      version: 1,
    });
}

function baseRequest(
  overrides: Partial<ResolveReturnRequestRequest> = {},
): ResolveReturnRequestRequest {
  return {
    organizationId: 'org-1',
    companyId: 'company-1',
    returnRequestId: 'return-1',
    decision: 'approved',
    ...overrides,
  };
}

describe('resolveReturnRequest', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('approves a devolução, reintegrating stock into the exact warehouse of origin and marking the pedido partially returned', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    await seedOrder('org-1', 'company-1', 'order-1', { itemQuantity: 4 });
    await seedInventoryBalance('org-1', 'variant-1', 'wh-1', 6);
    await seedInventoryBalance('org-1', 'variant-1', 'wh-2', 50);
    await seedReturnRequest('org-1', 'company-1', 'return-1', { quantity: 2 });
    const wrapped = testEnv.wrap(resolveReturnRequest);

    const result = (await wrapped(
      buildRequest(baseRequest(), authFor('owner-1')),
    )) as ResolveReturnRequestResponse;

    expect(result.status).toBe('approved');
    expect(result.resultingOrderStatus).toBe('partiallyReturned');

    const balanceWh1 = await db
      .collection('organizations')
      .doc('org-1')
      .collection('inventory')
      .doc('variant-1_wh-1')
      .get();
    expect(balanceWh1.data()?.physicalQuantity).toBe(8);
    const balanceWh2 = await db
      .collection('organizations')
      .doc('org-1')
      .collection('inventory')
      .doc('variant-1_wh-2')
      .get();
    expect(balanceWh2.data()?.physicalQuantity).toBe(50);

    const orderSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .get();
    expect(orderSnapshot.data()?.status).toBe('partially_returned');
    expect(orderSnapshot.data()?.statusHistory).toHaveLength(1);

    const returnRequestSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('returnRequests')
      .doc('return-1')
      .get();
    expect(returnRequestSnapshot.data()?.status).toBe('approved');
    expect(returnRequestSnapshot.data()?.decisions).toHaveLength(1);
    expect(returnRequestSnapshot.data()?.decisions[0]).toMatchObject({
      decision: 'approved',
      actorId: 'owner-1',
    });

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(
      auditSnapshot.docs.filter((doc) => doc.data().action === 'return.approved'),
    ).toHaveLength(1);
  });

  it('marks the pedido fully returned once the approved devolução covers every unit of every item', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    await seedOrder('org-1', 'company-1', 'order-1', { itemQuantity: 2 });
    await seedInventoryBalance('org-1', 'variant-1', 'wh-1', 0);
    await seedReturnRequest('org-1', 'company-1', 'return-1', { quantity: 2 });
    const wrapped = testEnv.wrap(resolveReturnRequest);

    const result = (await wrapped(
      buildRequest(baseRequest(), authFor('owner-1')),
    )) as ResolveReturnRequestResponse;

    expect(result.resultingOrderStatus).toBe('returned');
    const orderSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .get();
    expect(orderSnapshot.data()?.status).toBe('returned');
  });

  it('rejects a devolução with a mandatory reason, applying no stock movement nor pedido status change', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    await seedOrder('org-1', 'company-1', 'order-1');
    await seedInventoryBalance('org-1', 'variant-1', 'wh-1', 6);
    await seedReturnRequest('org-1', 'company-1', 'return-1');
    const wrapped = testEnv.wrap(resolveReturnRequest);

    const result = (await wrapped(
      buildRequest(
        baseRequest({ decision: 'rejected', reason: 'Fora do prazo de troca.' }),
        authFor('owner-1'),
      ),
    )) as ResolveReturnRequestResponse;

    expect(result.status).toBe('rejected');

    const balance = await db
      .collection('organizations')
      .doc('org-1')
      .collection('inventory')
      .doc('variant-1_wh-1')
      .get();
    expect(balance.data()?.physicalQuantity).toBe(6);

    const orderSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('orders')
      .doc('order-1')
      .get();
    expect(orderSnapshot.data()?.status).toBe('delivered');

    const returnRequestSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('returnRequests')
      .doc('return-1')
      .get();
    expect(returnRequestSnapshot.data()?.status).toBe('rejected');
    expect(returnRequestSnapshot.data()?.decisionReason).toBe('Fora do prazo de troca.');
  });

  it('rejects the call when a recusa carries no reason', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    await seedOrder('org-1', 'company-1', 'order-1');
    await seedReturnRequest('org-1', 'company-1', 'return-1');
    const wrapped = testEnv.wrap(resolveReturnRequest);

    await expect(
      wrapped(buildRequest(baseRequest({ decision: 'rejected' }), authFor('owner-1'))),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('denies a SALES_REP (no return.approve) from deciding a devolução', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1');
    await seedReturnRequest('org-1', 'company-1', 'return-1');
    const wrapped = testEnv.wrap(resolveReturnRequest);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('rep-1'))),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('denies a SALES_MANAGER from deciding a devolução whose seller is outside every one of their own teams', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER', ['team-1']);
    await seedMember('org-1', 'rep-1', 'SALES_REP', ['team-2']);
    await seedOrder('org-1', 'company-1', 'order-1', { sellerId: 'rep-1' });
    await seedReturnRequest('org-1', 'company-1', 'return-1', { sellerId: 'rep-1' });
    const wrapped = testEnv.wrap(resolveReturnRequest);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('manager-1'))),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('allows a SALES_MANAGER to decide a devolução of their own team', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER', ['team-1']);
    await seedMember('org-1', 'rep-1', 'SALES_REP', ['team-1']);
    await seedOrder('org-1', 'company-1', 'order-1', { sellerId: 'rep-1' });
    await seedInventoryBalance('org-1', 'variant-1', 'wh-1', 0);
    await seedReturnRequest('org-1', 'company-1', 'return-1', { sellerId: 'rep-1' });
    const wrapped = testEnv.wrap(resolveReturnRequest);

    const result = (await wrapped(
      buildRequest(baseRequest(), authFor('manager-1')),
    )) as ResolveReturnRequestResponse;
    expect(result.status).toBe('approved');
  });

  it('rejects deciding a devolução that was already decided (rejected), never re-deciding it', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    await seedOrder('org-1', 'company-1', 'order-1');
    await seedReturnRequest('org-1', 'company-1', 'return-1', { status: 'rejected' });
    const wrapped = testEnv.wrap(resolveReturnRequest);

    await expect(
      wrapped(buildRequest(baseRequest({ decision: 'approved' }), authFor('owner-1'))),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('replays the exact same result for a retried decision, never appending a second decisions entry', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    await seedOrder('org-1', 'company-1', 'order-1');
    await seedInventoryBalance('org-1', 'variant-1', 'wh-1', 6);
    await seedReturnRequest('org-1', 'company-1', 'return-1');
    const wrapped = testEnv.wrap(resolveReturnRequest);
    const request = buildRequest(baseRequest(), authFor('owner-1'));

    const first = (await wrapped(request)) as ResolveReturnRequestResponse;
    const second = (await wrapped(request)) as ResolveReturnRequestResponse;

    expect(second).toEqual(first);

    const returnRequestSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('returnRequests')
      .doc('return-1')
      .get();
    expect(returnRequestSnapshot.data()?.decisions).toHaveLength(1);

    const balance = await db
      .collection('organizations')
      .doc('org-1')
      .collection('inventory')
      .doc('variant-1_wh-1')
      .get();
    expect(balance.data()?.physicalQuantity).toBe(8);
  });

  it('rejects deciding a devolução that does not belong to the requested company', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    await seedOrder('org-1', 'company-1', 'order-1');
    await seedReturnRequest('org-1', 'company-1', 'return-1');
    const wrapped = testEnv.wrap(resolveReturnRequest);

    await expect(
      wrapped(
        buildRequest(baseRequest({ companyId: 'company-2' }), authFor('owner-1')),
      ),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });
});
