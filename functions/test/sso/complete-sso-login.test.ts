import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  completeSsoLogin,
  type CompleteSsoLoginRequest,
  type CompleteSsoLoginResponse,
} from '../../src/sso/complete-sso-login';

const PROJECT_ID = 'demo-vestipro-sso-complete-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: CompleteSsoLoginRequest,
  auth?: CallableRequest<CompleteSsoLoginRequest>['auth'],
): CallableRequest<CompleteSsoLoginRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<CompleteSsoLoginRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function federatedAuth(
  uid: string,
  email: string,
  signInProvider: string,
): CallableRequest<CompleteSsoLoginRequest>['auth'] {
  return {
    uid,
    token: { email, firebase: { sign_in_provider: signInProvider } },
    rawToken: 'raw-token',
  } as unknown as CallableRequest<CompleteSsoLoginRequest>['auth'];
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

async function seedSsoConnection(
  organizationId: string,
  connectionId: string,
  overrides: Record<string, unknown> = {},
): Promise<void> {
  const now = Timestamp.now();
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('ssoConnections')
    .doc(connectionId)
    .set({
      organizationId,
      protocol: 'oidc',
      providerId: `oidc.${connectionId}`,
      displayName: 'Azure AD',
      emailDomains: ['malwee.com.br'],
      defaultRoleName: 'SALES_REP',
      status: 'active',
      lastConfigError: null,
      createdAt: now,
      createdBy: 'owner-1',
      updatedAt: now,
      updatedBy: 'owner-1',
      version: 1,
      ...overrides,
    });
}

async function seedMembership(
  organizationId: string,
  uid: string,
  overrides: Record<string, unknown> = {},
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
      roleId: 'SALES_MANAGER',
      roleName: 'SALES_MANAGER',
      teamIds: [],
      status: 'active',
      version: 1,
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
      deletedAt: null,
      ...overrides,
    });
}

