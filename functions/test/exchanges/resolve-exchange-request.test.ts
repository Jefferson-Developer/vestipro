import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import { createExchangeRequest } from '../../src/exchanges/create-exchange-request';
import {
  resolveExchangeRequest,
  type ResolveExchangeRequestRequest,
  type ResolveExchangeRequestResponse,
} from '../../src/exchanges/resolve-exchange-request';

const PROJECT_ID = 'demo-vestipro-resolve-exchange-request-test';

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
  overrides: { teamIds?: string[] } = {},
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
      customerId: null,
      status: 'active',
      version: 1,
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
      deletedAt: null,
    });
}

async function seedCustomer(organizationId: string, customerId: string): Promise<void> {
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('customers')
    .doc(customerId)
    .set({ segment: 'varejo', status: 'active' });
}

async function seedPriceList(
  organizationId: string,
  companyId: string,
  priceListId: string,
  destinationPrice = 100,
): Promise<void> {
  const priceListRef = db
    .collection('organizations')
    .doc(organizationId)
    .collection('priceLists')
    .doc(priceListId);
  await priceListRef.set({
    organizationId,
    companyId,
    currency: 'BRL',
    status: 'active',
    validFrom: Timestamp.fromDate(new Date('2020-01-01')),
    validTo: null,
  });
  await priceListRef.collection('items').doc('item-destination').set({
    productId: 'product-1',
    variantId: 'variant-destination',
    companyId,
    price: destinationPrice,
  });
}

async function seedPaymentTerm(
  organizationId: string,
  companyId: string,
  paymentTermId: string,
): Promise<void> {
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('paymentTerms')
    .doc(paymentTermId)
    .set({
      organizationId,
      companyId,
      name: 'À vista',
      averageTermDays: 0,
      status: 'active',
      priceListIds: [],
    });
}

