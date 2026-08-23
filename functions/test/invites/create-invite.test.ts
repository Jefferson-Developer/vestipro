import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  createInvite,
  type CreateInviteRequest,
  type CreateInviteResponse,
} from '../../src/invites/create-invite';

// Isolated fake project, same rationale as `create-organization.test.ts`:
// talks to the real Firestore emulator through the Admin SDK, only
// `request.auth` is faked via `firebase-functions-test`'s `wrap`.
const PROJECT_ID = 'demo-vestipro-invites-create-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: CreateInviteRequest,
  auth?: CallableRequest<CreateInviteRequest>['auth'],
): CallableRequest<CreateInviteRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<CreateInviteRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<CreateInviteRequest>['auth'] {
  return {
    uid,
    token,
    rawToken: 'raw-token',
  } as CallableRequest<CreateInviteRequest>['auth'];
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

describe('createInvite', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('creates a pending invite with a secure token, its hash only in Firestore, and an audit log entry', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    const wrapped = testEnv.wrap(createInvite);

    const result = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          email: 'Novo.Vendedor@Vestipro.com.br',
          roleName: 'SALES_REP',
          message: '  Bem-vindo ao time!  ',
        },
        authFor('owner-1'),
      ),
    )) as CreateInviteResponse;

    expect(result.invite.email).toBe('novo.vendedor@vestipro.com.br');
    expect(result.invite.roleName).toBe('SALES_REP');
    expect(result.invite.status).toBe('pending');
    expect(result.invite.message).toBe('Bem-vindo ao time!');
    expect(result.invite.invitedByUserId).toBe('owner-1');
    expect(result.token).toBeTruthy();
    expect(new Date(result.invite.expiresAt).getTime()).toBeGreaterThan(Date.now());

    const inviteSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('invites')
      .doc(result.invite.id)
      .get();
    const inviteData = inviteSnapshot.data()!;
    expect(inviteData.tokenHash).toBeTruthy();
    expect(inviteData.tokenHash).not.toBe(result.token);

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.size).toBe(1);
    expect(auditSnapshot.docs[0].data().action).toBe('user.invited');
    expect(auditSnapshot.docs[0].data().actorUserId).toBe('owner-1');
    expect(auditSnapshot.docs[0].data().entityId).toBe(result.invite.id);
  });

  it('sets expiresAt roughly 7 days ahead by default', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    const wrapped = testEnv.wrap(createInvite);

    const before = Date.now();
    const result = (await wrapped(
      buildRequest(
        { organizationId: 'org-1', email: 'novo@vestipro.com.br', roleName: 'SALES_REP' },
        authFor('owner-1'),
      ),
    )) as CreateInviteResponse;

    const expiresInDays =
      (new Date(result.invite.expiresAt).getTime() - before) / (24 * 60 * 60 * 1000);
    expect(expiresInDays).toBeGreaterThan(6.9);
    expect(expiresInDays).toBeLessThan(7.1);
  });

  it('allows ADMIN to invite an ADMIN or lower, but rejects ADMIN inviting an OWNER', async () => {
    await seedOrganizationWithMember('org-1', 'admin-1', 'ADMIN');
    const wrapped = testEnv.wrap(createInvite);

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', email: 'peer-admin@vestipro.com.br', roleName: 'ADMIN' },
          authFor('admin-1'),
        ),
      ),
    ).resolves.toBeDefined();

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', email: 'nao-deveria@vestipro.com.br', roleName: 'OWNER' },
          authFor('admin-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });

    const allInvites = await db
      .collection('organizations')
      .doc('org-1')
      .collection('invites')
      .get();
    expect(allInvites.size).toBe(1);
  });

  it('rejects a caller without user.invite (e.g. SALES_REP)', async () => {
    await seedOrganizationWithMember('org-1', 'rep-1', 'SALES_REP');
    const wrapped = testEnv.wrap(createInvite);

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', email: 'novo@vestipro.com.br', roleName: 'SALES_REP' },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });

    const allInvites = await db
      .collection('organizations')
      .doc('org-1')
      .collection('invites')
      .get();
    expect(allInvites.size).toBe(0);
  });

  it('rejects a caller with no active membership in the organization', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    const wrapped = testEnv.wrap(createInvite);

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', email: 'novo@vestipro.com.br', roleName: 'SALES_REP' },
          authFor('stranger'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('rejects an inactive (deactivated) membership', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('owner-1')
      .update({ status: 'inactive' });
    const wrapped = testEnv.wrap(createInvite);

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', email: 'novo@vestipro.com.br', roleName: 'SALES_REP' },
          authFor('owner-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('rejects an unauthenticated call', async () => {
    const wrapped = testEnv.wrap(createInvite);

    await expect(
      wrapped(
        buildRequest({
          organizationId: 'org-1',
          email: 'novo@vestipro.com.br',
          roleName: 'SALES_REP',
        }),
      ),
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('rejects a malformed e-mail', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    const wrapped = testEnv.wrap(createInvite);

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', email: 'not-an-email', roleName: 'SALES_REP' },
          authFor('owner-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('rejects an unknown roleName', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    const wrapped = testEnv.wrap(createInvite);

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', email: 'novo@vestipro.com.br', roleName: 'NOT_A_ROLE' },
          authFor('owner-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('honors a per-organization inviteExpirationDays override', async () => {
    await seedOrganizationWithMember('org-1', 'owner-1', 'OWNER');
    await db
      .collection('organizations')
      .doc('org-1')
      .update({ 'settings.inviteExpirationDays': 30 });
    const wrapped = testEnv.wrap(createInvite);

    const before = Date.now();
    const result = (await wrapped(
      buildRequest(
        { organizationId: 'org-1', email: 'novo@vestipro.com.br', roleName: 'SALES_REP' },
        authFor('owner-1'),
      ),
    )) as CreateInviteResponse;

    const expiresInDays =
      (new Date(result.invite.expiresAt).getTime() - before) / (24 * 60 * 60 * 1000);
    expect(expiresInDays).toBeGreaterThan(29.9);
    expect(expiresInDays).toBeLessThan(30.1);
  });
});
