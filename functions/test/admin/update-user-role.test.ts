import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  updateUserRole,
  type UpdateUserRoleRequest,
  type UpdateUserRoleResponse,
} from '../../src/admin/update-user-role';

const PROJECT_ID = 'demo-vestipro-admin-update-user-role-test';

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

function buildRequest(
  data: UpdateUserRoleRequest,
  auth?: CallableRequest<UpdateUserRoleRequest>['auth'],
): CallableRequest<UpdateUserRoleRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<UpdateUserRoleRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<UpdateUserRoleRequest>['auth'] {
  return {
    uid,
    token,
    rawToken: 'raw-token',
  } as CallableRequest<UpdateUserRoleRequest>['auth'];
}

async function clearFirestore(): Promise<void> {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
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

async function seedMember(
  organizationId: string,
  uid: string,
  roleName: string,
  status = 'active',
): Promise<void> {
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
      status,
      version: 1,
      createdAt: now,
      createdBy: 'owner-1',
      updatedAt: now,
      updatedBy: 'owner-1',
      deletedAt: null,
    });
}

describe('updateUserRole', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('updates a valid target membership and records exactly one audit entry', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    const wrapped = testEnv.wrap(updateUserRole);

    const result = (await wrapped(
      buildRequest(
        { organizationId: 'org-1', targetUserId: 'rep-1', roleName: 'ADMIN' },
        authFor('owner-1', { name: 'Owner User' }),
      ),
    )) as UpdateUserRoleResponse;

    expect(result.previousRoleName).toBe('SALES_REP');
    expect(result.roleName).toBe('ADMIN');
    expect(result.targetUserId).toBe('rep-1');
    expect(new Date(result.updatedAt).toString()).not.toBe('Invalid Date');

    const membershipSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('rep-1')
      .get();
    expect(membershipSnapshot.data()?.roleId).toBe('ADMIN');
    expect(membershipSnapshot.data()?.roleName).toBe('ADMIN');
    expect(membershipSnapshot.data()?.updatedBy).toBe('owner-1');
    expect(membershipSnapshot.data()?.version).toBe(2);

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.size).toBe(1);
    const audit = auditSnapshot.docs[0].data();
    expect(audit.actorUserId).toBe('owner-1');
    expect(audit.targetUserId).toBe('rep-1');
    expect(audit.action).toBe('user.roleUpdated');
    expect(audit.previousValue).toEqual({ roleName: 'SALES_REP' });
    expect(audit.newValue).toEqual({ roleName: 'ADMIN' });
    expect(audit.timestamp).toBeInstanceOf(Timestamp);
  });

  it('blocks demoting the last active OWNER and writes no audit entry', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    const wrapped = testEnv.wrap(updateUserRole);

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', targetUserId: 'owner-1', roleName: 'ADMIN' },
          authFor('owner-1'),
        ),
      ),
    ).rejects.toMatchObject({
      code: 'failed-precondition',
      message:
        'Não é possível alterar este perfil porque ele é o último OWNER ativo da organização.',
    });

    const membershipSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('owner-1')
      .get();
    expect(membershipSnapshot.data()?.roleName).toBe('OWNER');

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.size).toBe(0);
  });

  it('rejects a caller without user.changeRole permission', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    await seedMember('org-1', 'rep-2', 'SALES_REP');
    const wrapped = testEnv.wrap(updateUserRole);

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', targetUserId: 'rep-2', roleName: 'READ_ONLY' },
          authFor('rep-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.size).toBe(0);
  });

  it('rejects an invalid self-promotion to a more privileged role', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'admin-1', 'ADMIN');
    const wrapped = testEnv.wrap(updateUserRole);

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', targetUserId: 'admin-1', roleName: 'OWNER' },
          authFor('admin-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });

    const membershipSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('admin-1')
      .get();
    expect(membershipSnapshot.data()?.roleName).toBe('ADMIN');
  });

  it('rejects an unknown target role', async () => {
    await seedOrganization('org-1');
    await seedMember('org-1', 'owner-1', 'OWNER');
    await seedMember('org-1', 'rep-1', 'SALES_REP');
    const wrapped = testEnv.wrap(updateUserRole);

    await expect(
      wrapped(
        buildRequest(
          { organizationId: 'org-1', targetUserId: 'rep-1', roleName: 'NOT_A_ROLE' },
          authFor('owner-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
