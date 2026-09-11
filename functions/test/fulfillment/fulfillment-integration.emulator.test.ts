import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';

import { createShipment, type CreateShipmentResponse } from '../../src/fulfillment/create-shipment';
import {
  registerLogisticsIssue,
  type RegisterLogisticsIssueResponse,
} from '../../src/fulfillment/register-logistics-issue';
import { resolveLogisticsIssue } from '../../src/fulfillment/resolve-logistics-issue';
import {
  registerTrackingEvent,
  type RegisterTrackingEventResponse,
} from '../../src/fulfillment/register-tracking-event';

// Talks to the Firestore emulator via the real Admin SDK
// (`FIRESTORE_EMULATOR_HOST`, set by `firebase emulators:exec`), same
// contract as `functions/test/replenishment/decide-replenishment-suggestion.test.ts`
// (TASK-176) — **not executable in this sandbox** (no Java available for
// `firebase emulators:exec`, the same pre-existing limitation already
// documented in TASK-094/TASK-133/TASK-176's own CONCLUIDA docs). Must run
// in CI/an environment with the Firebase Emulator Suite before deploy.
const PROJECT_ID = 'demo-vestipro-fulfillment-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest<T>(
  data: T,
  auth?: CallableRequest<T>['auth'],
): CallableRequest<T> {
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

async function seedMember(organizationId: string, uid: string, roleName: string): Promise<void> {
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

async function seedOrder(params: {
  organizationId: string;
  id: string;
  sellerId: string;
  status: string;
}): Promise<void> {
  const now = Timestamp.now();
  await db
    .collection('organizations')
    .doc(params.organizationId)
    .collection('orders')
    .doc(params.id)
    .set({
      organizationId: params.organizationId,
      companyId: 'company-1',
      customerId: 'customer-1',
      sellerId: params.sellerId,
      orderNumber: '000001',
      currency: 'BRL',
      status: params.status,
      statusHistory: [],
      items: [
        { id: 'item-1', productId: 'product-1', variantId: 'variant-1', quantity: 10, unitPrice: 50, warehouseId: null },
        { id: 'item-2', productId: 'product-2', variantId: 'variant-2', quantity: 5, unitPrice: 30, warehouseId: null },
      ],
      version: 1,
      createdAt: now,
      createdBy: params.sellerId,
      updatedAt: now,
      updatedBy: params.sellerId,
    });
}

describe('fulfillment Cloud Functions (TASK-214, EPIC-32)', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('createShipment rejects an order that is not invoiced/partially_invoiced yet', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder({ organizationId: 'org-1', id: 'order-1', sellerId: 'rep-1', status: 'processing' });

    const wrapped = testEnv.wrap(createShipment);
    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            companyId: 'company-1',
            orderId: 'order-1',
            shipmentId: 'shipment-1',
            packages: [{ packageNumber: 1, items: [{ orderItemId: 'item-1', quantity: 10 }] }],
          },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toThrow();
  });

  it('createShipment succeeds once invoiced, and is idempotent by shipmentId', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder({ organizationId: 'org-1', id: 'order-1', sellerId: 'rep-1', status: 'invoiced' });

    const wrapped = testEnv.wrap(createShipment);
    const request = buildRequest(
      {
        organizationId: 'org-1',
        companyId: 'company-1',
        orderId: 'order-1',
        shipmentId: 'shipment-1',
        packages: [{ packageNumber: 1, items: [{ orderItemId: 'item-1', quantity: 10 }] }],
      },
      authFor('rep-1'),
    );

    const first = (await wrapped(request)) as CreateShipmentResponse;
    const second = (await wrapped(request)) as CreateShipmentResponse;
    expect(first.shipmentId).toBe('shipment-1');
    expect(second.shipmentId).toBe('shipment-1');

    const snapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('shipments')
      .where('orderId', '==', 'order-1')
      .get();
    expect(snapshot.docs).toHaveLength(1);
  });

  it('registerTrackingEvent advances Order.status invoiced -> shipped -> delivered', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder({ organizationId: 'org-1', id: 'order-1', sellerId: 'rep-1', status: 'invoiced' });

    const createWrapped = testEnv.wrap(createShipment);
    await createWrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
          shipmentId: 'shipment-1',
          packages: [
            { packageNumber: 1, items: [{ orderItemId: 'item-1', quantity: 10 }, { orderItemId: 'item-2', quantity: 5 }] },
          ],
        },
        authFor('rep-1'),
      ),
    );

    const eventWrapped = testEnv.wrap(registerTrackingEvent);
    await eventWrapped(
      buildRequest(
        { organizationId: 'org-1', shipmentId: 'shipment-1', trackingEventId: 'event-shipped', type: 'shipped' },
        authFor('rep-1'),
      ),
    );

    let order = await db.collection('organizations').doc('org-1').collection('orders').doc('order-1').get();
    expect(order.data()?.status).toBe('shipped');

    await eventWrapped(
      buildRequest(
        { organizationId: 'org-1', shipmentId: 'shipment-1', trackingEventId: 'event-delivered', type: 'delivered' },
        authFor('rep-1'),
      ),
    );

    order = await db.collection('organizations').doc('org-1').collection('orders').doc('order-1').get();
    expect(order.data()?.status).toBe('delivered');
  });

  it('registerTrackingEvent is idempotent by trackingEventId (never applies the same event twice)', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder({ organizationId: 'org-1', id: 'order-1', sellerId: 'rep-1', status: 'invoiced' });

    const createWrapped = testEnv.wrap(createShipment);
    await createWrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
          shipmentId: 'shipment-1',
          packages: [{ packageNumber: 1, items: [{ orderItemId: 'item-1', quantity: 10 }] }],
        },
        authFor('rep-1'),
      ),
    );

    const eventWrapped = testEnv.wrap(registerTrackingEvent);
    const request = buildRequest(
      { organizationId: 'org-1', shipmentId: 'shipment-1', trackingEventId: 'event-shipped', type: 'shipped' },
      authFor('rep-1'),
    );

    const first = (await eventWrapped(request)) as RegisterTrackingEventResponse;
    const second = (await eventWrapped(request)) as RegisterTrackingEventResponse;
    expect(first.shipmentStatus).toBe('shipped');
    expect(second.shipmentStatus).toBe('shipped');

    const shipment = await db.collection('organizations').doc('org-1').collection('shipments').doc('shipment-1').get();
    // A retried delivery never re-applies its own side effects — `version`
    // only ever increments once for this one underlying event.
    expect(shipment.data()?.version).toBe(2); // 1 (create) + 1 (single applied event)
  });

  it('accumulates two partial deliveries with distinct items/quantities into a full delivery', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedOrder({ organizationId: 'org-1', id: 'order-1', sellerId: 'rep-1', status: 'invoiced' });

    const createWrapped = testEnv.wrap(createShipment);
    await createWrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
          shipmentId: 'shipment-1',
          packages: [
            { packageNumber: 1, items: [{ orderItemId: 'item-1', quantity: 10 }] },
            { packageNumber: 2, items: [{ orderItemId: 'item-2', quantity: 5 }] },
          ],
        },
        authFor('rep-1'),
      ),
    );

    const eventWrapped = testEnv.wrap(registerTrackingEvent);
    await eventWrapped(
      buildRequest(
        { organizationId: 'org-1', shipmentId: 'shipment-1', trackingEventId: 'event-shipped', type: 'shipped' },
        authFor('rep-1'),
      ),
    );

    const firstDelivery = (await eventWrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          shipmentId: 'shipment-1',
          trackingEventId: 'event-partial-1',
          type: 'partially_delivered',
          deliveredItems: [{ orderItemId: 'item-1', quantity: 10 }],
        },
        authFor('rep-1'),
      ),
    )) as RegisterTrackingEventResponse;
    expect(firstDelivery.shipmentStatus).toBe('partially_delivered');

    const secondDelivery = (await eventWrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          shipmentId: 'shipment-1',
          trackingEventId: 'event-partial-2',
          type: 'delivered',
          deliveredItems: [{ orderItemId: 'item-2', quantity: 5 }],
        },
        authFor('rep-1'),
      ),
    )) as RegisterTrackingEventResponse;
    expect(secondDelivery.shipmentStatus).toBe('delivered');

    const order = await db.collection('organizations').doc('org-1').collection('orders').doc('order-1').get();
    expect(order.data()?.status).toBe('delivered');
  });

  it('registerLogisticsIssue notifies a responsible different from the seller', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER');
    await seedOrder({ organizationId: 'org-1', id: 'order-1', sellerId: 'rep-1', status: 'invoiced' });

    const createWrapped = testEnv.wrap(createShipment);
    await createWrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
          shipmentId: 'shipment-1',
          packages: [{ packageNumber: 1, items: [{ orderItemId: 'item-1', quantity: 10 }] }],
        },
        authFor('rep-1'),
      ),
    );

    const issueWrapped = testEnv.wrap(registerLogisticsIssue);
    const response = (await issueWrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          shipmentId: 'shipment-1',
          logisticsIssueId: 'issue-1',
          type: 'delay',
          description: 'Atraso confirmado pela transportadora.',
          responsibleUserId: 'manager-1',
          nextAction: 'Contatar o cliente informando o novo prazo.',
        },
        authFor('rep-1'),
      ),
    )) as RegisterLogisticsIssueResponse;
    expect(response.status).toBe('open');

    const shipment = await db.collection('organizations').doc('org-1').collection('shipments').doc('shipment-1').get();
    expect(shipment.data()?.hasOpenIssue).toBe(true);

    const notifications = await db
      .collection('organizations')
      .doc('org-1')
      .collection('notifications')
      .where('userId', '==', 'manager-1')
      .get();
    expect(notifications.docs).toHaveLength(1);

    const resolveWrapped = testEnv.wrap(resolveLogisticsIssue);
    await resolveWrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          shipmentId: 'shipment-1',
          logisticsIssueId: 'issue-1',
          status: 'resolved',
          resolutionNote: 'Entrega concluída com atraso, cliente avisado.',
        },
        authFor('rep-1'),
      ),
    );

    const shipmentAfterResolution = await db
      .collection('organizations')
      .doc('org-1')
      .collection('shipments')
      .doc('shipment-1')
      .get();
    expect(shipmentAfterResolution.data()?.hasOpenIssue).toBe(false);
  });
});
