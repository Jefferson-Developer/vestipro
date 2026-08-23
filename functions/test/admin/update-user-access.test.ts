import { getApps, initializeApp } from 'firebase-admin/app';
import * as adminAuth from 'firebase-admin/auth';
import type { Auth, UserRecord } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import { createInvite } from '../../src/invites/create-invite';
import {
  ACCESS_DISABLED_MESSAGE,
  deactivateUser,
  reactivateUser,
  type UpdateUserAccessResponse,
} from '../../src/admin/update-user-access';

const PROJECT_ID = 'demo-vestipro-admin-update-user-access-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

const SYSTEM_ROLE_NAMES = [
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
  'SALES_REP',
  'SALES_ASSISTANT',
  'FINANCE',
  'READ_ONLY',
] as const;

type MockAuth = Pick<
  Auth,
  'getUser' | 'setCustomUserClaims' | 'updateUser' | 'revokeRefreshTokens'
>;

function buildRequest<T>(
  data: T,
  auth?: CallableRequest<T>['auth'],
): CallableRequest<T> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<T>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<unknown>['auth'] {
  return {
    uid,
    token,
    rawToken: 'raw-token',
  } as CallableRequest<unknown>['auth'];
}

async function clearFirestore(): Promise<void> {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
}

function installAuthMock({
  targetUserId = 'rep-1',
  customClaims = {},
}: {
  targetUserId?: string;
  customClaims?: Record<string, unknown>;
} = {}): jest.Mocked<MockAuth> {
  const auth = {
    getUser: jest.fn(),
    setCustomUserClaims: jest.fn(),
    updateUser: jest.fn(),
    revokeRefreshTokens: jest.fn(),
  } satisfies jest.Mocked<MockAuth>;

  auth.getUser.mockResolvedValue({
    uid: targetUserId,
    customClaims,
  } as unknown as UserRecord);
  auth.setCustomUserClaims.mockResolvedValue(undefined);
  auth.updateUser.mockResolvedValue({ uid: targetUserId } as unknown as UserRecord);
  auth.revokeRefreshTokens.mockResolvedValue(undefined);

  jest.spyOn(adminAuth, 'getAuth').mockReturnValue(auth as unknown as Auth);
  return auth;
}

async function seedOrganization(organizationId: string): Promise<void> {
  const now = Timestamp.now();
  const organizationRef = db.collection('organizations').doc(organizationId);
  await organizationRef.set({
    name: 'Grupo Fashion XPTO',
    slug: 'grupo-fashion-xpto',
    settings: { currency: 'BRL', country: 'BR', defaultLanguage: 'pt-BR' },
    status: 'active',
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
    deletedAt: null,
  });

  await Promise.all(
    SYSTEM_ROLE_NAMES.map((roleName) =>
      organizationRef.collection('roles').doc(roleName).set({
        organizationId,
        name: roleName,
        isSystemRole: true,
        version: 1,
        createdAt: now,
        createdBy: 'owner-1',
        updatedAt: now,
        updatedBy: 'owner-1',
        deletedAt: null,
      }),
    ),
  );
}

async function seedMember({
  organizationId,
  uid,
  roleName,
  status = 'active',
  teamIds = [],
}: {
  organizationId: string;
  uid: string;
  roleName: string;
  status?: string;
  teamIds?: string[];
}): Promise<void> {
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
      teamIds,
      status,
      version: 1,
      createdAt: now,
      createdBy: 'owner-1',
      updatedAt: now,
      updatedBy: 'owner-1',
      deletedAt: null,
    });
}

