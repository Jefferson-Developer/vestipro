import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  configureSsoConnection,
  type ConfigureSsoConnectionRequest,
  type ConfigureSsoConnectionResponse,
} from '../../src/sso/configure-sso-connection';

const PROJECT_ID = 'demo-vestipro-sso-configure-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: ConfigureSsoConnectionRequest,
  auth?: CallableRequest<ConfigureSsoConnectionRequest>['auth'],
): CallableRequest<ConfigureSsoConnectionRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<ConfigureSsoConnectionRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(uid: string): CallableRequest<ConfigureSsoConnectionRequest>['auth'] {
  return {
    uid,
    token: { email: `${uid}@vestipro.com.br` },
    rawToken: 'raw-token',
  } as CallableRequest<ConfigureSsoConnectionRequest>['auth'];
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

async function seedMembership(
  organizationId: string,
  uid: string,
  roleName: string,
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
      status: 'active',
      version: 1,
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
      deletedAt: null,
    });
}

const oidcRequestBody = (organizationId: string): ConfigureSsoConnectionRequest => ({
  organizationId,
  protocol: 'oidc',
  displayName: 'Azure AD',
  emailDomains: ['malwee.com.br'],
  defaultRoleName: 'SALES_REP',
  oidc: { clientId: 'client-1', issuer: 'https://login.microsoftonline.com/tenant/v2.0' },
});

