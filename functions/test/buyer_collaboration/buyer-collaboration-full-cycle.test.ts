import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import { createBuyerCollaborationSession } from '../../src/buyer_collaboration/create-buyer-collaboration-session';
import { shareBuyerCollaborationSession } from '../../src/buyer_collaboration/share-buyer-collaboration-session';
import { addBuyerCollaborationComment } from '../../src/buyer_collaboration/add-buyer-collaboration-comment';
import { requestBuyerCollaborationChanges } from '../../src/buyer_collaboration/request-buyer-collaboration-changes';
import { approveBuyerCollaborationSession } from '../../src/buyer_collaboration/approve-buyer-collaboration-session';
import { convertBuyerCollaborationSession } from '../../src/buyer_collaboration/convert-buyer-collaboration-session';

const PROJECT_ID = 'demo-vestipro-buyer-collaboration-full-cycle-test';
if (getApps().length === 0) initializeApp({ projectId: PROJECT_ID });
const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

const ORG_ID = 'org-1';
const CUSTOMER_ID = 'customer-1';
const SELLER_UID = 'rep-1';
const BUYER_UID = 'portal-1';

function buildRequest<T>(
  data: T,
  auth?: CallableRequest<T>['auth'],
): CallableRequest<T> {
  return { data, auth, rawRequest: {} as CallableRequest<T>['rawRequest'], acceptsStreaming: false };
}

function authFor(uid: string): CallableRequest<Record<string, unknown>>['auth'] {
  return { uid, token: {}, rawToken: 'raw-token' } as CallableRequest<Record<string, unknown>>['auth'];
}

async function clearFirestore(): Promise<void> {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
}

async function seedOrganization(): Promise<void> {
  await db.collection('organizations').doc(ORG_ID).set({ name: 'Moda XPTO' });
}

async function seedMember(
  uid: string,
  roleName: string,
  customerId?: string,
): Promise<void> {
  await db
    .collection('organizations')
    .doc(ORG_ID)
    .collection('members')
    .doc(uid)
    .set({
      organizationId: ORG_ID,
      userId: uid,
      roleName,
      teamIds: [],
      status: 'active',
      ...(customerId ? { customerId } : {}),
    });
}

async function seedCustomer(): Promise<void> {
  await db.collection('organizations').doc(ORG_ID).collection('customers').doc(CUSTOMER_ID).set({
    organizationId: ORG_ID,
    companyId: 'company-1',
    status: 'active',
  });
}

function baseItems() {
  return [
    {
      itemId: 'line-1',
      productId: 'product-1',
      productName: 'Vestido Floral',
      variantId: 'variant-1',
      quantity: 10,
      unitPrice: 100,
    },
  ];
}