async function seedHistoricalRecords(organizationId: string): Promise<void> {
  const organizationRef = db.collection('organizations').doc(organizationId);
  await Promise.all([
    organizationRef.collection('orders').doc('order-1').set({
      organizationId,
      userId: 'rep-1',
      total: 1200,
      status: 'submitted',
    }),
    organizationRef.collection('crmActivities').doc('activity-1').set({
      organizationId,
      userId: 'rep-1',
      type: 'visit',
      note: 'Cliente visitado.',
    }),
    organizationRef.collection('portfolioAssignments').doc('assignment-1').set({
      organizationId,
      userId: 'rep-1',
      customerId: 'customer-1',
      status: 'active',
    }),
    organizationRef.collection('auditLogs').doc('existing-log').set({
      organizationId,
      actorUserId: 'owner-1',
      action: 'user.roleUpdated',
      entityType: 'membership',
      entityId: 'rep-1',
      timestamp: Timestamp.now(),
    }),
  ]);
}

describe('update user access', () => {
  afterEach(async () => {
    jest.restoreAllMocks();
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('deactivates a membership, preserves history, audits and blocks the next authenticated request', async () => {
    const auth = installAuthMock();
    await seedOrganization('org-1');
    await seedMember({ organizationId: 'org-1', uid: 'owner-1', roleName: 'OWNER' });
    await seedMember({
      organizationId: 'org-1',
      uid: 'rep-1',
      roleName: 'SALES_REP',
      teamIds: ['team-a'],
    });
    await seedHistoricalRecords('org-1');
    const wrapped = testEnv.wrap(deactivateUser);

    const result = (await wrapped(
      buildRequest(
        { organizationId: 'org-1', targetUserId: 'rep-1' },
        authFor('owner-1', { name: 'Owner User' }),
      ),
    )) as UpdateUserAccessResponse;

    expect(result.previousStatus).toBe('active');
    expect(result.status).toBe('inactive');
    expect(result.targetUserId).toBe('rep-1');
    expect(new Date(result.updatedAt).toString()).not.toBe('Invalid Date');

    const membershipSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('rep-1')
      .get();
    const membership = membershipSnapshot.data();
    expect(membership?.status).toBe('inactive');
    expect(membership?.roleName).toBe('SALES_REP');
    expect(membership?.teamIds).toEqual(['team-a']);
    expect(membership?.version).toBe(2);
    expect(membership?.updatedBy).toBe('owner-1');

    await expect(
      db.collection('organizations').doc('org-1').collection('orders').doc('order-1').get(),
    ).resolves.toMatchObject({ exists: true });
    await expect(
      db
        .collection('organizations')
        .doc('org-1')
        .collection('crmActivities')
        .doc('activity-1')
        .get(),
    ).resolves.toMatchObject({ exists: true });
    await expect(
      db
        .collection('organizations')
        .doc('org-1')
        .collection('portfolioAssignments')
        .doc('assignment-1')
        .get(),
    ).resolves.toMatchObject({ exists: true });
    await expect(
      db
        .collection('organizations')
        .doc('org-1')
        .collection('auditLogs')
        .doc('existing-log')
        .get(),
    ).resolves.toMatchObject({ exists: true });

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .where('action', '==', 'user.deactivated')
      .get();
    expect(auditSnapshot.size).toBe(1);
    const audit = auditSnapshot.docs[0].data();
    expect(audit.actorUserId).toBe('owner-1');
    expect(audit.targetUserId).toBe('rep-1');
    expect(audit.previousValue).toEqual({
      status: 'active',
      roleName: 'SALES_REP',
    });
    expect(audit.newValue).toEqual({
      status: 'inactive',
      roleName: 'SALES_REP',
    });

    expect(auth.setCustomUserClaims).toHaveBeenCalledWith('rep-1', {
      vestiproAccessDisabled: true,
    });
    expect(auth.updateUser).toHaveBeenCalledWith('rep-1', { disabled: true });
    expect(auth.revokeRefreshTokens).toHaveBeenCalledWith('rep-1');

    const createInviteWrapped = testEnv.wrap(createInvite);
    await expect(
      createInviteWrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            targetUserId: 'unused',
            email: 'novo@vestipro.com.br',
            roleName: 'SALES_REP',
          },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({
      code: 'permission-denied',
      message: ACCESS_DISABLED_MESSAGE,
    });
  });

  it('reactivates a membership, audits the change and restores an auth user disabled by VestiPro access control', async () => {
    const auth = installAuthMock({
      customClaims: { vestiproAccessDisabled: true, keep: 'value' },
    });
    await seedOrganization('org-1');
    await seedMember({ organizationId: 'org-1', uid: 'owner-1', roleName: 'OWNER' });
    await seedMember({
      organizationId: 'org-1',
      uid: 'rep-1',
      roleName: 'SALES_REP',
      status: 'inactive',
    });
    const wrapped = testEnv.wrap(reactivateUser);

    const result = (await wrapped(
      buildRequest(
        { organizationId: 'org-1', targetUserId: 'rep-1' },
        authFor('owner-1', { name: 'Owner User' }),
      ),
    )) as UpdateUserAccessResponse;

    expect(result.previousStatus).toBe('inactive');
    expect(result.status).toBe('active');

    const membershipSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('rep-1')
      .get();
    expect(membershipSnapshot.data()?.status).toBe('active');
    expect(membershipSnapshot.data()?.version).toBe(2);

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .where('action', '==', 'user.reactivated')
      .get();
    expect(auditSnapshot.size).toBe(1);
    expect(auditSnapshot.docs[0].data().previousValue).toEqual({
      status: 'inactive',
      roleName: 'SALES_REP',
    });
    expect(auditSnapshot.docs[0].data().newValue).toEqual({
      status: 'active',
      roleName: 'SALES_REP',
    });

    expect(auth.updateUser).toHaveBeenCalledWith('rep-1', { disabled: false });
    expect(auth.setCustomUserClaims).toHaveBeenCalledWith('rep-1', {
      keep: 'value',
    });
    expect(auth.revokeRefreshTokens).toHaveBeenCalledWith('rep-1');
  });

  it('does not disable Firebase Auth when the user still has another active organization membership', async () => {
    const auth = installAuthMock();
    await seedOrganization('org-1');
    await seedOrganization('org-2');
    await seedMember({ organizationId: 'org-1', uid: 'owner-1', roleName: 'OWNER' });
    await seedMember({ organizationId: 'org-1', uid: 'rep-1', roleName: 'SALES_REP' });
    await seedMember({ organizationId: 'org-2', uid: 'rep-1', roleName: 'SALES_REP' });
    const wrapped = testEnv.wrap(deactivateUser);

    await wrapped(
      buildRequest(
        { organizationId: 'org-1', targetUserId: 'rep-1' },
        authFor('owner-1'),
      ),
    );

    expect(auth.updateUser).not.toHaveBeenCalledWith('rep-1', {
      disabled: true,
    });
    expect(auth.setCustomUserClaims).not.toHaveBeenCalled();
    expect(auth.revokeRefreshTokens).toHaveBeenCalledWith('rep-1');
  });

  it('blocks deactivating the last active OWNER and writes no audit entry', async () => {
    const auth = installAuthMock({ targetUserId: 'owner-1' });
    await seedOrganization('org-1');
    await seedMember({ organizationId: 'org-1', uid: 'owner-1', roleName: 'OWNER' });
    const wrapped = testEnv.wrap(deactivateUser);

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', targetUserId: 'owner-1' },
          authFor('owner-1'),
        ),
      ),
    ).rejects.toMatchObject({
      code: 'failed-precondition',
      message:
        'Não é possível desativar este usuário porque ele é o último OWNER ativo da organização.',
    });

    const membershipSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('owner-1')
      .get();
    expect(membershipSnapshot.data()?.status).toBe('active');

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.size).toBe(0);
    expect(auth.revokeRefreshTokens).not.toHaveBeenCalled();
    expect(auth.updateUser).not.toHaveBeenCalled();
  });
});
