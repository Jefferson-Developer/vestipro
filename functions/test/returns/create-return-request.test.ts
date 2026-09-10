import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  createReturnRequest,
  type CreateReturnRequestRequest,
  type CreateReturnRequestResponse,
} from '../../src/returns/create-return-request';

const PROJECT_ID = 'demo-vestipro-create-return-request-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: CreateReturnRequestRequest,
  auth?: CallableRequest<CreateReturnRequestRequest>['auth'],
): CallableRequest<CreateReturnRequestRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<CreateReturnRequestRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<CreateReturnRequestRequest>['auth'] {
  return { uid, token, rawToken: 'raw-token' } as CallableRequest<CreateReturnRequestRequest>['auth'];
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
  overrides: { teamIds?: string[]; customerId?: string } = {},
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
      teamIds: overrides.teamIds ?? [],
      customerId: overrides.customerId ?? null,
      status: 'active',
      version: 1,
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
      deletedAt: null,
    });
}

async function seedOrder(
  organizationId: string,
  companyId: string,
  orderId: string,
  overrides: {
    status?: string;
    sellerId?: string;
    customerId?: string;
    items?: Array<Record<string, unknown>>;
  } = {},
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
      customerId: overrides.customerId ?? 'customer-1',
      sellerId: overrides.sellerId ?? 'rep-1',
      orderNumber: '000001',
      currency: 'BRL',
      status: overrides.status ?? 'delivered',
      items: overrides.items ?? [
        {
          id: 'item-1',
          variantId: 'variant-1',
          productId: 'product-1',
          quantity: 4,
          unitPrice: 100,
          subtotal: 400,
          warehouseId: 'wh-1',
        },
      ],
      createdAt: now,
      createdBy: 'rep-1',
      updatedAt: now,
      updatedBy: 'rep-1',
      version: 1,
    });
}

function baseRequest(
  overrides: Partial<CreateReturnRequestRequest> = {},
): CreateReturnRequestRequest {
  return {
    organizationId: 'org-1',
    companyId: 'company-1',
    orderId: 'order-1',
    returnRequestId: 'return-1',
    reasonCategory: 'defect',
    items: [{ orderItemId: 'item-1', quantity: 2 }],
    ...overrides,
  };
}

