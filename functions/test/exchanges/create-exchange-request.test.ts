import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  createExchangeRequest,
  type CreateExchangeRequestRequest,
  type CreateExchangeRequestResponse,
} from '../../src/exchanges/create-exchange-request';

const PROJECT_ID = 'demo-vestipro-create-exchange-request-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: CreateExchangeRequestRequest,
  auth?: CallableRequest<CreateExchangeRequestRequest>['auth'],
): CallableRequest<CreateExchangeRequestRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<CreateExchangeRequestRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<CreateExchangeRequestRequest>['auth'] {
  return { uid, token, rawToken: 'raw-token' } as CallableRequest<CreateExchangeRequestRequest>['auth'];
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
      priceListId: 'price-list-1',
      paymentTermId: 'payment-term-1',
      status: overrides.status ?? 'delivered',
      items: overrides.items ?? [
        {
          id: 'item-1',
          variantId: 'variant-origin',
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

async function seedProductVariant(
  organizationId: string,
  variantId: string,
  overrides: { productId?: string; status?: string } = {},
): Promise<void> {
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('productVariants')
    .doc(variantId)
    .set({
      productId: overrides.productId ?? 'product-1',
      status: overrides.status ?? 'active',
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
      variantId,
      warehouseId,
      physicalQuantity,
      reservedQuantity: 0,
      blockedQuantity: 0,
    });
}

function baseRequest(
  overrides: Partial<CreateExchangeRequestRequest> = {},
): CreateExchangeRequestRequest {
  return {
    organizationId: 'org-1',
    companyId: 'company-1',
    orderId: 'order-1',
    exchangeRequestId: 'exchange-1',
    reasonCategory: 'size_issue',
    items: [{ orderItemId: 'item-1', destinationVariantId: 'variant-destination', quantity: 2 }],
    ...overrides,
  };
}

describe('createExchangeRequest', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  async function seedHappyPath(): Promise<void> {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1');
    await seedProductVariant('org-1', 'variant-destination', { productId: 'product-1' });
    await seedInventoryBalance('org-1', 'variant-destination', 'wh-1', 10);
  }

  it('opens a troca for the own pedido as SALES_REP, checking destination availability and writing the audit trail', async () => {
    await seedHappyPath();
    const wrapped = testEnv.wrap(createExchangeRequest);

    const result = (await wrapped(
      buildRequest(baseRequest(), authFor('rep-1')),
    )) as CreateExchangeRequestResponse;

    expect(result.status).toBe('requested');
    expect(result.items).toEqual([
      {
        orderItemId: 'item-1',
        originProductId: 'product-1',
        originVariantId: 'variant-origin',
        originUnitPrice: 100,
        destinationVariantId: 'variant-destination',
        destinationProductId: 'product-1',
        quantity: 2,
      },
    ]);

    const exchangeRequestSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('exchangeRequests')
      .doc('exchange-1')
      .get();
    const data = exchangeRequestSnapshot.data();
    expect(data?.status).toBe('requested');
    expect(data?.reasonCategory).toBe('size_issue');
    expect(data?.sellerId).toBe('rep-1');

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(
      auditSnapshot.docs.filter((doc) => doc.data().action === 'exchange.requested'),
    ).toHaveLength(1);
  });

  it('rejects a request when the destination variant has no stock for the requested quantity', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1');
    await seedProductVariant('org-1', 'variant-destination', { productId: 'product-1' });
    await seedInventoryBalance('org-1', 'variant-destination', 'wh-1', 1);
    const wrapped = testEnv.wrap(createExchangeRequest);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('rep-1'))),
    ).rejects.toMatchObject({ code: 'failed-precondition' });

    const snapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('exchangeRequests')
      .doc('exchange-1')
      .get();
    expect(snapshot.exists).toBe(false);
  });

  it('rejects a destination variant that does not belong to the same product', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1');
    await seedProductVariant('org-1', 'variant-destination', { productId: 'product-2' });
    await seedInventoryBalance('org-1', 'variant-destination', 'wh-1', 10);
    const wrapped = testEnv.wrap(createExchangeRequest);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('rep-1'))),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('rejects a destination variant that is no longer active', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1');
    await seedProductVariant('org-1', 'variant-destination', {
      productId: 'product-1',
      status: 'inactive',
    });
    await seedInventoryBalance('org-1', 'variant-destination', 'wh-1', 10);
    const wrapped = testEnv.wrap(createExchangeRequest);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('rep-1'))),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('rejects a quantity that exceeds the original order item quantity', async () => {
    await seedHappyPath();
    const wrapped = testEnv.wrap(createExchangeRequest);

    await expect(
      wrapped(
        buildRequest(
          baseRequest({
            items: [{ orderItemId: 'item-1', destinationVariantId: 'variant-destination', quantity: 5 }],
          }),
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('rejects a destination variant equal to the origin variant', async () => {
    await seedHappyPath();
    const wrapped = testEnv.wrap(createExchangeRequest);

    await expect(
      wrapped(
        buildRequest(
          baseRequest({
            items: [{ orderItemId: 'item-1', destinationVariantId: 'variant-origin', quantity: 1 }],
          }),
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('rejects a request for a pedido not in an eligible status', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1', { status: 'submitted' });
    await seedProductVariant('org-1', 'variant-destination', { productId: 'product-1' });
    await seedInventoryBalance('org-1', 'variant-destination', 'wh-1', 10);
    const wrapped = testEnv.wrap(createExchangeRequest);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('rep-1'))),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('rejects a request missing a categorized reason', async () => {
    await seedHappyPath();
    const wrapped = testEnv.wrap(createExchangeRequest);

    await expect(
      wrapped(
        buildRequest({ ...baseRequest(), reasonCategory: undefined }, authFor('rep-1')),
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('denies a SALES_ASSISTANT (no exchange grant) from requesting a troca', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'assistant-1', 'SALES_ASSISTANT');
    await seedOrder('org-1', 'company-1', 'order-1', { sellerId: 'assistant-1' });
    await seedProductVariant('org-1', 'variant-destination', { productId: 'product-1' });
    await seedInventoryBalance('org-1', 'variant-destination', 'wh-1', 10);
    const wrapped = testEnv.wrap(createExchangeRequest);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('assistant-1'))),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('denies a SALES_REP from requesting a troca for a pedido that is not their own', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder('org-1', 'company-1', 'order-1', { sellerId: 'rep-2' });
    await seedProductVariant('org-1', 'variant-destination', { productId: 'product-1' });
    await seedInventoryBalance('org-1', 'variant-destination', 'wh-1', 10);
    const wrapped = testEnv.wrap(createExchangeRequest);

    await expect(
      wrapped(buildRequest(baseRequest(), authFor('rep-1'))),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('allows a SALES_MANAGER to request a troca for a pedido of their own team', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER', { teamIds: ['team-1'] });
    await seedMember('org-1', 'rep-1', 'SALES_REP', { teamIds: ['team-1'] });
    await seedOrder('org-1', 'company-1', 'order-1', { sellerId: 'rep-1' });
    await seedProductVariant('org-1', 'variant-destination', { productId: 'product-1' });
    await seedInventoryBalance('org-1', 'variant-destination', 'wh-1', 10);
    const wrapped = testEnv.wrap(createExchangeRequest);

    const result = (await wrapped(
      buildRequest(baseRequest(), authFor('manager-1')),
    )) as CreateExchangeRequestResponse;
    expect(result.status).toBe('requested');
  });

  it('replays the exact same result for a retried call with the same exchangeRequestId', async () => {
    await seedHappyPath();
    const wrapped = testEnv.wrap(createExchangeRequest);
    const request = buildRequest(baseRequest(), authFor('rep-1'));

    const first = (await wrapped(request)) as CreateExchangeRequestResponse;
    const second = (await wrapped(request)) as CreateExchangeRequestResponse;

    expect(second).toEqual(first);

    const snapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('exchangeRequests')
      .get();
    expect(snapshot.docs).toHaveLength(1);
  });

  it('rejects a troca whose order does not belong to the requested company', async () => {
    await seedHappyPath();
    const wrapped = testEnv.wrap(createExchangeRequest);

    await expect(
      wrapped(
        buildRequest(baseRequest({ companyId: 'company-2' }), authFor('rep-1')),
      ),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });
});