async function seedOrder(
  organizationId: string,
  companyId: string,
  orderId: string,
  overrides: { status?: string; sellerId?: string } = {},
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
      priceListId: 'price-list-1',
      paymentTermId: 'payment-term-1',
      status: overrides.status ?? 'delivered',
      items: [
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

async function getInventoryBalance(
  organizationId: string,
  variantId: string,
  warehouseId: string,
): Promise<number> {
  const snapshot = await db
    .collection('organizations')
    .doc(organizationId)
    .collection('inventory')
    .doc(`${variantId}_${warehouseId}`)
    .get();
  return (snapshot.data()?.physicalQuantity as number | undefined) ?? 0;
}

async function seedFullScenario(destinationPrice = 100): Promise<void> {
  await seedOrganization('org-1');
  await seedMember('org-1', 'rep-1', 'SALES_REP');
  await seedMember('org-1', 'manager-1', 'SALES_MANAGER', { teamIds: ['team-1'] });
  await seedCustomer('org-1', 'customer-1');
  await seedOrder('org-1', 'company-1', 'order-1');
  await seedPriceList('org-1', 'company-1', 'price-list-1', destinationPrice);
  await seedPaymentTerm('org-1', 'company-1', 'payment-term-1');
  await seedProductVariant('org-1', 'variant-destination', { productId: 'product-1' });
  await seedInventoryBalance('org-1', 'variant-destination', 'wh-2', 10);

  const createWrapped = testEnv.wrap(createExchangeRequest);
  await createWrapped(
    buildRequest(
      {
        organizationId: 'org-1',
        companyId: 'company-1',
        orderId: 'order-1',
        exchangeRequestId: 'exchange-1',
        reasonCategory: 'size_issue',
        items: [{ orderItemId: 'item-1', destinationVariantId: 'variant-destination', quantity: 2 }],
      },
      authFor('rep-1'),
    ),
  );
}

describe('resolveExchangeRequest', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('approves a troca: reintegrates the origin variant and debits the destination variant atomically', async () => {
    await seedFullScenario(100);
    const wrapped = testEnv.wrap(resolveExchangeRequest);

    const result = (await wrapped(
      buildRequest<ResolveExchangeRequestRequest>(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          exchangeRequestId: 'exchange-1',
          decision: 'approved',
        },
        authFor('manager-1'),
      ),
    )) as ResolveExchangeRequestResponse;

    expect(result.status).toBe('approved');
    // Same unit price at origin (100) and destination (100) => no difference.
    expect(result.priceDifferenceAmount).toBe(0);

    expect(await getInventoryBalance('org-1', 'variant-origin', 'wh-1')).toBe(2);
    expect(await getInventoryBalance('org-1', 'variant-destination', 'wh-2')).toBe(8);

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(
      auditSnapshot.docs.filter((doc) => doc.data().action === 'exchange.approved'),
    ).toHaveLength(1);
  });

  it('computes a positive price difference when the destination variant is more expensive', async () => {
    await seedFullScenario(150);
    const wrapped = testEnv.wrap(resolveExchangeRequest);

    const result = (await wrapped(
      buildRequest<ResolveExchangeRequestRequest>(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          exchangeRequestId: 'exchange-1',
          decision: 'approved',
        },
        authFor('manager-1'),
      ),
    )) as ResolveExchangeRequestResponse;

    // (150 - 100) * 2 units = 100.
    expect(result.priceDifferenceAmount).toBe(100);
  });

  it('blocks the approval when the destination variant is no longer available, without touching stock', async () => {
    await seedFullScenario(100);
    // Drains the destination balance between the solicitação and the aprovação.
    await db
      .collection('organizations')
      .doc('org-1')
      .collection('inventory')
      .doc('variant-destination_wh-2')
      .update({ physicalQuantity: 1 });
    const wrapped = testEnv.wrap(resolveExchangeRequest);

    await expect(
      wrapped(
        buildRequest<ResolveExchangeRequestRequest>(
          {
            organizationId: 'org-1',
            companyId: 'company-1',
            exchangeRequestId: 'exchange-1',
            decision: 'approved',
          },
          authFor('manager-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'failed-precondition' });

    expect(await getInventoryBalance('org-1', 'variant-origin', 'wh-1')).toBe(0);
    expect(await getInventoryBalance('org-1', 'variant-destination', 'wh-2')).toBe(1);

    const snapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('exchangeRequests')
      .doc('exchange-1')
      .get();
    expect(snapshot.data()?.status).toBe('requested');
  });

  it('rejects a troca without touching stock or pricing', async () => {
    await seedFullScenario(100);
    const wrapped = testEnv.wrap(resolveExchangeRequest);

    const result = (await wrapped(
      buildRequest<ResolveExchangeRequestRequest>(
        {
          organizationId: 'org-1',
          companyId: 'company-1',
          exchangeRequestId: 'exchange-1',
          decision: 'rejected',
          reason: 'Cliente desistiu da troca.',
        },
        authFor('manager-1'),
      ),
    )) as ResolveExchangeRequestResponse;

    expect(result.status).toBe('rejected');
    expect(result.priceDifferenceAmount).toBeUndefined();
    expect(await getInventoryBalance('org-1', 'variant-origin', 'wh-1')).toBe(0);
    expect(await getInventoryBalance('org-1', 'variant-destination', 'wh-2')).toBe(10);
  });

  it('requires a reason to reject a troca', async () => {
    await seedFullScenario(100);
    const wrapped = testEnv.wrap(resolveExchangeRequest);

    await expect(
      wrapped(
        buildRequest<ResolveExchangeRequestRequest>(
          {
            organizationId: 'org-1',
            companyId: 'company-1',
            exchangeRequestId: 'exchange-1',
            decision: 'rejected',
          },
          authFor('manager-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('denies a SALES_REP (no exchange.approve) from deciding a troca', async () => {
    await seedFullScenario(100);
    const wrapped = testEnv.wrap(resolveExchangeRequest);

    await expect(
      wrapped(
        buildRequest<ResolveExchangeRequestRequest>(
          {
            organizationId: 'org-1',
            companyId: 'company-1',
            exchangeRequestId: 'exchange-1',
            decision: 'approved',
          },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('replays the exact same decision for a retried call', async () => {
    await seedFullScenario(100);
    const wrapped = testEnv.wrap(resolveExchangeRequest);
    const request = buildRequest<ResolveExchangeRequestRequest>(
      {
        organizationId: 'org-1',
        companyId: 'company-1',
        exchangeRequestId: 'exchange-1',
        decision: 'approved',
      },
      authFor('manager-1'),
    );

    const first = (await wrapped(request)) as ResolveExchangeRequestResponse;
    const second = (await wrapped(request)) as ResolveExchangeRequestResponse;

    expect(second).toEqual(first);
    expect(await getInventoryBalance('org-1', 'variant-destination', 'wh-2')).toBe(8);
  });
});
