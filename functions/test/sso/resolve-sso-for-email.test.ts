import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  resolveSsoForEmail,
  type ResolveSsoForEmailRequest,
  type ResolveSsoForEmailResponse,
} from '../../src/sso/resolve-sso-for-email';

const PROJECT_ID = 'demo-vestipro-sso-resolve-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: ResolveSsoForEmailRequest,
): CallableRequest<ResolveSsoForEmailRequest> {
  return {
    data,
    auth: undefined,
    rawRequest: {} as CallableRequest<ResolveSsoForEmailRequest>['rawRequest'],
    acceptsStreaming: false,
  };
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

describe('resolveSsoForEmail', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it('resolves the organization/protocol/providerId for a known, active domain', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedSsoConnection('org-1', 'conn-1');
    const wrapped = testEnv.wrap(resolveSsoForEmail);

    const result = (await wrapped(
      buildRequest({ email: 'Ana.Souza@Malwee.COM.br' }),
    )) as ResolveSsoForEmailResponse;

    expect(result.found).toBe(true);
    expect(result.organizationId).toBe('org-1');
    expect(result.organizationName).toBe('Grupo Fashion XPTO');
    expect(result.protocol).toBe('oidc');
    expect(result.providerId).toBe('oidc.conn-1');
  });

  it('reports found:false for a domain with no SSO connection at all, without leaking anything', async () => {
    const wrapped = testEnv.wrap(resolveSsoForEmail);

    const result = (await wrapped(
      buildRequest({ email: 'ana@dominio-desconhecido.com' }),
    )) as ResolveSsoForEmailResponse;

    expect(result.found).toBe(false);
    expect(result.organizationId).toBeNull();
    expect(result.organizationName).toBeNull();
    expect(result.protocol).toBeNull();
    expect(result.providerId).toBeNull();
  });

  it('never resolves a disabled connection', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedSsoConnection('org-1', 'conn-1', { status: 'disabled' });
    const wrapped = testEnv.wrap(resolveSsoForEmail);

    const result = (await wrapped(
      buildRequest({ email: 'ana@malwee.com.br' }),
    )) as ResolveSsoForEmailResponse;

    expect(result.found).toBe(false);
  });

  it('never resolves a connection left invalid_config — fail-safe, never grants a login route', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedSsoConnection('org-1', 'conn-1', {
      status: 'invalid_config',
      lastConfigError: 'Certificado inválido',
    });
    const wrapped = testEnv.wrap(resolveSsoForEmail);

    const result = (await wrapped(
      buildRequest({ email: 'ana@malwee.com.br' }),
    )) as ResolveSsoForEmailResponse;

    expect(result.found).toBe(false);
  });

  it('isolation: each domain resolves only to the organization that registered it', async () => {
    await seedOrganization('org-1', 'Grupo Fashion XPTO');
    await seedOrganization('org-2', 'Outra Confecção');
    await seedSsoConnection('org-1', 'conn-1', { emailDomains: ['malwee.com.br'] });
    await seedSsoConnection('org-2', 'conn-2', { emailDomains: ['outraconfeccao.com.br'] });
    const wrapped = testEnv.wrap(resolveSsoForEmail);

    const resultOrg1 = (await wrapped(
      buildRequest({ email: 'ana@malwee.com.br' }),
    )) as ResolveSsoForEmailResponse;
    const resultOrg2 = (await wrapped(
      buildRequest({ email: 'joao@outraconfeccao.com.br' }),
    )) as ResolveSsoForEmailResponse;

    expect(resultOrg1.organizationId).toBe('org-1');
    expect(resultOrg2.organizationId).toBe('org-2');
  });

  it('rejects a malformed e-mail', async () => {
    const wrapped = testEnv.wrap(resolveSsoForEmail);

    await expect(
      wrapped(buildRequest({ email: 'nao-e-um-email' })),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
