import { createHash } from 'node:crypto';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  registerCatalogShareOpen,
  type RegisterCatalogShareOpenRequest,
  type RegisterCatalogShareOpenResponse,
} from '../../src/catalog/register-catalog-share-open';

const PROJECT_ID = 'demo-vestipro-catalog-share-open-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: RegisterCatalogShareOpenRequest,
): CallableRequest<RegisterCatalogShareOpenRequest> {
  return {
    data,
    auth: undefined,
    rawRequest: {} as CallableRequest<RegisterCatalogShareOpenRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

async function clearFirestore(): Promise<void> {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
}

async function seedShare(
  organizationId: string,
  shareId: string,
  token: string,
  overrides: Record<string, unknown> = {},
): Promise<void> {
  const now = Timestamp.now();
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('catalogShares')
    .doc(shareId)
    .set({
      organizationId,
      scope: 'product',
      items: [{ productId: 'product-1', name: 'Camisa Linho', imageUrl: null }],
      collectionId: null,
      collectionName: null,
      tokenHash: hashToken(token),
      status: 'active',
      openCount: 0,
      firstOpenedAt: null,
      lastOpenedAt: null,
      expiresAt: Timestamp.fromMillis(now.toMillis() + 30 * 24 * 60 * 60 * 1000),
      createdBy: 'rep-1',
      createdByName: 'Rep Um',
      createdAt: now,
      updatedAt: now,
      ...overrides,
    });
}

describe('registerCatalogShareOpen', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('increments openCount and sets first/lastOpenedAt on the first open', async () => {
    await seedShare('org-1', 'share-1', 'token-1');
    const wrapped = testEnv.wrap(registerCatalogShareOpen);

    const result = (await wrapped(
      buildRequest({ token: 'token-1' }),
    )) as RegisterCatalogShareOpenResponse;
    expect(result.recorded).toBe(true);

    const snapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('catalogShares')
      .doc('share-1')
      .get();
    const data = snapshot.data()!;
    expect(data.openCount).toBe(1);
    expect(data.firstOpenedAt).not.toBeNull();
    expect(data.lastOpenedAt).not.toBeNull();
  });

  it('increments openCount again without changing firstOpenedAt on a second open', async () => {
    await seedShare('org-1', 'share-1', 'token-1');
    const wrapped = testEnv.wrap(registerCatalogShareOpen);

    await wrapped(buildRequest({ token: 'token-1' }));
    const firstSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('catalogShares')
      .doc('share-1')
      .get();
    const firstOpenedAt = firstSnapshot.data()!.firstOpenedAt;

    await wrapped(buildRequest({ token: 'token-1' }));
    const secondSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('catalogShares')
      .doc('share-1')
      .get();
    const data = secondSnapshot.data()!;
    expect(data.openCount).toBe(2);
    expect(data.firstOpenedAt).toEqual(firstOpenedAt);
  });

  it('does not record and does not throw for an unknown token', async () => {
    const wrapped = testEnv.wrap(registerCatalogShareOpen);

    const result = (await wrapped(
      buildRequest({ token: 'never-issued' }),
    )) as RegisterCatalogShareOpenResponse;
    expect(result.recorded).toBe(false);
  });

  it('does not record and does not throw for a revoked share', async () => {
    await seedShare('org-1', 'share-1', 'token-1', { status: 'revoked' });
    const wrapped = testEnv.wrap(registerCatalogShareOpen);

    const result = (await wrapped(
      buildRequest({ token: 'token-1' }),
    )) as RegisterCatalogShareOpenResponse;
    expect(result.recorded).toBe(false);

    const snapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('catalogShares')
      .doc('share-1')
      .get();
    expect(snapshot.data()!.openCount).toBe(0);
  });

  it('does not record and does not throw for an expired share', async () => {
    await seedShare('org-1', 'share-1', 'token-1', {
      expiresAt: Timestamp.fromMillis(Date.now() - 60_000),
    });
    const wrapped = testEnv.wrap(registerCatalogShareOpen);

    const result = (await wrapped(
      buildRequest({ token: 'token-1' }),
    )) as RegisterCatalogShareOpenResponse;
    expect(result.recorded).toBe(false);
  });

  it('never throws even for a missing token', async () => {
    const wrapped = testEnv.wrap(registerCatalogShareOpen);

    const result = (await wrapped(
      buildRequest({}),
    )) as RegisterCatalogShareOpenResponse;
    expect(result.recorded).toBe(false);
  });
});
