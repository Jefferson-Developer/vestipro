import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';

import {
  recomputeMonthlyAggregates,
  type RecomputeMonthlyAggregatesRequest,
  type RecomputeMonthlyAggregatesResponse,
} from '../../src/aggregations/recompute-monthly-aggregates';

/**
 * Firebase Emulator Suite test — same shape as
 * `functions/test/inventory/recompute-stock-turnover-metrics.test.ts`
 * (TASK-094): exercises the real `onCall` against a real Firestore
 * Emulator instance (RBAC, idempotent recompute, multi-tenant isolation).
 * Requires `firebase emulators:start`/`emulators:exec` with Java available
 * — see this suite's own `recompute-monthly-aggregates-CONCLUIDA.md` note
 * if this fails with "Could not spawn `java -version`" in a sandboxed
 * environment; that is a pre-existing environment limitation, not specific
 * to this test.
 */
const PROJECT_ID = 'demo-vestipro-monthly-aggregates-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: RecomputeMonthlyAggregatesRequest,
  auth?: CallableRequest<RecomputeMonthlyAggregatesRequest>['auth'],
): CallableRequest<RecomputeMonthlyAggregatesRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<RecomputeMonthlyAggregatesRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<RecomputeMonthlyAggregatesRequest>['auth'] {
  return {
    uid,
    token,
    rawToken: 'raw-token',
  } as CallableRequest<RecomputeMonthlyAggregatesRequest>['auth'];
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

async function seedOrder(
  organizationId: string,
  orderId: string,
  params: {
    companyId: string;
    customerId: string;
    sellerId: string;
    createdAt: string;
    itemsSubtotal: number;
    status?: string;
    state?: string;
  },
): Promise<void> {
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('orders')
    .doc(orderId)
    .set({
      organizationId,
      companyId: params.companyId,
      customerId: params.customerId,
      sellerId: params.sellerId,
      status: params.status ?? 'submitted',
      createdAt: Timestamp.fromDate(new Date(params.createdAt)),
      deletedAt: null,
      deliveryAddress: { state: params.state ?? 'SC' },
      discountAmount: 0,
      surchargeAmount: 0,
      shippingAmount: 0,
      items: [
        {
          productId: 'product-1',
          quantity: 1,
          subtotal: params.itemsSubtotal,
        },
      ],
    });
}

describe('recomputeMonthlyAggregates (Firebase Emulator)', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('generates monthly snapshots from real orders and recomputing again does not duplicate them (idempotent)', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER');
    await seedOrder('org-1', 'order-1', {
      companyId: 'company-1',
      customerId: 'customer-1',
      sellerId: 'seller-1',
      createdAt: '2026-08-05T10:00:00.000Z',
      itemsSubtotal: 1000,
    });
    await seedOrder('org-1', 'order-2', {
      companyId: 'company-1',
      customerId: 'customer-1',
      sellerId: 'seller-1',
      createdAt: '2026-08-20T10:00:00.000Z',
      itemsSubtotal: 500,
    });

    const wrapped = testEnv.wrap(recomputeMonthlyAggregates);
    const response = (await wrapped(
      buildRequest(
        { organizationId: 'org-1', companyId: 'company-1', monthKey: '2026-08' },
        authFor('manager-1'),
      ),
    )) as RecomputeMonthlyAggregatesResponse;

    expect(response.generatedSnapshots).toBeGreaterThan(0);

    const customerSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('customerMonthlyAggregates')
      .doc('company-1_customer-1_2026-08')
      .get();
    expect(customerSnapshot.exists).toBe(true);
    expect(customerSnapshot.data()?.revenueGross).toBeCloseTo(1500, 2);
    expect(customerSnapshot.data()?.orderCount).toBe(2);

    // Reprocessing the same month must not duplicate/corrupt the snapshot.
    await wrapped(
      buildRequest(
        { organizationId: 'org-1', companyId: 'company-1', monthKey: '2026-08' },
        authFor('manager-1'),
      ),
    );
    const allDocs = await db
      .collection('organizations')
      .doc('org-1')
      .collection('customerMonthlyAggregates')
      .get();
    expect(allDocs.size).toBe(1);
  });

  it('never mixes orders from a different organization into the recomputed snapshot', async () => {
    await seedOrganization('org-1');
    await seedOrganization('org-2');
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER');
    await seedOrder('org-1', 'order-1', {
      companyId: 'company-1',
      customerId: 'customer-1',
      sellerId: 'seller-1',
      createdAt: '2026-08-05T10:00:00.000Z',
      itemsSubtotal: 1000,
    });
    await seedOrder('org-2', 'order-2', {
      companyId: 'company-1',
      customerId: 'customer-1',
      sellerId: 'seller-1',
      createdAt: '2026-08-05T10:00:00.000Z',
      itemsSubtotal: 999999,
    });

    const wrapped = testEnv.wrap(recomputeMonthlyAggregates);
    await wrapped(
      buildRequest(
        { organizationId: 'org-1', companyId: 'company-1', monthKey: '2026-08' },
        authFor('manager-1'),
      ),
    );

    const customerSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('customerMonthlyAggregates')
      .doc('company-1_customer-1_2026-08')
      .get();
    expect(customerSnapshot.data()?.revenueGross).toBeCloseTo(1000, 2);

    const org2Snapshot = await db
      .collection('organizations')
      .doc('org-2')
      .collection('customerMonthlyAggregates')
      .doc('company-1_customer-1_2026-08')
      .get();
    expect(org2Snapshot.exists).toBe(false);
  });

  it('a month with zero orders produces zero snapshots', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER');

    const wrapped = testEnv.wrap(recomputeMonthlyAggregates);
    const response = (await wrapped(
      buildRequest(
        { organizationId: 'org-1', companyId: 'company-1', monthKey: '2026-08' },
        authFor('manager-1'),
      ),
    )) as RecomputeMonthlyAggregatesResponse;

    expect(response.generatedSnapshots).toBe(0);
  });

  it('rejects a caller without OWNER/ADMIN/SALES_MANAGER role', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'assistant-1', 'SALES_ASSISTANT');

    const wrapped = testEnv.wrap(recomputeMonthlyAggregates);
    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', companyId: 'company-1', monthKey: '2026-08' },
          authFor('assistant-1'),
        ),
      ),
    ).rejects.toThrow();
  });
});