describe('createReturnRequest', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('opens a devolução for the own pedido as SALES_REP, denormalizing items/warehouse and writing the audit trail', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1');
    const wrapped = testEnv.wrap(createReturnRequest);

    const result = (await wrapped(
      buildRequest(baseRequest(), authFor('rep-1')),
    )) as CreateReturnRequestResponse;

    expect(result.status).toBe('requested');
    expect(result.refundAmount).toBe(200);
    expect(result.items).toEqual([
      {
        orderItemId: 'item-1',
        productId: 'product-1',
        variantId: 'variant-1',
        quantity: 2,
        unitPrice: 100,
        subtotal: 200,
      },
    ]);

    const returnRequestSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('returnRequests')
      .doc('return-1')
      .get();
    const data = returnRequestSnapshot.data();
    expect(data?.status).toBe('requested');
    expect(data?.reasonCategory).toBe('defect');
    expect(data?.sellerId).toBe('rep-1');
    expect(data?.customerId).toBe('customer-1');
    expect(data?.items[0].warehouseId).toBe('wh-1');
    expect(data?.requestedBy).toBe('rep-1');

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(
      auditSnapshot.docs.filter((doc) => doc.data().action === 'return.requested'),
    ).toHaveLength(1);
  });

  it('rejects a quantity that exceeds the original order item quantity', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1');
    const wrapped = testEnv.wrap(createReturnRequest);

    await expect(
      wrapped(
        buildRequest(
          baseRequest({ items: [{ orderItemId: 'item-1', quantity: 5 }] }),
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'failed-precondition' });

    const snapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('returnRequests')
      .doc('return-1')
      .get();
    expect(snapshot.exists).toBe(false);
  });

  it('rejects a second devolução whose quantity would push the total above the item quantity', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1');
    const wrapped = testEnv.wrap(createReturnRequest);

    await wrapped(
      buildRequest(
        baseRequest({ returnRequestId: 'return-1', items: [{ orderItemId: 'item-1', quantity: 3 }] }),
        authFor('rep-1'),
      ),
    );

    await expect(
      wrapped(
        buildRequest(
          baseRequest({ returnRequestId: 'return-2', items: [{ orderItemId: 'item-1', quantity: 2 }] }),
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('rejects a request for a pedido not in an eligible status', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1', { status: 'submitted' });
    const wrapped = testEnv.wrap(createReturnRequest);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('rep-1'))),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('rejects a request missing a categorized reason', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1');
    const wrapped = testEnv.wrap(createReturnRequest);

    await expect(
      wrapped(
        buildRequest(
          { ...baseRequest(), reasonCategory: undefined },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('denies a SALES_ASSISTANT (no return.create) from requesting a devolução', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'assistant-1', 'SALES_ASSISTANT');
    await seedOrder('org-1', 'company-1', 'order-1', { sellerId: 'assistant-1' });
    const wrapped = testEnv.wrap(createReturnRequest);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('assistant-1'))),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('denies a SALES_REP from requesting a devolução for a pedido that is not their own', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1', { sellerId: 'rep-2' });
    const wrapped = testEnv.wrap(createReturnRequest);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('rep-1'))),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('allows a SALES_MANAGER to request a devolução for a pedido of their own team', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER', { teamIds: ['team-1'] });
    await seedMember('org-1', 'rep-1', 'SALES_REP', { teamIds: ['team-1'] });
    await seedOrder('org-1', 'company-1', 'order-1', { sellerId: 'rep-1' });
    const wrapped = testEnv.wrap(createReturnRequest);

    const result = (await wrapped(
      buildRequest(baseRequest(), authFor('manager-1')),
    )) as CreateReturnRequestResponse;
    expect(result.status).toBe('requested');
  });

  it('denies a SALES_MANAGER outside every team of the seller from requesting a devolução', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER', { teamIds: ['team-1'] });
    await seedMember('org-1', 'rep-1', 'SALES_REP', { teamIds: ['team-2'] });
    await seedOrder('org-1', 'company-1', 'order-1', { sellerId: 'rep-1' });
    const wrapped = testEnv.wrap(createReturnRequest);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('manager-1'))),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('lets the customer portal request a devolução only for its own pedido', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'buyer-1', 'CUSTOMER_PORTAL', { customerId: 'customer-1' });
    await seedOrder('org-1', 'company-1', 'order-1', { customerId: 'customer-1' });
    const wrapped = testEnv.wrap(createReturnRequest);

    const result = (await wrapped(
      buildRequest(baseRequest(), authFor('buyer-1', { email: 'buyer@store.com' })),
    )) as CreateReturnRequestResponse;
    expect(result.status).toBe('requested');

    await seedOrder('org-1', 'company-1', 'order-2', { customerId: 'customer-2' });
    await expect(
      wrapped(
        buildRequest(
          baseRequest({ orderId: 'order-2', returnRequestId: 'return-2' }),
          authFor('buyer-1', { email: 'buyer@store.com' }),
        ),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('replays the exact same result for a retried call with the same returnRequestId', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1');
    const wrapped = testEnv.wrap(createReturnRequest);
    const request = buildRequest(baseRequest(), authFor('rep-1'));

    const first = (await wrapped(request)) as CreateReturnRequestResponse;
    const second = (await wrapped(request)) as CreateReturnRequestResponse;

    expect(second).toEqual(first);

    const snapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('returnRequests')
      .get();
    expect(snapshot.docs).toHaveLength(1);
  });

  it('rejects a devolução whose order does not belong to the requested company', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1');
    const wrapped = testEnv.wrap(createReturnRequest);

    await expect(
      wrapped(
        buildRequest(baseRequest({ companyId: 'company-2' }), authFor('rep-1')),
      ),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });
});
