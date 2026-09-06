import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { HttpsError, type CallableRequest } from 'firebase-functions/v2/https';

import {
  ACCOUNT_DELETION_CONFIRMATION,
  DELETED_USER_LABEL,
  executeAccountDeletion,
  requestAccountDeletionHandler,
  type AccountDeletionRequest,
} from '../../src/privacy/account-deletion';

const PROJECT_ID = 'demo-vestipro-account-deletion-test';
if (getApps().length === 0) initializeApp({ projectId: PROJECT_ID });
const db = getFirestore();

class FakeAuth {
  deleted: string[] = [];
  revoked: string[] = [];
  async deleteUser(uid: string) { this.deleted.push(uid); }
  async revokeRefreshTokens(uid: string) { this.revoked.push(uid); }
}

async function clearFirestore(): Promise<void> {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
}

async function seedMembership(userId: string, roleName = 'SALES_REP') {
  await db.collection('organizations').doc('org-a').set({ name: 'Org A' });
  await db.collection('organizations').doc('org-a').collection('members').doc(userId).set({
    organizationId: 'org-a', userId, roleName, roleId: roleName, teamIds: ['team-a'],
    companyIds: ['company-a'], status: 'active', email: `${userId}@example.test`,
  });
}

describe('account deletion (Firestore Emulator)', () => {
  beforeEach(clearFirestore);
  afterAll(async () => { await clearFirestore(); await db.terminate(); });

  it('anonimiza histórico, preserva terceiros e remove RBAC, push e dados pessoais', async () => {
    await seedMembership('user-a');
    const organization = db.collection('organizations').doc('org-a');
    await db.collection('users').doc('user-a').set({ uid: 'user-a', name: 'Ana', email: 'ana@example.test' });
    await db.collection('users').doc('user-a').collection('consentRecords').doc('consent').set({ userId: 'user-a' });
    await organization.collection('pushDevices').doc('device-a').set({ userId: 'user-a', token: 'secret' });
    await organization.collection('communicationPreferences').doc('user-a').set({ userId: 'user-a' });
    await organization.collection('teams').doc('team-a').set({
      memberIds: ['user-a', 'user-b'], managerId: 'user-a', managerName: 'Ana',
    });
    await organization.collection('customers').doc('customer-a').set({ name: 'Loja preservada' });
    await organization.collection('orders').doc('order-a').set({ sellerId: 'user-a', sellerName: 'Ana' });
    await organization.collection('orders').doc('order-b').set({ sellerId: 'user-b', sellerName: 'Bia' });
    await organization.collection('opportunities').doc('opportunity-a').set({ responsibleUserId: 'user-a' });

    const auth = new FakeAuth();
    const result = await executeAccountDeletion({
      db, auth, organizationId: 'org-a', userId: 'user-a',
      now: new Date('2026-09-05T12:00:00Z'),
    });

    expect(result.anonymizedRecords).toBeGreaterThanOrEqual(4);
    expect((await organization.collection('customers').doc('customer-a').get()).exists).toBe(true);
    expect((await organization.collection('orders').doc('order-b').get()).data()?.sellerName).toBe('Bia');
    expect((await organization.collection('orders').doc('order-a').get()).data()?.sellerName).toBe(DELETED_USER_LABEL);
    expect((await organization.collection('members').doc('user-a').get()).data()).toMatchObject({
      status: 'deleted', teamIds: [], companyIds: [], displayName: DELETED_USER_LABEL,
    });
    expect((await organization.collection('pushDevices').get()).empty).toBe(true);
    expect((await organization.collection('teams').doc('team-a').get()).data()).toMatchObject({
      memberIds: ['user-b'], managerName: DELETED_USER_LABEL,
    });
    expect((await db.collection('users').doc('user-a').collection('consentRecords').get()).empty).toBe(true);
    const audits = await organization.collection('auditLogs').get();
    expect(audits.docs[0].data().metadata).toMatchObject({ cascadeDeletion: false });
    expect(audits.docs[0].data().metadata.retained).toHaveLength(2);
    expect(auth.deleted).toEqual(['user-a']);
    expect(auth.revoked).toEqual(['user-a']);
  });

  it('bloqueia o único OWNER sem alterar a organização', async () => {
    await seedMembership('owner-a', 'OWNER');
    await expect(executeAccountDeletion({
      db, auth: new FakeAuth(), organizationId: 'org-a', userId: 'owner-a',
    })).rejects.toMatchObject({ code: 'failed-precondition' });
    expect((await db.collection('organizations').doc('org-a').collection('members').doc('owner-a').get()).data()?.status).toBe('active');
  });

  it('bloqueia antes de mutar quando é único OWNER em outro tenant', async () => {
    await seedMembership('user-a');
    await db.collection('organizations').doc('org-b').set({ name: 'Org B' });
    await db.collection('organizations').doc('org-b').collection('members').doc('user-a').set({
      organizationId: 'org-b', userId: 'user-a', roleName: 'OWNER',
      status: 'active', email: 'ana@example.test',
    });

    await expect(executeAccountDeletion({
      db, auth: new FakeAuth(), organizationId: 'org-a', userId: 'user-a',
    })).rejects.toMatchObject({ code: 'failed-precondition' });
    expect((await db.collection('organizations').doc('org-a').collection('members').doc('user-a').get()).data()?.status).toBe('active');
  });

  it('exige frase exata e autenticação recente', async () => {
    const auth = new FakeAuth();
    const request = (confirmation: string, authTime: number): CallableRequest<AccountDeletionRequest> => ({
      data: { organizationId: 'org-a', confirmation },
      auth: { uid: 'user-a', token: { auth_time: authTime }, rawToken: 'token' } as never,
      rawRequest: {} as never,
      acceptsStreaming: false,
    });
    const now = new Date('2026-09-05T12:00:00Z');
    await expect(requestAccountDeletionHandler(request('errado', now.getTime() / 1000), { db, auth, now }))
      .rejects.toBeInstanceOf(HttpsError);
    await expect(requestAccountDeletionHandler(request(ACCOUNT_DELETION_CONFIRMATION, now.getTime() / 1000 - 301), { db, auth, now }))
      .rejects.toMatchObject({ code: 'failed-precondition' });
  });
});