describe('buyer_collaboration full cycle (TASK-211)', () => {
  beforeEach(async () => {
    await clearFirestore();
    await seedOrganization();
    await seedMember(SELLER_UID, 'SALES_REP');
    await seedMember(BUYER_UID, 'CUSTOMER_PORTAL', CUSTOMER_ID);
    await seedCustomer();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('walks seller_draft -> buyer_review -> changes_requested -> buyer_review -> buyer_approved -> converted_to_order, recording comments and notifications along the way', async () => {
    const create = testEnv.wrap(createBuyerCollaborationSession);
    const createResult = (await create(
      buildRequest(
        {
          organizationId: ORG_ID,
          companyId: 'company-1',
          customerId: CUSTOMER_ID,
          priceListId: 'price-list-1',
          sourceType: 'orderDraft',
          sourceId: 'draft-1',
          items: baseItems(),
          showPrices: true,
        },
        authFor(SELLER_UID),
      ),
    )) as { sessionId: string; status: string };
    expect(createResult.status).toBe('seller_draft');
    const sessionId = createResult.sessionId;
    const sessionRef = db
      .collection('organizations')
      .doc(ORG_ID)
      .collection('buyerCollaborationSessions')
      .doc(sessionId);

    // Buyer cannot see/act on it before it is shared.
    await expect(
      testEnv.wrap(approveBuyerCollaborationSession)(
        buildRequest({ organizationId: ORG_ID, sessionId }, authFor(BUYER_UID)),
      ),
    ).rejects.toThrow();

    const share = testEnv.wrap(shareBuyerCollaborationSession);
    await share(
      buildRequest({ organizationId: ORG_ID, sessionId }, authFor(SELLER_UID)),
    );
    expect((await sessionRef.get()).data()?.status).toBe('buyer_review');

    const addComment = testEnv.wrap(addBuyerCollaborationComment);
    await addComment(
      buildRequest(
        {
          organizationId: ORG_ID,
          sessionId,
          body: 'Consegue 15 peças da variante 1?',
        },
        authFor(BUYER_UID),
      ),
    );
    const commentsAfterBuyerComment = await sessionRef.collection('comments').get();
    expect(commentsAfterBuyerComment.size).toBe(1);
    expect(commentsAfterBuyerComment.docs[0]!.data().authorType).toBe('buyer');

    const requestChanges = testEnv.wrap(requestBuyerCollaborationChanges);
    await requestChanges(
      buildRequest(
        {
          organizationId: ORG_ID,
          sessionId,
          comment: 'Preciso de 15 unidades em vez de 10.',
          proposedChanges: [
            { itemId: 'line-1', action: 'update', requestedQuantity: 15 },
          ],
        },
        authFor(BUYER_UID),
      ),
    );
    expect((await sessionRef.get()).data()?.status).toBe('changes_requested');
    const sellerNotificationsAfterChangeRequest = await db
      .collection('organizations')
      .doc(ORG_ID)
      .collection('notifications')
      .where('userId', '==', SELLER_UID)
      .get();
    expect(sellerNotificationsAfterChangeRequest.size).toBeGreaterThanOrEqual(1);
    expect(
      sellerNotificationsAfterChangeRequest.docs.some((doc) =>
        (doc.data().deepLink as string).includes(`/org/${ORG_ID}/buyer-collaboration/${sessionId}`),
      ),
    ).toBe(true);

    // Seller revises the item quantity and re-shares.
    await share(
      buildRequest(
        {
          organizationId: ORG_ID,
          sessionId,
          items: [{ ...baseItems()[0], quantity: 15 }],
          note: 'Consegui liberar as 15 peças.',
        },
        authFor(SELLER_UID),
      ),
    );
    const revisedSession = await sessionRef.get();
    expect(revisedSession.data()?.status).toBe('buyer_review');
    expect(revisedSession.data()?.items[0].quantity).toBe(15);
    const buyerNotificationsAfterRevision = await db
      .collection('organizations')
      .doc(ORG_ID)
      .collection('notifications')
      .where('userId', '==', BUYER_UID)
      .get();
    expect(
      buyerNotificationsAfterRevision.docs.some((doc) =>
        (doc.data().deepLink as string).includes(`/customer-portal/${ORG_ID}/collaboration/${sessionId}`),
      ),
    ).toBe(true);

    const approve = testEnv.wrap(approveBuyerCollaborationSession);
    await approve(
      buildRequest({ organizationId: ORG_ID, sessionId }, authFor(BUYER_UID)),
    );
    expect((await sessionRef.get()).data()?.status).toBe('buyer_approved');

    // Seller submits the order through the normal order flow (out of this
    // feature's scope — simulated here as an already-existing Order with a
    // price matching the price list at conversion time), then converts.
    const orderId = 'order-1';
    await db.collection('organizations').doc(ORG_ID).collection('priceLists').doc('price-list-1').collection('items').doc('item-1').set({
      productId: 'product-1',
      variantId: 'variant-1',
      companyId: 'company-1',
      price: 100,
    });
    await db.collection('organizations').doc(ORG_ID).collection('orders').doc(orderId).set({
      organizationId: ORG_ID,
      companyId: 'company-1',
      customerId: CUSTOMER_ID,
      sellerId: SELLER_UID,
      orderNumber: '000001',
      deletedAt: null,
    });

    const convert = testEnv.wrap(convertBuyerCollaborationSession);
    const conversionResult = (await convert(
      buildRequest(
        { organizationId: ORG_ID, sessionId, orderId },
        authFor(SELLER_UID),
      ),
    )) as { converted: boolean; orderId?: string };
    expect(conversionResult.converted).toBe(true);
    expect(conversionResult.orderId).toBe(orderId);
    const convertedSession = await sessionRef.get();
    expect(convertedSession.data()?.status).toBe('converted_to_order');
    expect(convertedSession.data()?.convertedOrderId).toBe(orderId);

    const allComments = await sessionRef.collection('comments').orderBy('createdAt').get();
    // buyer comment, changes_requested, revision note, system approve, system convert.
    expect(allComments.size).toBeGreaterThanOrEqual(5);
  });

  it('rejects a SALES_ASSISTANT trying to act as the seller side', async () => {
    await seedMember('assistant-1', 'SALES_ASSISTANT');
    const create = testEnv.wrap(createBuyerCollaborationSession);
    await expect(
      create(
        buildRequest(
          {
            organizationId: ORG_ID,
            companyId: 'company-1',
            customerId: CUSTOMER_ID,
            priceListId: 'price-list-1',
            sourceType: 'orderDraft',
            sourceId: 'draft-1',
            items: baseItems(),
            showPrices: true,
          },
          authFor('assistant-1'),
        ),
      ),
    ).rejects.toThrow();
  });
});
