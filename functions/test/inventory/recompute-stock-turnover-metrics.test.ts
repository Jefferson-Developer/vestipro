import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';

import {
  recomputeStockTurnoverMetrics,
  type RecomputeStockTurnoverMetricsRequest,
  type RecomputeStockTurnoverMetricsResponse,
} from '../../src/inventory/recompute-stock-turnover-metrics';

const PROJECT_ID = 'demo-vestipro-stock-turnover-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: RecomputeStockTurnoverMetricsRequest,
  auth?: CallableRequest<RecomputeStockTurnoverMetricsRequest>['auth'],
): CallableRequest<RecomputeStockTurnoverMetricsRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<RecomputeStockTurnoverMetricsRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<RecomputeStockTurnoverMetricsRequest>['auth'] {
  return {
    uid,
    token,
    rawToken: 'raw-token',
  } as CallableRequest<RecomputeStockTurnoverMetricsRequest>['auth'];
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

async function seedFact(params: {
  id: string;
  dateAt: string;
  productId: string;
  variantId: string;
  collectionId: string;
  warehouseId: string;
  openingStockQuantity: number;
  receivedQuantity: number;
  soldQuantity: number;
  closingStockQuantity: number;
}): Promise<void> {
  await db
    .collection('organizations')
    .doc('org-1')
    .collection('stockTurnoverDailyFacts')
    .doc(params.id)
    .set({
      organizationId: 'org-1',
      dateAt: Timestamp.fromDate(new Date(`${params.dateAt}T00:00:00.000Z`)),
      productId: params.productId,
      variantId: params.variantId,
      collectionId: params.collectionId,
      warehouseId: params.warehouseId,
      openingStockQuantity: params.openingStockQuantity,
      receivedQuantity: params.receivedQuantity,
      soldQuantity: params.soldQuantity,
      closingStockQuantity: params.closingStockQuantity,
    });
}

describe('recomputeStockTurnoverMetrics', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('generates precomputed snapshots from simulated stock and sales facts', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'manager-1', 'SALES_MANAGER');
    await seedFact({
      id: 'fact-1',
      dateAt: '2026-08-01',
      productId: 'product-1',
      variantId: 'variant-1',
      collectionId: 'collection-1',
      warehouseId: 'warehouse-1',
      openingStockQuantity: 100,
      receivedQuantity: 20,
      soldQuantity: 30,
      closingStockQuantity: 90,
    });
    await seedFact({
      id: 'fact-2',
      dateAt: '2026-08-02',
      productId: 'product-1',
      variantId: 'variant-1',
      collectionId: 'collection-1',
      warehouseId: 'warehouse-1',
      openingStockQuantity: 90,
      receivedQuantity: 10,
      soldQuantity: 20,
      closingStockQuantity: 80,
    });

    const wrapped = testEnv.wrap(recomputeStockTurnoverMetrics);
    const response = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          periodStart: '2026-08-01',
          periodEnd: '2026-08-02',
        },
        authFor('manager-1'),
      ),
    )) as RecomputeStockTurnoverMetricsResponse;

    expect(response.generatedSnapshots).toBe(4);

    const metricSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('stockTurnoverMetrics')
      .doc('product_product-1_2026-08-01_2026-08-02')
      .get();

    expect(metricSnapshot.exists).toBe(true);
    expect(metricSnapshot.data()?.sellThroughRate).toBeCloseTo(0.3846, 4);
    expect(metricSnapshot.data()?.turnoverRate).toBeCloseTo(0.5556, 4);
    expect(metricSnapshot.data()?.stockCoverageDays).toBeCloseTo(3.2, 4);
    expect(metricSnapshot.data()?.coverageStatus).toBe('ready');
  });
});

