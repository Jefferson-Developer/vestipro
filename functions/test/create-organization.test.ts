import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';
import {
  createOrganization,
  type CreateOrganizationRequest,
  type CreateOrganizationResponse,
} from '../src/organizations/create-organization';

// A dedicated (fake) project id, isolated from every other emulator-backed
// test suite in this repository (e.g. `firestore-tests/`, which uses its
// own `vestipro-rules-test`) — this file talks to the Firestore emulator
// (`FIRESTORE_EMULATOR_HOST`, set by `firebase emulators:exec`) through the
// real Admin SDK, exactly like production `createOrganization` does; only
// `request.auth` is faked, via `firebase-functions-test`'s `wrap`.
const PROJECT_ID = 'demo-vestipro-functions-test';

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT_ID });
}

const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function buildRequest(
  data: CreateOrganizationRequest,
  auth?: CallableRequest<CreateOrganizationRequest>['auth'],
): CallableRequest<CreateOrganizationRequest> {
  return {
    data,
    auth,
    rawRequest: {} as CallableRequest<CreateOrganizationRequest>['rawRequest'],
    acceptsStreaming: false,
  };
}

function authFor(
  uid: string,
  token: Record<string, unknown> = {},
): CallableRequest<CreateOrganizationRequest>['auth'] {
  return {
    uid,
    token,
    rawToken: 'raw-token',
  } as CallableRequest<CreateOrganizationRequest>['auth'];
}

async function clearFirestore(): Promise<void> {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
}

