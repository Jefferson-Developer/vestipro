import { createHash } from 'node:crypto';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import { reviewCartShare } from '../../src/cart_shares/review-cart-share';

const PROJECT_ID = 'demo-vestipro-cart-share-review-test';
if (getApps().length === 0) initializeApp({ projectId: PROJECT_ID });
const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

describe('reviewCartShare (TASK-181)', () => {
  afterAll(async () => { testEnv.cleanup(); await db.terminate(); });

  it('reflects approval and notifies the seller without creating an order', async () => {
    const token = 'public-token';
    const now = Timestamp.now();
    const organization = db.collection('organizations').doc('org-1');
    await organization.set({ name: 'Moda' });
    const share = organization.collection('cartShares').doc('share-1');
    await share.set({
      tokenHash: createHash('sha256').update(token).digest('hex'),
      status: 'active', expiresAt: Timestamp.fromMillis(now.toMillis() + 60_000),
      createdBy: 'rep-1', sourceCartId: 'draft-1',
      items: [{ itemId: 'line-1' }], createdAt: now, updatedAt: now,
    });

    const wrapped = testEnv.wrap(reviewCartShare);
    await wrapped({
      data: { token, decision: 'approved' }, auth: undefined,
      rawRequest: {}, acceptsStreaming: false,
    } as CallableRequest<Record<string, unknown>>);

    expect((await share.get()).data()?.review.decision).toBe('approved');
    expect((await organization.collection('notifications').get()).size).toBe(1);
    expect((await organization.collection('orders').get()).empty).toBe(true);
  });
});
