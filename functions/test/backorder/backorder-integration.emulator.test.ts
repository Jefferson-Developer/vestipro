import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';

import { createBackorderRequest, type CreateBackorderRequestResponse } from '../../src/backorder/create-backorder-request';
import { decideBackorderApproval } from '../../src/backorder/decide-backorder-approval';
import { cancelBackorderRequest } from '../../src/backorder/cancel-backorder-request';
import { convertBackorderToOrder, type ConvertBackorderToOrderResponse } from '../../src/backorder/convert-backorder-to-order';
import { flagReadyBackordersForVariant } from '../../src/backorder/notify-backorders-on-stock-available';

// Talks to the Firestore emulator via the real Admin SDK
// (`FIRESTORE_EMULATOR_HOST`, set by `firebase emulators:exec`), same
// contract as `functions/test/fulfillment/fulfillment-integration.emulator.test.ts`
// (TASK-214) — **not executable in this sandbox** (no Java available for
// `firebase emulators:exec`, the same pre-existing limitation already
// documented in TASK-094/TASK-133/TASK-176/TASK-214's own CONCLUIDA docs).
// Must run in CI/an environment with the Firebase Emulator Suite before
// deploy.
const PROJECT_ID = 'demo-vestipro-backorder-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest<T>(data: T, auth?: CallableRequest<T>['auth']): CallableRequest<T> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<T>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(uid: string): CallableRequest<unknown>['auth'] {
  return { uid, token: {}, rawToken: 'raw-token' } as CallableRequest<unknown>['auth'];
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
  teamIds: string[] = [],
): Promise<void> {
  const now = Timestamp.now();
  await db.collection('organizations').doc(organizationId).collection('members').doc(uid).set({
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

async function seedCustomer(organizationId: string, id: string, companyId = 'company-1'): Promise<void> {
  await db.collection('organizations').doc(organizationId).collection('customers').doc(id).set({
    organizationId,
    companyId,
    name: `Cliente ${id}`,
  });
}

async function seedVariant(organizationId: string, productId: string, variantId: string): Promise<void> {
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('products')
    .doc(productId)
    .collection('variants')
    .doc(variantId)
    .set({ productId, variantId, sku: `${productId}-${variantId}` });
}

async function seedInventoryBalance(params: {
  organizationId: string;
  variantId: string;
  warehouseId: string;
  physicalQuantity: number;
  reservedQuantity?: number;
  blockedQuantity?: number;
}): Promise<void> {
  await db
    .collection('organizations')
    .doc(params.organizationId)
    .collection('inventory')
    .doc(`${params.variantId}_${params.warehouseId}`)
    .set({
      organizationId: params.organizationId,
      companyId: 'company-1',
      productId: 'product-1',
      variantId: params.variantId,
      warehouseId: params.warehouseId,
      physicalQuantity: params.physicalQuantity,
      reservedQuantity: params.reservedQuantity ?? 0,
      blockedQuantity: params.blockedQuantity ?? 0,
      version: 1,
      updatedAt: Timestamp.now(),
      updatedBy: 'system',
      lastSource: 'seed',
    });
}

async function seedOrderWithItem(params: {
  organizationId: string;
  id: string;
  sellerId: string;
  customerId: string;
  variantId: string;
  quantity: number;
}): Promise<void> {
  const now = Timestamp.now();
  await db.collection('organizations').doc(params.organizationId).collection('orders').doc(params.id).set({
    organizationId: params.organizationId,
    companyId: 'company-1',
    customerId: params.customerId,
    sellerId: params.sellerId,
    orderNumber: '000001',
    currency: 'BRL',
    status: 'submitted',
    items: [
      {
        id: 'item-1',
        productId: 'product-1',
        variantId: params.variantId,
        quantity: params.quantity,
        unitPrice: 50,
        warehouseId: null,
      },
    ],
    version: 1,
    createdAt: now,
    createdBy: params.sellerId,
    updatedAt: now,
    updatedBy: params.sellerId,
    deletedAt: null,
  });
}

describe('backorder Cloud Functions (TASK-215, EPIC-32)', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('creates a queued backorder from a product with only partial stock, without debiting inventory', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedCustomer('org-1', 'customer-1');
    await seedVariant('org-1', 'product-1', 'variant-1');
    await seedInventoryBalance({ organizationId: 'org-1', variantId: 'variant-1', warehouseId: 'wh-1', physicalQuantity: 3 });

    const wrapped = testEnv.wrap(createBackorderRequest);
    const response = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          backorderId: 'backorder-1',
          customerId: 'customer-1',
          productId: 'product-1',
          variantId: 'variant-1',
          quantity: 10,
          origin: 'catalog',
        },
        authFor('rep-1'),
      ),
    )) as CreateBackorderRequestResponse;

    expect(response.status).toBe('queued');
    expect(response.quantityAtRequest).toBe(3);

    const balance = await db
      .collection('organizations')
      .doc('org-1')
      .collection('inventory')
      .doc('variant-1_wh-1')
      .get();
    expect(balance.data()?.physicalQuantity).toBe(3);
  });

  it('parks a backorder above the auto-approve limit as awaiting_approval until decided', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP', ['team-1']);
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER', ['team-1']);
    await seedCustomer('org-1', 'customer-1');
    await seedVariant('org-1', 'product-1', 'variant-1');

    const wrapped = testEnv.wrap(createBackorderRequest);
    const response = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          backorderId: 'backorder-1',
          customerId: 'customer-1',
          productId: 'product-1',
          variantId: 'variant-1',
          quantity: 999,
          origin: 'catalog',
        },
        authFor('rep-1'),
      ),
    )) as CreateBackorderRequestResponse;
    expect(response.status).toBe('awaiting_approval');

    const decideWrapped = testEnv.wrap(decideBackorderApproval);
    await expect(
      decideWrapped(
        buildRequest({ organizationId: 'org-1', backorderId: 'backorder-1', approve: true }, authFor('rep-1')),
      ),
    ).rejects.toThrow();

    const decided = await decideWrapped(
      buildRequest({ organizationId: 'org-1', backorderId: 'backorder-1', approve: true }, authFor('manager-1')),
    );
    expect((decided as { status: string }).status).toBe('queued');
  });

  it('queue ordering: higher priority and older requests rank first across multiple customers', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedCustomer('org-1', 'customer-a');
    await seedCustomer('org-1', 'customer-b');
    await seedVariant('org-1', 'product-1', 'variant-1');

    const wrapped = testEnv.wrap(createBackorderRequest);
    await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          backorderId: 'backorder-normal',
          customerId: 'customer-a',
          productId: 'product-1',
          variantId: 'variant-1',
          quantity: 5,
          origin: 'catalog',
          priority: 'normal',
        },
        authFor('rep-1'),
      ),
    );
    await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          backorderId: 'backorder-urgent',
          customerId: 'customer-b',
          productId: 'product-1',
          variantId: 'variant-1',
          quantity: 5,
          origin: 'catalog',
          priority: 'urgent',
        },
        authFor('rep-1'),
      ),
    );

    const snapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('backorders')
      .where('status', '==', 'queued')
      .get();
    const sorted = snapshot.docs
      .map((doc) => doc.data())
      .sort((left, right) => (right.priorityWeight as number) - (left.priorityWeight as number));
    expect(sorted[0].customerId).toBe('customer-b');
    expect(sorted[1].customerId).toBe('customer-a');
  });

  it('flags a queued backorder ready_to_fulfill once stock increases enough, then converts it into an already-submitted order', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedCustomer('org-1', 'customer-1');
    await seedVariant('org-1', 'product-1', 'variant-1');

    const createWrapped = testEnv.wrap(createBackorderRequest);
    await createWrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          backorderId: 'backorder-1',
          customerId: 'customer-1',
          productId: 'product-1',
          variantId: 'variant-1',
          quantity: 10,
          origin: 'catalog',
        },
        authFor('rep-1'),
      ),
    );

    // Simulates `notifyBackordersOnStockAvailable`'s own trigger body, since
    // this suite talks to the callables directly and Firestore document
    // triggers are not invoked by `firebase-functions-test`'s wrap() helper.
    const flagged = await flagReadyBackordersForVariant(db, 'org-1', 'variant-1', 10);
    expect(flagged).toEqual(['backorder-1']);

    const flaggedSnapshot = await db.collection('organizations').doc('org-1').collection('backorders').doc('backorder-1').get();
    expect(flaggedSnapshot.data()?.status).toBe('ready_to_fulfill');

    await seedOrderWithItem({
      organizationId: 'org-1',
      id: 'order-1',
      sellerId: 'rep-1',
      customerId: 'customer-1',
      variantId: 'variant-1',
      quantity: 10,
    });

    const convertWrapped = testEnv.wrap(convertBackorderToOrder);
    const conversion = (await convertWrapped(
      buildRequest({ organizationId: 'org-1', backorderId: 'backorder-1', orderId: 'order-1' }, authFor('rep-1')),
    )) as ConvertBackorderToOrderResponse;
    expect(conversion.status).toBe('converted');
    expect(conversion.fulfilledQuantity).toBe(10);

    const converted = await db.collection('organizations').doc('org-1').collection('backorders').doc('backorder-1').get();
    expect(converted.data()?.status).toBe('converted');
    expect(converted.data()?.convertedOrderId).toBe('order-1');
  });

  it('rejects converting into an order that does not cover the pending quantity', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedCustomer('org-1', 'customer-1');
    await seedVariant('org-1', 'product-1', 'variant-1');

    const createWrapped = testEnv.wrap(createBackorderRequest);
    await createWrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          backorderId: 'backorder-1',
          customerId: 'customer-1',
          productId: 'product-1',
          variantId: 'variant-1',
          quantity: 10,
          origin: 'catalog',
        },
        authFor('rep-1'),
      ),
    );

    await seedOrderWithItem({
      organizationId: 'org-1',
      id: 'order-1',
      sellerId: 'rep-1',
      customerId: 'customer-1',
      variantId: 'variant-1',
      quantity: 4,
    });

    const convertWrapped = testEnv.wrap(convertBackorderToOrder);
    await expect(
      convertWrapped(
        buildRequest({ organizationId: 'org-1', backorderId: 'backorder-1', orderId: 'order-1' }, authFor('rep-1')),
      ),
    ).rejects.toThrow();
  });

  it('cancelBackorderRequest is only allowed while still open, never after converted', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedCustomer('org-1', 'customer-1');
    await seedVariant('org-1', 'product-1', 'variant-1');

    const createWrapped = testEnv.wrap(createBackorderRequest);
    await createWrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          backorderId: 'backorder-1',
          customerId: 'customer-1',
          productId: 'product-1',
          variantId: 'variant-1',
          quantity: 5,
          origin: 'catalog',
        },
        authFor('rep-1'),
      ),
    );

    const cancelWrapped = testEnv.wrap(cancelBackorderRequest);
    const cancelled = await cancelWrapped(
      buildRequest({ organizationId: 'org-1', backorderId: 'backorder-1', reason: 'Cliente desistiu' }, authFor('rep-1')),
    );
    expect((cancelled as { status: string }).status).toBe('cancelled');

    await expect(
      cancelWrapped(
        buildRequest({ organizationId: 'org-1', backorderId: 'backorder-1' }, authFor('rep-1')),
      ),
    ).rejects.toThrow();
  });
});