describe('createOrganization', () => {
  afterEach(async () => {
    await clearFirestore();
  });

  afterAll(async () => {
    testEnv.cleanup();
    await db.terminate();
  });

  it(
    'creates the organization, seeds the 7 system roles, grants the caller ' +
      'the OWNER membership and records an audit log entry',
    async () => {
      const wrapped = testEnv.wrap(createOrganization);

      const result = (await wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            name: 'Grupo Fashion XPTO',
            slug: 'grupo-fashion-xpto',
            currency: 'BRL',
            country: 'BR',
            defaultLanguage: 'pt-BR',
          },
          authFor('user-1'),
        ),
      )) as CreateOrganizationResponse;

      expect(result.alreadyExisted).toBe(false);
      expect(result.organization.id).toBe('org-1');
      expect(result.organization.name).toBe('Grupo Fashion XPTO');
      expect(result.organization.createdBy).toBe('user-1');
      expect(result.organization.status).toBe('active');
      expect(result.organization.settings).toEqual({
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
      });
      expect(new Date(result.organization.createdAt).toString()).not.toBe('Invalid Date');

      const organizationRef = db.collection('organizations').doc('org-1');

      const orgSnapshot = await organizationRef.get();
      expect(orgSnapshot.exists).toBe(true);

      const roleIds = (await organizationRef.collection('roles').get()).docs.map(
        (doc) => doc.id,
      );
      expect(roleIds.sort()).toEqual(
        [
          'ADMIN',
          'FINANCE',
          'OWNER',
          'READ_ONLY',
          'SALES_ASSISTANT',
          'SALES_MANAGER',
          'SALES_REP',
        ].sort(),
      );

      const membershipSnapshot = await organizationRef.collection('members').doc('user-1').get();
      expect(membershipSnapshot.exists).toBe(true);
      expect(membershipSnapshot.data()?.roleId).toBe('OWNER');
      expect(membershipSnapshot.data()?.roleName).toBe('OWNER');
      expect(membershipSnapshot.data()?.status).toBe('active');

      const ownerMarkerSnapshot = await db.collection('organizationOwners').doc('user-1').get();
      expect(ownerMarkerSnapshot.exists).toBe(true);
      expect(ownerMarkerSnapshot.data()?.organizationId).toBe('org-1');

      const auditSnapshot = await organizationRef.collection('auditLogs').get();
      expect(auditSnapshot.size).toBe(1);
      expect(auditSnapshot.docs[0].data().action).toBe('organization.created');
      expect(auditSnapshot.docs[0].data().actorUserId).toBe('user-1');
      expect(auditSnapshot.docs[0].data().entityId).toBe('org-1');
    },
  );

  it('persists and returns the optional segment when provided, and omits it ' +
    'entirely from settings when not provided', async () => {
    const wrapped = testEnv.wrap(createOrganization);

    const withSegment = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          name: 'Grupo Fashion XPTO',
          slug: 'grupo-fashion-xpto',
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
          segment: 'apparel',
        },
        authFor('user-1'),
      ),
    )) as CreateOrganizationResponse;

    expect(withSegment.organization.settings).toEqual({
      currency: 'BRL',
      country: 'BR',
      defaultLanguage: 'pt-BR',
      segment: 'apparel',
    });

    const withoutSegment = (await wrapped(
      buildRequest(
        {
          organizationId: 'org-2',
          name: 'Outra Organização',
          slug: 'outra-organizacao',
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
        },
        authFor('user-2'),
      ),
    )) as CreateOrganizationResponse;

    expect(withoutSegment.organization.settings).toEqual({
      currency: 'BRL',
      country: 'BR',
      defaultLanguage: 'pt-BR',
    });
  });

  it(
    'is idempotent: a retry from the same uid returns the already-created ' +
      'organization instead of creating a duplicate, even when the retry ' +
      'carries a different organizationId',
    async () => {
      const wrapped = testEnv.wrap(createOrganization);

      const first = (await wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            name: 'Grupo Fashion XPTO',
            slug: 'grupo-fashion-xpto',
            currency: 'BRL',
            country: 'BR',
            defaultLanguage: 'pt-BR',
          },
          authFor('user-1'),
        ),
      )) as CreateOrganizationResponse;

      const retry = (await wrapped(
        buildRequest(
          {
            organizationId: 'org-2',
            name: 'Outro Nome',
            slug: 'outro-nome',
            currency: 'USD',
            country: 'US',
            defaultLanguage: 'en-US',
          },
          authFor('user-1'),
        ),
      )) as CreateOrganizationResponse;

      expect(first.alreadyExisted).toBe(false);
      expect(retry.alreadyExisted).toBe(true);
      expect(retry.organization.id).toBe('org-1');
      expect(retry.organization.name).toBe('Grupo Fashion XPTO');

      const secondOrgSnapshot = await db.collection('organizations').doc('org-2').get();
      expect(secondOrgSnapshot.exists).toBe(false);

      const allOrganizations = await db.collection('organizations').get();
      expect(allOrganizations.size).toBe(1);
    },
  );

  it(
    'rolls back every write when the transaction fails midway, leaving no ' +
      'partial state (never an Organization without an OWNER)',
    async () => {
      // Simulates a mid-transaction failure by pre-corrupting the
      // would-be OWNER role document: the defensive consistency check in
      // create-organization.ts throws once it finds this, before any write
      // is staged — the whole point of this test is proving nothing else
      // (Organization, Membership, owner marker) got created either.
      await db
        .collection('organizations')
        .doc('org-1')
        .collection('roles')
        .doc('OWNER')
        .set({ corrupted: true });

      const wrapped = testEnv.wrap(createOrganization);

      await expect(
        wrapped(
          buildRequest(
            {
              organizationId: 'org-1',
              name: 'Grupo Fashion XPTO',
              slug: 'grupo-fashion-xpto',
              currency: 'BRL',
              country: 'BR',
              defaultLanguage: 'pt-BR',
            },
            authFor('user-1'),
          ),
        ),
      ).rejects.toMatchObject({ code: 'internal' });

      const organizationRef = db.collection('organizations').doc('org-1');

      expect((await organizationRef.get()).exists).toBe(false);
      expect((await organizationRef.collection('members').doc('user-1').get()).exists).toBe(
        false,
      );
      expect((await db.collection('organizationOwners').doc('user-1').get()).exists).toBe(false);

      // The corrupted role document itself is untouched by the rollback.
      const roleSnapshot = await organizationRef.collection('roles').doc('OWNER').get();
      expect(roleSnapshot.data()).toEqual({ corrupted: true });
    },
  );

  it('rejects an unauthenticated call without writing anything', async () => {
    const wrapped = testEnv.wrap(createOrganization);

    await expect(
      wrapped(
        buildRequest({
          organizationId: 'org-1',
          name: 'Grupo Fashion XPTO',
          slug: 'grupo-fashion-xpto',
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
        }),
      ),
    ).rejects.toMatchObject({ code: 'unauthenticated' });

    const allOrganizations = await db.collection('organizations').get();
    expect(allOrganizations.size).toBe(0);
  });

  it('rejects a payload with a blank required field', async () => {
    const wrapped = testEnv.wrap(createOrganization);

    await expect(
      wrapped(
        buildRequest(
          {
            organizationId: 'org-1',
            name: '   ',
            slug: 'grupo-fashion-xpto',
            currency: 'BRL',
            country: 'BR',
            defaultLanguage: 'pt-BR',
          },
          authFor('user-1'),
        ),
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });

    const allOrganizations = await db.collection('organizations').get();
    expect(allOrganizations.size).toBe(0);
  });

  it("uses the caller's users/{uid} profile name as the audit log actorName when present", async () => {
    await db.collection('users').doc('user-1').set({ name: 'Ana Souza' });

    const wrapped = testEnv.wrap(createOrganization);
    await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          name: 'Grupo Fashion XPTO',
          slug: 'grupo-fashion-xpto',
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
        },
        authFor('user-1'),
      ),
    );

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.docs[0].data().actorName).toBe('Ana Souza');
  });

  it("falls back to the auth token's name when there is no users/{uid} profile", async () => {
    const wrapped = testEnv.wrap(createOrganization);
    await wrapped(
      buildRequest(
        {
          organizationId: 'org-1',
          name: 'Grupo Fashion XPTO',
          slug: 'grupo-fashion-xpto',
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
        },
        authFor('user-1', { name: 'Token Name' }),
      ),
    );

    const auditSnapshot = await db
      .collection('organizations')
      .doc('org-1')
      .collection('auditLogs')
      .get();
    expect(auditSnapshot.docs[0].data().actorName).toBe('Token Name');
  });
});
