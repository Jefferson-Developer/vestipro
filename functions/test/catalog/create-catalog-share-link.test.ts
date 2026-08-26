import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  createCatalogShareLink,
  type CreateCatalogShareLinkRequest,
  type CreateCatalogShareLinkResponse,
} from '../../src/catalog/create-catalog-share-link';

const PROJECT_ID = 'demo-vestipro-catalog-share-create-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: CreateCatalogShareLinkRequest,
  auth?: CallableRequest<CreateCatalogShareLinkRequest>['auth'],
): CallableRequest<CreateCatalogShareLinkRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<CreateCatalogShareLinkRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<CreateCatalogShareLinkRequest>['auth'] {
  return { uid, token, rawToken: 'raw-token' } as CallableRequest<CreateCatalogShareLinkRequest>['auth'];
}

async function clearFirestore(): Promise<void> {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
}

async function seedOrganizationWithMember(
  organizationId: string,
  uid: string,
  roleName: string,
): Promise<void> {
  const now = Timestamp.now();
  await db.collection('organizations').doc(organizationId).set({
    name: 'Grupo Fashion XPTO',
    slug: 'grupo-fashion-xpto',
    settings: { currency: 'BRL', country: 'BR', defaultLanguage: 'pt-BR' },
    status: 'active',
    createdAt: now,
    createdBy: uid,
    updatedAt: now,
    updatedBy: uid,
  });
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

const oneItem = [{ productId: 'product-1', name: 'Camisa Linho', imageUrl: 'https://img/1.png' }];

describe('createCatalogShareLink', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('creates an active share with a secure token, its hash only in Firestore', async () => {
    await seedOrganizationWithMember('org-1', 'rep-1', 'SALES_REP');
    const wrapped = testEnv.wrap(createCatalogShareLink);

    const result = (await wrapped(
      buildRequest(
        { organizationId: 'org-1', scope: 'product', items: oneItem },
        authFor('rep-1'),
      ),
    )) as CreateCatalogShareLinkResponse;

    expect(result.share.scope).toBe('product');
    expect(result.share.items).toEqual(oneItem);
    expect(result.share.status).toBe('active');
    expect(result.share.openCount).toBe(0);
    expect(result.share.createdBy).toBe('rep-1');
    expect(result.token).toBeTruthy();
    expect(new Date(result.share.expiresAt).getTime()).toBeGreaterThan(Date.now());

    const snapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('catalogShares')
      .doc(result.share.id)
      .get();
    const data = snapshot.data()!;
    expect(data.tokenHash).toBeTruthy();
    expect(data.tokenHash).not.toBe(result.token);
  });

  it('any active member (not just catalog.manage roles) may create a share', async () => {
    await seedOrganizationWithMember('org-1', 'assistant-1', 'SALES_ASSISTANT');
    const wrapped = testEnv.wrap(createCatalogShareLink);

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', scope: 'product', items: oneItem },
          authFor('assistant-1'),
        ),
      ),
    ).resolves.toBeDefined();
  });

  it('defaults expiresAt to roughly 30 days ahead', async () => {
    await seedOrganizationWithMember('org-1', 'rep-1', 'SALES_REP');
    const wrapped = testEnv.wrap(createCatalogShareLink);

    const before = Date.now();
    const result = (await wrapped(
      buildRequest(
        { organizationId: 'org-1', scope: 'product', items: oneItem },
        authFor('rep-1'),
      ),
    )) as CreateCatalogShareLinkResponse;

    const expiresInDays =
      (new Date(result.share.expiresAt).getTime() - before) / (24 * 60 * 60 * 1000);
    expect(expiresInDays).toBeGreaterThan(29.9);
    expect(expiresInDays).toBeLessThan(30.1);
  });

  it('honors a requested expiresInDays within the allowed range', async () => {
    await seedOrganizationWithMember('org-1', 'rep-1', 'SALES_REP');
    const wrapped = testEnv.wrap(createCatalogShareLink);

    const before = Date.now();
    const result = (await wrapped(
      buildRequest(
        { organizationId: 'org-1', scope: 'product', items: oneItem, expiresInDays: 7 },
        authFor('rep-1'),
      ),
    )) as CreateCatalogShareLinkResponse;

    const expiresInDays =
      (new Date(result.share.expiresAt).getTime() - before) / (24 * 60 * 60 * 1000);
    expect(expiresInDays).toBeGreaterThan(6.9);
    expect(expiresInDays).toBeLessThan(7.1);
  });

  it('accepts a multi-item selection scope', async () => {
    await seedOrganizationWithMember('org-1', 'rep-1', 'SALES_REP');
    const wrapped = testEnv.wrap(createCatalogShareLink);

    const items = [
      { productId: 'product-1', name: 'Camisa', imageUrl: null },
      { productId: 'product-2', name: 'Calça', imageUrl: null },
    ];
    const result = (await wrapped(
      buildRequest(
        { organizationId: 'org-1', scope: 'selection', items },
        authFor('rep-1'),
      ),
    )) as CreateCatalogShareLinkResponse;

    expect(result.share.items).toHaveLength(2);
  });

  it("rejects scope 'product' with more than one item", async () => {
    await seedOrganizationWithMember('org-1', 'rep-1', 'SALES_REP');
    const wrapped = testEnv.wrap(createCatalogShareLink);

    const items = [
      { productId: 'product-1', name: 'Camisa', imageUrl: null },
      { productId: 'product-2', name: 'Calça', imageUrl: null },
    ];
    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', scope: 'product', items },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it("requires collectionId/collectionName when scope is 'collection'", async () => {
    await seedOrganizationWithMember('org-1', 'rep-1', 'SALES_REP');
    const wrapped = testEnv.wrap(createCatalogShareLink);

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', scope: 'collection', items: oneItem },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });

    const result = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          scope: 'collection',
          items: oneItem,
          collectionId: 'collection-1',
          collectionName: 'Verão 2026',
        },
        authFor('rep-1'),
      ),
    )) as CreateCatalogShareLinkResponse;
    expect(result.share.collectionId).toBe('collection-1');
    expect(result.share.collectionName).toBe('Verão 2026');
  });

  it('rejects an empty items array', async () => {
    await seedOrganizationWithMember('org-1', 'rep-1', 'SALES_REP');
    const wrapped = testEnv.wrap(createCatalogShareLink);

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', scope: 'selection', items: [] },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('rejects an unauthenticated call', async () => {
    const wrapped = testEnv.wrap(createCatalogShareLink);

    await expect(
      wrapped(buildRequest({ organizationId: 'org-1', scope: 'product', items: oneItem })),
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('rejects a caller with no active membership in the organization', async () => {
    await seedOrganizationWithMember('org-1', 'rep-1', 'SALES_REP');
    const wrapped = testEnv.wrap(createCatalogShareLink);

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', scope: 'product', items: oneItem },
          authFor('stranger'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('rejects an inactive (deactivated) membership', async () => {
    await seedOrganizationWithMember('org-1', 'rep-1', 'SALES_REP');
    await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('rep-1')
      .update({ status: 'inactive' });
    const wrapped = testEnv.wrap(createCatalogShareLink);

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', scope: 'product', items: oneItem },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });
});
