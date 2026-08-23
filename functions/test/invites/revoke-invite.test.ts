import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  revokeInvite,
  type RevokeInviteRequest,
  type RevokeInviteResponse,
} from '../../src/invites/revoke-invite';

const PROJECT_ID = 'demo-vestipro-invites-revoke-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: RevokeInviteRequest,
  auth?: CallableRequest<RevokeInviteRequest>['auth'],
): CallableRequest<RevokeInviteRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<RevokeInviteRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<RevokeInviteRequest>['auth'] {
  return {
    uid,
    token,
    rawToken: 'raw-token',
  } as CallableRequest<RevokeInviteRequest>['auth'];
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

async function seedInvite(
  organizationId: string,
  inviteId: string,
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
      tokenHash: 'original-hash',
      invitedByUserId: 'owner-1',
      invitedByName: 'Owner',
      message: null,
      expiresAt: Timestamp.fromMillis(now.toMillis() + 7 * 24 * 60 * 60 * 1000),
      createdAt: now,
      createdBy: 'owner-1',
      updatedAt: now,
      updatedBy: 'owner-1',
      ...overrides,
    });
}

describe('revokeInvite', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('marks a pending invite revoked, clears tokenHash and records an audit entry', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    await seedInvite('org-1', 'invite-1');
    const wrapped = testEnv.wrap(revokeInvite);

    const result = (await wrapped(
      buildRequest({ organizationId: 'org-1', inviteId: 'invite-1' }, authFor('owner-1')),
    )) as RevokeInviteResponse;

    expect(result.invite.status).toBe('revoked');

    const inviteSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('invites')
      .doc('invite-1')
      .get();
    const inviteData = inviteSnapshot.data()!;
    expect(inviteData.status).toBe('revoked');
    expect(inviteData.tokenHash).toBeNull();

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.size).toBe(1);
    expect(auditSnapshot.docs[0].data().action).toBe('user.inviteRevoked');
  });

  it('is not reusable: revoking twice fails the second time with failed-precondition', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    await seedInvite('org-1', 'invite-1');
    const wrapped = testEnv.wrap(revokeInvite);

    await wrapped(buildRequest({ organizationId: 'org-1', inviteId: 'invite-1' }, authFor('owner-1')));

    await expect(
      wrapped(buildRequest({ organizationId: 'org-1', inviteId: 'invite-1' }, authFor('owner-1'))),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('rejects revoking an already-accepted invite', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    await seedInvite('org-1', 'invite-1', { status: 'accepted' });
    const wrapped = testEnv.wrap(revokeInvite);

    await expect(
      wrapped(buildRequest({ organizationId: 'org-1', inviteId: 'invite-1' }, authFor('owner-1'))),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('rejects a caller without user.invite (e.g. SALES_MANAGER)', async () => {
    await seedOrganizationWithMember('org-1', 'manager-1', 'SALES_MANAGER');
    await seedInvite('org-1', 'invite-1');
    const wrapped = testEnv.wrap(revokeInvite);

    await expect(
      wrapped(buildRequest({ organizationId: 'org-1', inviteId: 'invite-1' }, authFor('manager-1'))),
    ).rejects.toMatchObject({ code: 'permission-denied' });

    const inviteSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('invites')
      .doc('invite-1')
      .get();
    expect(inviteSnapshot.data()!.status).toBe('pending');
  });

  it('rejects a non-existent invite', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    const wrapped = testEnv.wrap(revokeInvite);

    await expect(
      wrapped(buildRequest({ organizationId: 'org-1', inviteId: 'missing' }, authFor('owner-1'))),
    ).rejects.toMatchObject({ code: 'not-found' });
  });

  it('rejects an unauthenticated call', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    await seedInvite('org-1', 'invite-1');
    const wrapped = testEnv.wrap(revokeInvite);

    await expect(
      wrapped(buildRequest({ organizationId: 'org-1', inviteId: 'invite-1' })),
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });
});
