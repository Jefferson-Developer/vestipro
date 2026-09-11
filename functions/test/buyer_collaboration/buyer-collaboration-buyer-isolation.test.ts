import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import { createBuyerCollaborationSession } from '../../src/buyer_collaboration/create-buyer-collaboration-session';
import { shareBuyerCollaborationSession } from '../../src/buyer_collaboration/share-buyer-collaboration-session';
import { approveBuyerCollaborationSession } from '../../src/buyer_collaboration/approve-buyer-collaboration-session';
import { addBuyerCollaborationComment } from '../../src/buyer_collaboration/add-buyer-collaboration-comment';

/**
 * TASK-211's own "comprador externo só acessa sessões vinculadas ao próprio
 * customerId" — exercised here at the callable layer (every mutating action
 * re-derives the caller's `customerId` from their real CUSTOMER_PORTAL
 * Membership, `assertBuyerCanAct`, never trusting the client). The
 * read-only, Firestore-direct side of this same guarantee
 * (`canReadBuyerCollaborationSession`/`canReadBuyerCollaborationComment` in
 * `firestore.rules`) is covered separately by
 * `firestore-tests/firestore.rules.test.js`.
 */

const PROJECT_ID = 'demo-vestipro-buyer-collaboration-isolation-test';
if (getApps().length === 0) initializeApp({ projectId: PROJECT_ID });
const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

const ORG_ID = 'org-1';
const CUSTOMER_A = 'customer-a';
const CUSTOMER_B = 'customer-b';
const SELLER_UID = 'rep-1';
const BUYER_A_UID = 'portal-a';
const BUYER_B_UID = 'portal-b';

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

describe('buyer_collaboration external buyer isolation (TASK-211)', () => {
  let sessionId: string;

  beforeEach(async () => {
    await clearFirestore();
    await db.collection('organizations').doc(ORG_ID).set({ name: 'Moda XPTO' });
    await db.collection('organizations').doc(ORG_ID).collection('members').doc(SELLER_UID).set({
      organizationId: ORG_ID,
      roleName: 'SALES_REP',
      teamIds: [],
      status: 'active',
    });
    await db.collection('organizations').doc(ORG_ID).collection('members').doc(BUYER_A_UID).set({
      organizationId: ORG_ID,
      roleName: 'CUSTOMER_PORTAL',
      teamIds: [],
      status: 'active',
      customerId: CUSTOMER_A,
    });
    await db.collection('organizations').doc(ORG_ID).collection('members').doc(BUYER_B_UID).set({
      organizationId: ORG_ID,
      roleName: 'CUSTOMER_PORTAL',
      teamIds: [],
      status: 'active',
      customerId: CUSTOMER_B,
    });
    await db.collection('organizations').doc(ORG_ID).collection('customers').doc(CUSTOMER_A).set({
      organizationId: ORG_ID,
      companyId: 'company-1',
      status: 'active',
    });

    const created = (await testEnv.wrap(createBuyerCollaborationSession)(
      buildRequest(
        {
          organizationId: ORG_ID,
          companyId: 'company-1',
          customerId: CUSTOMER_A,
          priceListId: 'price-list-1',
          sourceType: 'orderDraft',
          sourceId: 'draft-1',
          items: [
            {
              itemId: 'line-1',
              productId: 'product-1',
              productName: 'Vestido Floral',
              variantId: 'variant-1',
              quantity: 5,
              unitPrice: 100,
            },
          ],
          showPrices: true,
        },
        authFor(SELLER_UID),
      ),
    )) as { sessionId: string };
    sessionId = created.sessionId;
    await testEnv.wrap(shareBuyerCollaborationSession)(
      buildRequest({ organizationId: ORG_ID, sessionId }, authFor(SELLER_UID)),
    );
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it("customer A's own portal user can approve the session", async () => {
    await expect(
      testEnv.wrap(approveBuyerCollaborationSession)(
        buildRequest({ organizationId: ORG_ID, sessionId }, authFor(BUYER_A_UID)),
      ),
    ).resolves.toMatchObject({ status: 'buyer_approved' });
  });

  it("customer B's portal user cannot approve customer A's session", async () => {
    await expect(
      testEnv.wrap(approveBuyerCollaborationSession)(
        buildRequest({ organizationId: ORG_ID, sessionId }, authFor(BUYER_B_UID)),
      ),
    ).rejects.toThrow(/pertence a outro cliente/);
  });

  it("customer B's portal user cannot comment on customer A's session", async () => {
    await expect(
      testEnv.wrap(addBuyerCollaborationComment)(
        buildRequest(
          { organizationId: ORG_ID, sessionId, body: 'Tentando comentar em sessão alheia.' },
          authFor(BUYER_B_UID),
        ),
      ),
    ).rejects.toThrow(/pertence a outro cliente/);
  });

  it('an unauthenticated caller cannot approve any session', async () => {
    await expect(
      testEnv.wrap(approveBuyerCollaborationSession)(
        buildRequest({ organizationId: ORG_ID, sessionId }, undefined),
      ),
    ).rejects.toThrow();
  });
});
