import { createHash } from 'node:crypto';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  validateInvite,
  type ValidateInviteRequest,
  type ValidateInviteResponse,
} from '../../src/invites/validate-invite';

const PROJECT_ID = 'demo-vestipro-invites-validate-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: ValidateInviteRequest,
): CallableRequest<ValidateInviteRequest> {
  return {
    data,
    auth: undefined,
    rawRequest: {} as CallableRequest<ValidateInviteRequest>['rawRequest'],
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

async function seedInvite(
  organizationId: string,
  inviteId: string,
  token: string,
  overrides: Record<string, unknown> = {},
): Promise<void> {
  const now = Timestamp.now();
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('invites')
    .doc(inviteId)
    .set({
      organizationId,
      email: 'convidado@vestipro.com.br',
      roleName: 'SALES_REP',
      status: 'pending',
      tokenHash: hashToken(token),
      invitedByUserId: 'owner-1',
      invitedByName: 'Owner Um',
      message: null,
      expiresAt: Timestamp.fromMillis(now.toMillis() + 7 * 24 * 60 * 60 * 1000),
      createdAt: now,
      createdBy: 'owner-1',
      updatedAt: now,
      updatedBy: 'owner-1',
      ...overrides,
    });
}

describe('validateInvite', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('reports a pending, non-expired invite as valid, with organization/email/role context', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedInvite('org-1', 'invite-1', 'token-1');
    const wrapped = testEnv.wrap(validateInvite);

    const result = (await wrapped(
      buildRequest({ token: 'token-1' }),
    )) as ValidateInviteResponse;

    expect(result.outcome).toBe('valid');
    expect(result.organizationId).toBe('org-1');
    expect(result.organizationName).toBe('Grupo Fashion XPTO');
    expect(result.email).toBe('convidado@vestipro.com.br');
    expect(result.roleName).toBe('SALES_REP');
  });

  it('reports an unknown token as notFound, without leaking any invite data', async () => {
    const wrapped = testEnv.wrap(validateInvite);

    const result = (await wrapped(
      buildRequest({ token: 'never-issued-token' }),
    )) as ValidateInviteResponse;

    expect(result.outcome).toBe('notFound');
    expect(result.organizationId).toBeNull();
    expect(result.organizationName).toBeNull();
    expect(result.email).toBeNull();
    expect(result.roleName).toBeNull();
  });

  it('reports an already-accepted invite as accepted', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedInvite('org-1', 'invite-1', 'token-1', { status: 'accepted' });
    const wrapped = testEnv.wrap(validateInvite);

    const result = (await wrapped(
      buildRequest({ token: 'token-1' }),
    )) as ValidateInviteResponse;

    expect(result.outcome).toBe('accepted');
  });

  it('reports a revoked invite as revoked', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedInvite('org-1', 'invite-1', 'token-1', { status: 'revoked' });
    const wrapped = testEnv.wrap(validateInvite);

    const result = (await wrapped(
      buildRequest({ token: 'token-1' }),
    )) as ValidateInviteResponse;

    expect(result.outcome).toBe('revoked');
  });

  it('reports a past-expiresAt invite as expired even though status is still pending', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedInvite('org-1', 'invite-1', 'token-1', {
      status: 'pending',
      expiresAt: Timestamp.fromMillis(Date.now() - 60_000),
    });
    const wrapped = testEnv.wrap(validateInvite);

    const result = (await wrapped(
      buildRequest({ token: 'token-1' }),
    )) as ValidateInviteResponse;

    expect(result.outcome).toBe('expired');
  });

  it('rejects a missing token', async () => {
    const wrapped = testEnv.wrap(validateInvite);

    await expect(
      wrapped(buildRequest({})),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('never returns tokenHash or the plaintext token', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedInvite('org-1', 'invite-1', 'token-1');
    const wrapped = testEnv.wrap(validateInvite);

    const result = (await wrapped(
      buildRequest({ token: 'token-1' }),
    )) as unknown as Record<string, unknown>;

    expect(result.tokenHash).toBeUndefined();
    expect(result.token).toBeUndefined();
  });
});
