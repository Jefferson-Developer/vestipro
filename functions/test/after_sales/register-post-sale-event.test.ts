import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  registerPostSaleEvent,
  type RegisterPostSaleEventRequest,
  type RegisterPostSaleEventResponse,
} from '../../src/after_sales/register-post-sale-event';

const PROJECT_ID = 'demo-vestipro-register-post-sale-event-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: RegisterPostSaleEventRequest,
  auth?: CallableRequest<RegisterPostSaleEventRequest>['auth'],
): CallableRequest<RegisterPostSaleEventRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<RegisterPostSaleEventRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<RegisterPostSaleEventRequest>['auth'] {
  return { uid, token, rawToken: 'raw-token' } as CallableRequest<RegisterPostSaleEventRequest>['auth'];
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
  overrides: { status?: string; sellerId?: string; customerId?: string } = {},
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
      items: [
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
  overrides: Partial<RegisterPostSaleEventRequest> = {},
): RegisterPostSaleEventRequest {
  return {
    organizationId: 'org-1',
    companyId: 'company-1',
    orderId: 'order-1',
    eventId: 'event-1',
    type: 'delivered',
    ...overrides,
  };
}

describe('registerPostSaleEvent', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('registers a manual milestone for the own pedido as SALES_REP and notifies the vendedor', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1');
    const wrapped = testEnv.wrap(registerPostSaleEvent);

    const result = (await wrapped(
      buildRequest(baseRequest(), authFor('rep-1')),
    )) as RegisterPostSaleEventResponse;

    expect(result.type).toBe('delivered');
    expect(result.description).toBeNull();

    const eventSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('postSaleEvents')
      .doc('event-1')
      .get();
    const data = eventSnapshot.data();
    expect(data?.type).toBe('delivered');
    expect(data?.source).toBe('manual');
    expect(data?.sellerId).toBe('rep-1');
    expect(data?.notifiedSeller).toBe(true);

    const notificationsSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('notifications')
      .where('userId', '==', 'rep-1')
      .get();
    expect(notificationsSnapshot.docs).toHaveLength(1);
  });

  it('never notifies for a milestone outside the notifiable set (e.g. dispatched)', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1', { status: 'processing' });
    const wrapped = testEnv.wrap(registerPostSaleEvent);

    await wrapped(
      buildRequest(baseRequest({ type: 'dispatched' }), authFor('rep-1')),
    );

    const notificationsSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('notifications')
      .get();
    expect(notificationsSnapshot.docs).toHaveLength(0);
  });

  it('rejects a "problema reportado" without a description', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1');
    const wrapped = testEnv.wrap(registerPostSaleEvent);

    await expect(
      wrapped(
        buildRequest(
          baseRequest({ type: 'problem_reported', description: '   ' }),
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });

    const snapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('postSaleEvents')
      .doc('event-1')
      .get();
    expect(snapshot.exists).toBe(false);
  });

  it('accepts a "problema reportado" with a description and keeps it verbatim', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1');
    const wrapped = testEnv.wrap(registerPostSaleEvent);

    const result = (await wrapped(
      buildRequest(
        baseRequest({ type: 'problem_reported', description: 'Cliente reportou avaria na peça.' }),
        authFor('rep-1'),
      ),
    )) as RegisterPostSaleEventResponse;

    expect(result.description).toBe('Cliente reportou avaria na peça.');
  });

  it('rejects a manual type outside the allowed set (e.g. a system-only type)', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1');
    const wrapped = testEnv.wrap(registerPostSaleEvent);

    await expect(
      wrapped(
        buildRequest(
          { ...baseRequest(), type: 'return_requested' as never },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('rejects a request for a pedido not in an elegible status', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1', { status: 'submitted' });
    const wrapped = testEnv.wrap(registerPostSaleEvent);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('rep-1'))),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('denies a SALES_ASSISTANT (no postSaleEvent register grant) from registering an event', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'assistant-1', 'SALES_ASSISTANT');
    await seedOrder('org-1', 'company-1', 'order-1', { sellerId: 'assistant-1' });
    const wrapped = testEnv.wrap(registerPostSaleEvent);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('assistant-1'))),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('denies a SALES_REP from registering an event for a pedido that is not their own', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1', { sellerId: 'rep-2' });
    const wrapped = testEnv.wrap(registerPostSaleEvent);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('rep-1'))),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('replays the exact same result for a retried call with the same eventId (never a duplicate)', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1');
    const wrapped = testEnv.wrap(registerPostSaleEvent);
    const request = buildRequest(baseRequest(), authFor('rep-1'));

    const first = (await wrapped(request)) as RegisterPostSaleEventResponse;
    const second = (await wrapped(request)) as RegisterPostSaleEventResponse;

    expect(second).toEqual(first);

    const snapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('postSaleEvents')
      .get();
    expect(snapshot.docs).toHaveLength(1);

    const notificationsSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('notifications')
      .get();
    expect(notificationsSnapshot.docs).toHaveLength(1);
  });
});