describe('completeSsoLogin', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('JIT-provisions a brand-new Membership with the connection\'s defaultRoleName on first login', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedSsoConnection('org-1', 'conn-1');
    const wrapped = testEnv.wrap(completeSsoLogin);

    const result = (await wrapped(
      buildRequest({}, federatedAuth('new-user-1', 'ana@malwee.com.br', 'oidc.conn-1')),
    )) as CompleteSsoLoginResponse;

    expect(result.organizationId).toBe('org-1');
    expect(result.roleName).toBe('SALES_REP');
    expect(result.provisioned).toBe(true);

    const membershipSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('new-user-1')
      .get();
    expect(membershipSnapshot.exists).toBe(true);
    expect(membershipSnapshot.data()?.roleName).toBe('SALES_REP');
    expect(membershipSnapshot.data()?.status).toBe('active');
    expect(membershipSnapshot.data()?.email).toBe('ana@malwee.com.br');

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.size).toBe(1);
    expect(auditSnapshot.docs[0].data().action).toBe('user.ssoLoginProvisioned');
  });

  it('never provisions with an administrative role — defaultRoleName itself can only ever be a non-admin role', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    // A defaultRoleName of OWNER/ADMIN can never reach Firestore in the
    // first place — `configureSsoConnection`'s own `validateDefaultRoleName`
    // rejects it at configuration time (see its own unit test). This
    // documents the invariant `completeSsoLogin` relies on instead of
    // re-validating it a second time: whatever `defaultRoleName` is stored
    // is exactly what a first login is provisioned with, verbatim.
    await seedSsoConnection('org-1', 'conn-1', { defaultRoleName: 'SALES_ASSISTANT' });
    const wrapped = testEnv.wrap(completeSsoLogin);

    const result = (await wrapped(
      buildRequest({}, federatedAuth('new-user-1', 'ana@malwee.com.br', 'oidc.conn-1')),
    )) as CompleteSsoLoginResponse;

    expect(result.roleName).toBe('SALES_ASSISTANT');
    expect(result.roleName).not.toBe('OWNER');
    expect(result.roleName).not.toBe('ADMIN');
  });

  it('preserves an existing Membership\'s role on a subsequent login, even if an admin changed it after the first login', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedSsoConnection('org-1', 'conn-1', { defaultRoleName: 'SALES_REP' });
    await seedMembership('org-1', 'existing-user', { roleId: 'SALES_MANAGER', roleName: 'SALES_MANAGER' });
    const wrapped = testEnv.wrap(completeSsoLogin);

    const result = (await wrapped(
      buildRequest({}, federatedAuth('existing-user', 'ana@malwee.com.br', 'oidc.conn-1')),
    )) as CompleteSsoLoginResponse;

    expect(result.provisioned).toBe(false);
    expect(result.roleName).toBe('SALES_MANAGER');

    const membershipSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('existing-user')
      .get();
    expect(membershipSnapshot.data()?.roleName).toBe('SALES_MANAGER');
    expect(membershipSnapshot.data()?.version).toBe(2);

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.docs[0].data().action).toBe('user.ssoLogin');
  });

  it('rejects a non-federated session (e.g. e-mail/senha) trying to call this directly', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedSsoConnection('org-1', 'conn-1');
    const wrapped = testEnv.wrap(completeSsoLogin);

    await expect(
      wrapped(buildRequest({}, federatedAuth('user-1', 'ana@malwee.com.br', 'password'))),
    ).rejects.toMatchObject({ code: 'permission-denied' });

    const membershipSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('user-1')
      .get();
    expect(membershipSnapshot.exists).toBe(false);
  });

  it('rejects an unauthenticated call', async () => {
    const wrapped = testEnv.wrap(completeSsoLogin);

    await expect(wrapped(buildRequest({}))).rejects.toMatchObject({
      code: 'unauthenticated',
    });
  });

  it('rejects when the connection is disabled/invalid_config — never grants access by fallback', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedSsoConnection('org-1', 'conn-1', { status: 'invalid_config' });
    const wrapped = testEnv.wrap(completeSsoLogin);

    await expect(
      wrapped(buildRequest({}, federatedAuth('new-user-1', 'ana@malwee.com.br', 'oidc.conn-1'))),
    ).rejects.toMatchObject({ code: 'failed-precondition' });

    const membershipSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('new-user-1')
      .get();
    expect(membershipSnapshot.exists).toBe(false);
  });

  it('rejects when the IdP-asserted e-mail domain is not one of the connection\'s own domains', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedSsoConnection('org-1', 'conn-1', { emailDomains: ['malwee.com.br'] });
    const wrapped = testEnv.wrap(completeSsoLogin);

    await expect(
      wrapped(
        buildRequest(
          {},
          federatedAuth('new-user-1', 'ana@dominio-nao-autorizado.com', 'oidc.conn-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('never reactivates a Membership an administrator deactivated', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedSsoConnection('org-1', 'conn-1');
    await seedMembership('org-1', 'deactivated-user', { status: 'inactive' });
    const wrapped = testEnv.wrap(completeSsoLogin);

    await expect(
      wrapped(
        buildRequest({}, federatedAuth('deactivated-user', 'ana@malwee.com.br', 'oidc.conn-1')),
      ),
    ).rejects.toMatchObject({ code: 'permission-denied' });

    const membershipSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('deactivated-user')
      .get();
    expect(membershipSnapshot.data()?.status).toBe('inactive');
  });

  it('isolation: a providerId registered to one organization only ever resolves that organization\'s connection', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedOrganization('org-2', 'Outra Confecção');
    await seedSsoConnection('org-1', 'conn-1', { emailDomains: ['malwee.com.br'] });
    await seedSsoConnection('org-2', 'conn-2', {
      providerId: 'oidc.conn-2',
      emailDomains: ['outraconfeccao.com.br'],
      defaultRoleName: 'FINANCE',
    });
    const wrapped = testEnv.wrap(completeSsoLogin);

    const result = (await wrapped(
      buildRequest(
        {},
        federatedAuth('user-org-2', 'joao@outraconfeccao.com.br', 'oidc.conn-2'),
      ),
    )) as CompleteSsoLoginResponse;

    expect(result.organizationId).toBe('org-2');
    expect(result.roleName).toBe('FINANCE');

    const org1Membership = await db
      .collection('organizations')
      .doc('org-1')
      .collection('members')
      .doc('user-org-2')
      .get();
    expect(org1Membership.exists).toBe(false);
  });
});