describe('configureSsoConnection', () => {
  let createProviderConfigSpy: jest.SpyInstance;
  let updateProviderConfigSpy: jest.SpyInstance;

  beforeEach(() => {
    createProviderConfigSpy = jest
      .spyOn(getAuth(), 'createProviderConfig')
      .mockImplementation((config) => Promise.resolve(config as never));
    updateProviderConfigSpy = jest
      .spyOn(getAuth(), 'updateProviderConfig')
      .mockImplementation((_providerId, config) => Promise.resolve(config as never));
  });

  afterEach(async () => {
    createProviderConfigSpy.mockRestore();
    updateProviderConfigSpy.mockRestore();
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('rejects a caller without an active Membership', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    const wrapped = testEnv.wrap(configureSsoConnection);

    await expect(
      wrapped(buildRequest(oidcRequestBody('org-1'), authFor('stranger'))),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it.each(['SALES_MANAGER', 'SALES_REP', 'SALES_ASSISTANT', 'FINANCE', 'READ_ONLY'])(
    'rejects a caller whose role is %s (only OWNER/ADMIN can configure SSO)',
    async (roleName) => {
      await seedOrganization('org-1', 'Grupo Fashion XPTO');
      await seedMembership('org-1', 'caller-1', roleName);
      const wrapped = testEnv.wrap(configureSsoConnection);

      await expect(
        wrapped(buildRequest(oidcRequestBody('org-1'), authFor('caller-1'))),
      ).rejects.toMatchObject({ code: 'permission-denied' });
      expect(createProviderConfigSpy).not.toHaveBeenCalled();
    },
  );

  it.each(['OWNER', 'ADMIN'])(
    'rejects a defaultRoleName of OWNER/ADMIN even from a caller who is %s',
    async (roleName) => {
      await seedOrganization('org-1', 'Grupo Fashion XPTO');
      await seedMembership('org-1', 'caller-1', roleName);
      const wrapped = testEnv.wrap(configureSsoConnection);

      await expect(
        wrapped(
          buildRequest(
            { ...oidcRequestBody('org-1'), defaultRoleName: 'ADMIN' },
            authFor('caller-1'),
          ),
        ),
      ).rejects.toMatchObject({ code: 'invalid-argument' });
      expect(createProviderConfigSpy).not.toHaveBeenCalled();
    },
  );

  it('persists an active connection and registers it with Identity Platform on success', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedMembership('org-1', 'owner-1', 'OWNER');
    const wrapped = testEnv.wrap(configureSsoConnection);

    const result = (await wrapped(
      buildRequest(oidcRequestBody('org-1'), authFor('owner-1')),
    )) as ConfigureSsoConnectionResponse;

    expect(result.status).toBe('active');
    expect(result.providerId).toBe(`oidc.${result.connectionId}`);
    expect(createProviderConfigSpy).toHaveBeenCalledTimes(1);

    const connectionSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('ssoConnections')
      .doc(result.connectionId)
      .get();
    expect(connectionSnapshot.data()?.status).toBe('active');
    expect(connectionSnapshot.data()?.emailDomains).toEqual(['malwee.com.br']);
    expect(connectionSnapshot.data()?.defaultRoleName).toBe('SALES_REP');

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.size).toBe(1);
    expect(auditSnapshot.docs[0].data().action).toBe('sso.connectionConfigured');
  });

  it(
    'persists status:invalid_config and rejects the call when Identity Platform rejects the ' +
      'metadata (IdP mock simulating a configuration error) — never grants access by fallback',
    async () => {
      await seedOrganization('org-1', 'Grupo Fashion XPTO');
      await seedMembership('org-1', 'owner-1', 'OWNER');
      createProviderConfigSpy.mockImplementation(() =>
        Promise.reject(new Error('Certificado X.509 inválido ou expirado')),
      );
      const wrapped = testEnv.wrap(configureSsoConnection);

      await expect(
        wrapped(buildRequest(oidcRequestBody('org-1'), authFor('owner-1'))),
      ).rejects.toMatchObject({ code: 'failed-precondition' });

      const connectionsSnapshot = await db
        .collection('organizations')
        .doc('org-1')
        .collection('ssoConnections')
        .get();
      expect(connectionsSnapshot.size).toBe(1);
      expect(connectionsSnapshot.docs[0].data().status).toBe('invalid_config');
      expect(connectionsSnapshot.docs[0].data().lastConfigError).toContain('Certificado X.509');
    },
  );

  it(
    'isolation: rejects a domain already claimed by another organization\'s connection, ' +
      'without persisting a new connection for the second organization',
    async () => {
      await seedOrganization('org-1', 'Grupo Fashion XPTO');
      await seedOrganization('org-2', 'Outra Confecção');
      await seedMembership('org-1', 'owner-1', 'OWNER');
      await seedMembership('org-2', 'owner-2', 'OWNER');
      const wrapped = testEnv.wrap(configureSsoConnection);

      await wrapped(buildRequest(oidcRequestBody('org-1'), authFor('owner-1')));

      await expect(
        wrapped(buildRequest(oidcRequestBody('org-2'), authFor('owner-2'))),
      ).rejects.toMatchObject({ code: 'already-exists' });

      const org2Connections = await db
        .collection('organizations')
        .doc('org-2')
        .collection('ssoConnections')
        .get();
      expect(org2Connections.size).toBe(0);
    },
  );

  it('updates an existing connection in place, bumping its version', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedMembership('org-1', 'owner-1', 'OWNER');
    const wrapped = testEnv.wrap(configureSsoConnection);

    const created = (await wrapped(
      buildRequest(oidcRequestBody('org-1'), authFor('owner-1')),
    )) as ConfigureSsoConnectionResponse;

    const updated = (await wrapped(
      buildRequest(
        {
          ...oidcRequestBody('org-1'),
          connectionId: created.connectionId,
          displayName: 'Azure AD (renomeado)',
        },
        authFor('owner-1'),
      ),
    )) as ConfigureSsoConnectionResponse;

    expect(updated.connectionId).toBe(created.connectionId);
    expect(updateProviderConfigSpy).toHaveBeenCalledTimes(1);

    const connectionSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('ssoConnections')
      .doc(created.connectionId)
      .get();
    expect(connectionSnapshot.data()?.displayName).toBe('Azure AD (renomeado)');
    expect(connectionSnapshot.data()?.version).toBe(2);
  });
});
