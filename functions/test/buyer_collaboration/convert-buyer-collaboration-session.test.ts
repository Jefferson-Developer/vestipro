import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import { convertBuyerCollaborationSession } from '../../src/buyer_collaboration/convert-buyer-collaboration-session';

/**
 * TASK-211: "toda alteração proposta precisa ser revalidada contra preço
 * [...] no momento da conversão" — a `buyer_approved` session whose captured
 * `unitPrice` no longer matches the live price list must be blocked (or, if
 * the seller explicitly accepts the drift, still converted, but the drift is
 * always reported back).
 */

const PROJECT_ID = 'demo-vestipro-buyer-collaboration-convert-test';
if (getApps().length === 0) initializeApp({ projectId: PROJECT_ID });
const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

const ORG_ID = 'org-1';
const CUSTOMER_ID = 'customer-1';
const SELLER_UID = 'rep-1';
const SESSION_ID = 'session-1';
const ORDER_ID = 'order-1';

function buildRequest<T>(data: T, auth?: CallableRequest<T>['auth']): CallableRequest<T> {
  return { data, auth, rawRequest: {} as CallableRequest<T>['rawRequest'], acceptsStreaming: false };
}

function authFor(uid: string): CallableRequest<Record<string, unknown>>['auth'] {
  return { uid, token: {}, rawToken: 'raw-token' } as CallableRequest<Record<string, unknown>>['auth'];
}

async function clearFirestore(): Promise<void> {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
}

async function seedApprovedSession(approvedUnitPrice: number): Promise<void> {
  const now = Timestamp.now();
  await db.collection('organizations').doc(ORG_ID).set({ name: 'Moda XPTO' });
  await db.collection('organizations').doc(ORG_ID).collection('members').doc(SELLER_UID).set({
    organizationId: ORG_ID,
    roleName: 'SALES_REP',
    teamIds: [],
    status: 'active',
  });
  await db
    .collection('organizations')
    .doc(ORG_ID)
    .collection('buyerCollaborationSessions')
    .doc(SESSION_ID)
    .set({
      organizationId: ORG_ID,
      companyId: 'company-1',
      sellerId: SELLER_UID,
      customerId: CUSTOMER_ID,
      sourceType: 'orderDraft',
      sourceId: 'draft-1',
      priceListId: 'price-list-1',
      status: 'buyer_approved',
      items: [
        {
          itemId: 'line-1',
          productId: 'product-1',
          productName: 'Vestido Floral',
          variantId: 'variant-1',
          quantity: 10,
          unitPrice: approvedUnitPrice,
          subtotal: approvedUnitPrice * 10,
        },
      ],
      showPrices: true,
      currentTotal: approvedUnitPrice * 10,
      convertedOrderId: null,
      createdBy: SELLER_UID,
      createdAt: now,
      updatedAt: now,
      lastActivityAt: now,
      expiresAt: Timestamp.fromMillis(now.toMillis() + 60 * 60 * 1000),
    });
  await db
    .collection('organizations')
    .doc(ORG_ID)
    .collection('priceLists')
    .doc('price-list-1')
    .collection('items')
    .doc('item-1')
    .set({ productId: 'product-1', variantId: 'variant-1', companyId: 'company-1', price: 100 });
  await db.collection('organizations').doc(ORG_ID).collection('orders').doc(ORDER_ID).set({
    organizationId: ORG_ID,
    companyId: 'company-1',
    customerId: CUSTOMER_ID,
    sellerId: SELLER_UID,
    orderNumber: '000001',
    deletedAt: null,
  });
}

describe('convertBuyerCollaborationSession price revalidation (TASK-211)', () => {
  beforeEach(clearFirestore);
  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('converts straight away when the current price list still matches what the buyer approved', async () => {
    await seedApprovedSession(100);
    const result = (await testEnv.wrap(convertBuyerCollaborationSession)(
      buildRequest(
        { organizationId: ORG_ID, sessionId: SESSION_ID, orderId: ORDER_ID },
        authFor(SELLER_UID),
      ),
    )) as { converted: boolean; priceDrift: unknown[] };
    expect(result.converted).toBe(true);
    expect(result.priceDrift).toHaveLength(0);
  });

  it('blocks conversion and reports the drift when the price list changed since approval', async () => {
    await seedApprovedSession(80); // buyer approved at 80, price list now says 100.
    const result = (await testEnv.wrap(convertBuyerCollaborationSession)(
      buildRequest(
        { organizationId: ORG_ID, sessionId: SESSION_ID, orderId: ORDER_ID },
        authFor(SELLER_UID),
      ),
    )) as {
      converted: boolean;
      priceDrift: Array<{ variantId: string; approvedUnitPrice: number; currentUnitPrice: number | null }>;
    };
    expect(result.converted).toBe(false);
    expect(result.priceDrift).toEqual([
      expect.objectContaining({ variantId: 'variant-1', approvedUnitPrice: 80, currentUnitPrice: 100 }),
    ]);
    const sessionAfter = await db
      .collection('organizations')
      .doc(ORG_ID)
      .collection('buyerCollaborationSessions')
      .doc(SESSION_ID)
      .get();
    expect(sessionAfter.data()?.status).toBe('buyer_approved');
    expect(sessionAfter.data()?.convertedOrderId).toBeNull();
  });

  it('converts anyway once the seller explicitly accepts the reported drift', async () => {
    await seedApprovedSession(80);
    const result = (await testEnv.wrap(convertBuyerCollaborationSession)(
      buildRequest(
        {
          organizationId: ORG_ID,
          sessionId: SESSION_ID,
          orderId: ORDER_ID,
          acceptPriceDrift: true,
        },
        authFor(SELLER_UID),
      ),
    )) as { converted: boolean };
    expect(result.converted).toBe(true);
    const sessionAfter = await db
      .collection('organizations')
      .doc(ORG_ID)
      .collection('buyerCollaborationSessions')
      .doc(SESSION_ID)
      .get();
    expect(sessionAfter.data()?.status).toBe('converted_to_order');
    expect(sessionAfter.data()?.convertedOrderId).toBe(ORDER_ID);
  });

  it('refuses to link an order that does not belong to the same customer', async () => {
    await seedApprovedSession(100);
    await db.collection('organizations').doc(ORG_ID).collection('orders').doc(ORDER_ID).set({
      organizationId: ORG_ID,
      companyId: 'company-1',
      customerId: 'someone-else',
      sellerId: SELLER_UID,
      orderNumber: '000002',
      deletedAt: null,
    });
    await expect(
      testEnv.wrap(convertBuyerCollaborationSession)(
        buildRequest(
          { organizationId: ORG_ID, sessionId: SESSION_ID, orderId: ORDER_ID },
          authFor(SELLER_UID),
        ),
      ),
    ).rejects.toThrow(/não pertence a esta sessão/);
  });

  it('refuses to convert a session that is not yet buyer_approved', async () => {
    await seedApprovedSession(100);
    await db
      .collection('organizations')
      .doc(ORG_ID)
      .collection('buyerCollaborationSessions')
      .doc(SESSION_ID)
      .set({ status: 'buyer_review' }, { merge: true });
    await expect(
      testEnv.wrap(convertBuyerCollaborationSession)(
        buildRequest(
          { organizationId: ORG_ID, sessionId: SESSION_ID, orderId: ORDER_ID },
          authFor(SELLER_UID),
        ),
      ),
    ).rejects.toThrow(/aprovada pelo comprador/);
  });
});
