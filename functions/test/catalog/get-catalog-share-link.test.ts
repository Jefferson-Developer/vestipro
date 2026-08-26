import { createHash } from 'node:crypto';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  getCatalogShareLink,
  type GetCatalogShareLinkRequest,
  type GetCatalogShareLinkResponse,
} from '../../src/catalog/get-catalog-share-link';

const PROJECT_ID = 'demo-vestipro-catalog-share-get-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: GetCatalogShareLinkRequest,
): CallableRequest<GetCatalogShareLinkRequest> {
  return {
    data,
    auth: undefined,
    rawRequest: {} as CallableRequest<GetCatalogShareLinkRequest>['rawRequest'],
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

async function seedOrganization(organizationId: string, name: string): Promise<void> {
  const now = Timestamp.now();
  await db.collection('organizations').doc(organizationId).set({
    name,
    slug: organizationId,
    settings: { currency: 'BRL', country: 'BR', defaultLanguage: 'pt-BR' },
    status: 'active',
    createdAt: now,
    createdBy: 'seed',
    updatedAt: now,
    updatedBy: 'seed',
  });
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

describe('getCatalogShareLink', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('reports a valid share with organization/items context, without internal fields', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedShare('org-1', 'share-1', 'token-1');
    const wrapped = testEnv.wrap(getCatalogShareLink);

    const result = (await wrapped(
      buildRequest({ token: 'token-1' }),
    )) as GetCatalogShareLinkResponse & Record<string, unknown>;

    expect(result.outcome).toBe('valid');
    expect(result.organizationName).toBe('Grupo Fashion XPTO');
    expect(result.items).toEqual([
      { productId: 'product-1', name: 'Camisa Linho', imageUrl: null },
    ]);
    expect(result.id).toBeUndefined();
    expect(result.organizationId).toBeUndefined();
    expect(result.createdBy).toBeUndefined();
    expect(result.tokenHash).toBeUndefined();
  });

  it('reports an unknown token as notFound, without leaking data', async () => {
    const wrapped = testEnv.wrap(getCatalogShareLink);

    const result = (await wrapped(
      buildRequest({ token: 'never-issued' }),
    )) as GetCatalogShareLinkResponse;

    expect(result.outcome).toBe('notFound');
    expect(result.items).toEqual([]);
    expect(result.organizationName).toBeNull();
  });

  it('reports a revoked share as revoked, without leaking items', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedShare('org-1', 'share-1', 'token-1', { status: 'revoked' });
    const wrapped = testEnv.wrap(getCatalogShareLink);

    const result = (await wrapped(
      buildRequest({ token: 'token-1' }),
    )) as GetCatalogShareLinkResponse;

    expect(result.outcome).toBe('revoked');
    expect(result.items).toEqual([]);
  });

  it('reports a past-expiresAt share as expired even though status is still active', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedShare('org-1', 'share-1', 'token-1', {
      expiresAt: Timestamp.fromMillis(Date.now() - 60_000),
    });
    const wrapped = testEnv.wrap(getCatalogShareLink);

    const result = (await wrapped(
      buildRequest({ token: 'token-1' }),
    )) as GetCatalogShareLinkResponse;

    expect(result.outcome).toBe('expired');
    expect(result.items).toEqual([]);
  });

  it('rejects a missing token', async () => {
    const wrapped = testEnv.wrap(getCatalogShareLink);

    await expect(wrapped(buildRequest({}))).rejects.toMatchObject({
      code: 'invalid-argument',
    });
  });
});
