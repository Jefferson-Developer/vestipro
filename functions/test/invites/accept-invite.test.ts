import { createHash } from 'node:crypto';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  acceptInvite,
  type AcceptInviteRequest,
  type AcceptInviteResponse,
} from '../../src/invites/accept-invite';

const PROJECT_ID = 'demo-vestipro-invites-accept-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: AcceptInviteRequest,
  auth?: CallableRequest<AcceptInviteRequest>['auth'],
): CallableRequest<AcceptInviteRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<AcceptInviteRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  email: string,
): CallableRequest<AcceptInviteRequest>['auth'] {
  return {
    uid,
    token: { email },
    rawToken: 'raw-token',
  } as CallableRequest<AcceptInviteRequest>['auth'];
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

describe('acceptInvite', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('creates the Membership with the invite role, marks the invite accepted, and records an audit entry', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedInvite('org-1', 'invite-1', 'token-1');
    const wrapped = testEnv.wrap(acceptInvite);

    const result = (await wrapped(
      buildRequest({ token: 'token-1' }, authFor('new-user-1', 'Convidado@Vestipro.com.br')),
    )) as AcceptInviteResponse;

    expect(result.organizationId).toBe('org-1');
    expect(result.organizationName).toBe('Grupo Fashion XPTO');
    expect(result.roleName).toBe('SALES_REP');

    const membershipSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('new-user-1')
      .get();
    expect(membershipSnapshot.exists).toBe(true);
    expect(membershipSnapshot.data()?.roleName).toBe('SALES_REP');
    expect(membershipSnapshot.data()?.status).toBe('active');

    const inviteSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('invites')
      .doc('invite-1')
      .get();
    expect(inviteSnapshot.data()?.status).toBe('accepted');
    // Unlike `revokeInvite`, `acceptInvite` deliberately keeps `tokenHash`
    // as-is — `status: 'accepted'` alone already blocks any further use,
    // with a precise message (see the "rejects a second acceptance" test).
    expect(inviteSnapshot.data()?.tokenHash).toBeTruthy();

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.size).toBe(1);
    expect(auditSnapshot.docs[0].data().action).toBe('user.inviteAccepted');
    expect(auditSnapshot.docs[0].data().actorUserId).toBe('new-user-1');
  });

  it('rejects a second acceptance of the same token (already accepted)', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedInvite('org-1', 'invite-1', 'token-1');
    const wrapped = testEnv.wrap(acceptInvite);

    await wrapped(
      buildRequest({ token: 'token-1' }, authFor('new-user-1', 'convidado@vestipro.com.br')),
    );

    await expect(
      wrapped(
        buildRequest(
          { token: 'token-1' },
          authFor('another-user', 'convidado@vestipro.com.br'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'failed-precondition' });

    const membershipSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('another-user')
      .get();
    expect(membershipSnapshot.exists).toBe(false);
  });

  it('rejects an expired invite', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedInvite('org-1', 'invite-1', 'token-1', {
      expiresAt: Timestamp.fromMillis(Date.now() - 60_000),
    });
    const wrapped = testEnv.wrap(acceptInvite);

    await expect(
      wrapped(
        buildRequest({ token: 'token-1' }, authFor('new-user-1', 'convidado@vestipro.com.br')),
      ),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('rejects a revoked invite', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    // Real `revokeInvite` also clears `tokenHash` (defense-in-depth) — kept
    // here so this test exercises `resolveInviteOutcome`'s `'revoked'`
    // branch specifically, distinct from the "unknown token" `not-found`
    // case covered by its own test below.
    await seedInvite('org-1', 'invite-1', 'token-1', { status: 'revoked' });
    const wrapped = testEnv.wrap(acceptInvite);

    await expect(
      wrapped(
        buildRequest(
          { token: 'token-1' },
          authFor('new-user-1', 'convidado@vestipro.com.br'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'failed-precondition' });

    const membershipSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('new-user-1')
      .get();
    expect(membershipSnapshot.exists).toBe(false);
  });

  it('rejects when the caller e-mail diverges from the invite e-mail', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedInvite('org-1', 'invite-1', 'token-1');
    const wrapped = testEnv.wrap(acceptInvite);

    await expect(
      wrapped(
        buildRequest(
          { token: 'token-1' },
          authFor('new-user-1', 'outro-email@vestipro.com.br'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });

    const inviteSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('invites')
      .doc('invite-1')
      .get();
    expect(inviteSnapshot.data()?.status).toBe('pending');
  });

  it('rejects an unknown token', async () => {
    const wrapped = testEnv.wrap(acceptInvite);

    await expect(
      wrapped(
        buildRequest(
          { token: 'never-issued' },
          authFor('new-user-1', 'convidado@vestipro.com.br'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'not-found' });
  });

  it('rejects an unauthenticated call', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedInvite('org-1', 'invite-1', 'token-1');
    const wrapped = testEnv.wrap(acceptInvite);

    await expect(
      wrapped(buildRequest({ token: 'token-1' })),
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('links an already existing account (vínculo de conta já existente), preserving createdAt/createdBy and bumping version', async () => {
    const now = Timestamp.now();
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedInvite('org-1', 'invite-1', 'token-1', { roleName: 'SALES_MANAGER' });
    await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('existing-user')
      .set({
        organizationId: 'org-1',
        userId: 'existing-user',
        roleId: 'SALES_REP',
        roleName: 'SALES_REP',
        teamIds: ['team-a'],
        status: 'inactive',
        version: 1,
        createdAt: now,
        createdBy: 'someone-else',
        updatedAt: now,
        updatedBy: 'someone-else',
      });
    const wrapped = testEnv.wrap(acceptInvite);

    await wrapped(
      buildRequest({ token: 'token-1' }, authFor('existing-user', 'convidado@vestipro.com.br')),
    );

    const membershipSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('existing-user')
      .get();
    const membership = membershipSnapshot.data()!;
    expect(membership.roleName).toBe('SALES_MANAGER');
    expect(membership.status).toBe('active');
    expect(membership.teamIds).toEqual(['team-a']);
    expect(membership.version).toBe(2);
    expect(membership.createdBy).toBe('someone-else');
  });
});
