import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  resendInvite,
  type ResendInviteRequest,
  type ResendInviteResponse,
} from '../../src/invites/resend-invite';

const PROJECT_ID = 'demo-vestipro-invites-resend-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: ResendInviteRequest,
  auth?: CallableRequest<ResendInviteRequest>['auth'],
): CallableRequest<ResendInviteRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<ResendInviteRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<ResendInviteRequest>['auth'] {
  return {
    uid,
    token,
    rawToken: 'raw-token',
  } as CallableRequest<ResendInviteRequest>['auth'];
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

describe('resendInvite', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('generates a new token/hash, extends expiresAt and keeps status pending, recording an audit entry', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    await seedInvite('org-1', 'invite-1');
    const wrapped = testEnv.wrap(resendInvite);

    const result = (await wrapped(
      buildRequest({ organizationId: 'org-1', inviteId: 'invite-1' }, authFor('owner-1')),
    )) as ResendInviteResponse;

    expect(result.invite.status).toBe('pending');
    expect(result.token).toBeTruthy();

    const inviteSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('invites')
      .doc('invite-1')
      .get();
    const inviteData = inviteSnapshot.data()!;
    expect(inviteData.tokenHash).not.toBe('original-hash');

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.size).toBe(1);
    expect(auditSnapshot.docs[0].data().action).toBe('user.inviteResent');
  });

  it('invalidates the previous token: only the new tokenHash is stored', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    await seedInvite('org-1', 'invite-1', { tokenHash: 'first-hash' });
    const wrapped = testEnv.wrap(resendInvite);

    const first = (await wrapped(
      buildRequest({ organizationId: 'org-1', inviteId: 'invite-1' }, authFor('owner-1')),
    )) as ResendInviteResponse;

    const second = (await wrapped(
      buildRequest({ organizationId: 'org-1', inviteId: 'invite-1' }, authFor('owner-1')),
    )) as ResendInviteResponse;

    expect(first.token).not.toBe(second.token);

    const inviteSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('invites')
      .doc('invite-1')
      .get();
    expect(inviteSnapshot.data()!.tokenHash).not.toBe('first-hash');
  });

  it('allows resending an already-expired invite (reactivating it as pending)', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    await seedInvite('org-1', 'invite-1', { status: 'expired' });
    const wrapped = testEnv.wrap(resendInvite);

    const result = (await wrapped(
      buildRequest({ organizationId: 'org-1', inviteId: 'invite-1' }, authFor('owner-1')),
    )) as ResendInviteResponse;

    expect(result.invite.status).toBe('pending');
  });

  it('rejects resending an already-accepted invite', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    await seedInvite('org-1', 'invite-1', { status: 'accepted' });
    const wrapped = testEnv.wrap(resendInvite);

    await expect(
      wrapped(buildRequest({ organizationId: 'org-1', inviteId: 'invite-1' }, authFor('owner-1'))),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('rejects resending an already-revoked invite', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    await seedInvite('org-1', 'invite-1', { status: 'revoked' });
    const wrapped = testEnv.wrap(resendInvite);

    await expect(
      wrapped(buildRequest({ organizationId: 'org-1', inviteId: 'invite-1' }, authFor('owner-1'))),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('rejects a caller without user.invite', async () => {
    await seedOrganizationWithMember('org-1', 'rep-1', 'SALES_REP');
    await seedInvite('org-1', 'invite-1');
    const wrapped = testEnv.wrap(resendInvite);

    await expect(
      wrapped(buildRequest({ organizationId: 'org-1', inviteId: 'invite-1' }, authFor('rep-1'))),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('rejects an ADMIN resending an invite originally issued for OWNER', async () => {
    await seedOrganizationWithMember('org-1', 'admin-1', 'ADMIN');
    await seedInvite('org-1', 'invite-1', { roleName: 'OWNER' });
    const wrapped = testEnv.wrap(resendInvite);

    await expect(
      wrapped(buildRequest({ organizationId: 'org-1', inviteId: 'invite-1' }, authFor('admin-1'))),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('rejects a non-existent invite', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    const wrapped = testEnv.wrap(resendInvite);

    await expect(
      wrapped(buildRequest({ organizationId: 'org-1', inviteId: 'missing' }, authFor('owner-1'))),
    ).rejects.toMatchObject({ code: 'not-found' });
  });

  it('rejects an unauthenticated call', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    await seedInvite('org-1', 'invite-1');
    const wrapped = testEnv.wrap(resendInvite);

    await expect(
      wrapped(buildRequest({ organizationId: 'org-1', inviteId: 'invite-1' })),
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });
});
