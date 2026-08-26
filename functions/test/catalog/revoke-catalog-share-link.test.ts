import { createHash } from 'node:crypto';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  revokeCatalogShareLink,
  type RevokeCatalogShareLinkRequest,
  type RevokeCatalogShareLinkResponse,
} from '../../src/catalog/revoke-catalog-share-link';

const PROJECT_ID = 'demo-vestipro-catalog-share-revoke-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: RevokeCatalogShareLinkRequest,
  auth?: CallableRequest<RevokeCatalogShareLinkRequest>['auth'],
): CallableRequest<RevokeCatalogShareLinkRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<RevokeCatalogShareLinkRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
): CallableRequest<RevokeCatalogShareLinkRequest>['auth'] {
  return { uid, token: {}, rawToken: 'raw-token' } as CallableRequest<RevokeCatalogShareLinkRequest>['auth'];
}

function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

async function clearFirestore(): Promise<void> {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
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
    });
}

async function seedShare(
  organizationId: string,
  shareId: string,
  createdBy: string,
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
      tokenHash: hashToken('token-1'),
      status: 'active',
      openCount: 0,
      firstOpenedAt: null,
      lastOpenedAt: null,
      expiresAt: Timestamp.fromMillis(now.toMillis() + 30 * 24 * 60 * 60 * 1000),
      createdBy,
      createdByName: 'Rep Um',
      createdAt: now,
      updatedAt: now,
      ...overrides,
    });
}

describe('revokeCatalogShareLink', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('lets the creator revoke their own active share', async () => {
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedShare('org-1', 'share-1', 'rep-1');
    const wrapped = testEnv.wrap(revokeCatalogShareLink);

    const result = (await wrapped(
      buildRequest({ organizationId: 'org-1', shareId: 'share-1' }, authFor('rep-1')),
    )) as RevokeCatalogShareLinkResponse;

    expect(result.share.status).toBe('revoked');
  });

  it('lets an OWNER revoke a share created by someone else', async () => {
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedMember('org-1', 'owner-1', 'OWNER');
    await seedShare('org-1', 'share-1', 'rep-1');
    const wrapped = testEnv.wrap(revokeCatalogShareLink);

    const result = (await wrapped(
      buildRequest({ organizationId: 'org-1', shareId: 'share-1' }, authFor('owner-1')),
    )) as RevokeCatalogShareLinkResponse;

    expect(result.share.status).toBe('revoked');
  });

  it('rejects a peer (not the creator, not OWNER/ADMIN) revoking someone else\'s share', async () => {
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedMember('org-1', 'rep-2', 'SALES_REP');
    await seedShare('org-1', 'share-1', 'rep-1');
    const wrapped = testEnv.wrap(revokeCatalogShareLink);

    await expect(
      wrapped(buildRequest({ organizationId: 'org-1', shareId: 'share-1' }, authFor('rep-2'))),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('rejects revoking an already-revoked share', async () => {
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedShare('org-1', 'share-1', 'rep-1', { status: 'revoked' });
    const wrapped = testEnv.wrap(revokeCatalogShareLink);

    await expect(
      wrapped(buildRequest({ organizationId: 'org-1', shareId: 'share-1' }, authFor('rep-1'))),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('rejects an unknown shareId', async () => {
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    const wrapped = testEnv.wrap(revokeCatalogShareLink);

    await expect(
      wrapped(
        buildRequest({ organizationId: 'org-1', shareId: 'not-a-real-share' }, authFor('rep-1')),
      ),
    ).rejects.toMatchObject({ code: 'not-found' });
  });

  it('rejects an unauthenticated call', async () => {
    const wrapped = testEnv.wrap(revokeCatalogShareLink);

    await expect(
      wrapped(buildRequest({ organizationId: 'org-1', shareId: 'share-1' })),
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });
});
