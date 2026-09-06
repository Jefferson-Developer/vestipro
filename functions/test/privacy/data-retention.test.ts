import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { type CallableRequest } from 'firebase-functions/v2/https';

import {
  DEFAULT_RETENTION_DAYS,
  MINIMUM_RETENTION_DAYS,
  PERSONAL_DATA_MINIMIZATION_CONTRACT,
  applyRetentionForOrganization,
  resolveRetentionDays,
  updateDataRetentionPolicyHandler,
  type UpdateDataRetentionPolicyRequest,
} from '../../src/privacy/data-retention';

const PROJECT_ID = 'demo-vestipro-data-retention-test';
if (getApps().length === 0) initializeApp({ projectId: PROJECT_ID });
const db = getFirestore();
const now = new Date('2026-09-05T12:00:00Z');

async function clearFirestore(): Promise<void> {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
}

async function seedOrganization(): Promise<FirebaseFirestore.DocumentReference> {
  const organization = db.collection('organizations').doc('org-a');
  await organization.set({ name: 'Org A', status: 'active' });
  return organization;
}

function daysAgo(days: number): Timestamp {
  return Timestamp.fromMillis(now.getTime() - days * 86_400_000);
}

function request(retentionDays: Record<string, number>):
CallableRequest<UpdateDataRetentionPolicyRequest> {
  return {
    data: { organizationId: 'org-a', retentionDays },
    auth: { uid: 'user-a', token: {}, rawToken: 'token' } as never,
    rawRequest: {} as never,
    acceptsStreaming: false,
  };
}

describe('configurable data retention (Firestore Emulator)', () => {
  beforeEach(clearFirestore);
  afterAll(async () => { await clearFirestore(); await db.terminate(); });

  it('aplica prazo por tipo removendo ou anonimizando dados vencidos', async () => {
    const organization = await seedOrganization();
    await organization.collection('settings').doc('dataRetention').set({
      retentionDays: { auditLogs: 1825, readNotifications: 10, checkInLocations: 5, temporaryExports: 2 },
    });
    await organization.collection('auditLogs').doc('old').set({
      timestamp: daysAgo(1900), actorUserId: 'user-a', actorName: 'Ana', ipAddress: '127.0.0.1',
    });
    await organization.collection('notifications').doc('old').set({ readAt: daysAgo(11), userId: 'user-a' });
    await organization.collection('notifications').doc('new').set({ readAt: daysAgo(9), userId: 'user-a' });
    await organization.collection('visitCheckIns').doc('old').set({
      checkedInAt: daysAgo(6), latitude: -23.5, longitude: -46.6, address: 'Rua pessoal',
    });
    await organization.collection('temporaryExports').doc('old').set({ createdAt: daysAgo(3), storagePath: 'tmp/a' });

    const deletedStoragePaths: string[] = [];
    const summary = await applyRetentionForOrganization({
      db, organizationId: 'org-a', now,
      deleteStorageObject: async (path) => { deletedStoragePaths.push(path); },
    });

    expect(summary).toMatchObject({ deletedRecords: 2, anonymizedRecords: 2 });
    expect((await organization.collection('notifications').doc('old').get()).exists).toBe(false);
    expect((await organization.collection('notifications').doc('new').get()).exists).toBe(true);
    expect((await organization.collection('auditLogs').doc('old').get()).data()).toMatchObject({
      actorUserId: 'anonymized', actorName: 'Anonimizado', ipAddress: null,
    });
    expect((await organization.collection('visitCheckIns').doc('old').get()).data()).toMatchObject({
      latitude: null, longitude: null, address: null,
    });
    expect(deletedStoragePaths).toEqual(['tmp/a']);
  });

  it('rejeita prazo abaixo do minimo legal no servidor', async () => {
    const organization = await seedOrganization();
    await organization.collection('members').doc('user-a').set({ roleName: 'OWNER', status: 'active' });
    await expect(updateDataRetentionPolicyHandler(request({ auditLogs: 30 }), db))
      .rejects.toMatchObject({ code: 'invalid-argument' });
    expect((await organization.collection('settings').doc('dataRetention').get()).exists).toBe(false);
  });

  it('usa prazo seguro padrao quando nao existe configuracao', async () => {
    const organization = await seedOrganization();
    await organization.collection('notifications').doc('expired').set({
      readAt: daysAgo(DEFAULT_RETENTION_DAYS.readNotifications + 1), userId: 'user-a',
    });
    await organization.collection('notifications').doc('retained').set({
      readAt: daysAgo(DEFAULT_RETENTION_DAYS.readNotifications - 1), userId: 'user-a',
    });
    await applyRetentionForOrganization({ db, organizationId: 'org-a', now });
    expect((await organization.collection('notifications').doc('expired').get()).exists).toBe(false);
    expect((await organization.collection('notifications').doc('retained').get()).exists).toBe(true);
  });

  it('nao remove dado vencido ainda referenciado por processo ativo', async () => {
    const organization = await seedOrganization();
    await organization.collection('notifications').doc('active-appointment').set({
      readAt: daysAgo(200), userId: 'user-a', processStatus: 'scheduled',
    });
    const summary = await applyRetentionForOrganization({ db, organizationId: 'org-a', now });
    expect(summary.activeRecordsSkipped).toBe(1);
    expect((await organization.collection('notifications').doc('active-appointment').get()).exists).toBe(true);
  });

  it('mantem contrato explicito de minimizacao para cada tipo retido', () => {
    expect(Object.keys(PERSONAL_DATA_MINIMIZATION_CONTRACT).sort())
      .toEqual(Object.keys(MINIMUM_RETENTION_DAYS).sort());
    for (const fields of Object.values(PERSONAL_DATA_MINIMIZATION_CONTRACT)) {
      expect(fields.length).toBeGreaterThan(0);
    }
    expect(PERSONAL_DATA_MINIMIZATION_CONTRACT.checkInLocations)
      .not.toContain('continuousLocationHistory');
  });

  it('salva configuracao somente para administrador ativo e completa defaults', async () => {
    const organization = await seedOrganization();
    await organization.collection('members').doc('user-a').set({
      roleName: 'ADMIN', status: 'active', displayName: 'Admin',
    });
    const response = await updateDataRetentionPolicyHandler(
      request({ auditLogs: 2000, readNotifications: 45 }), db,
    );
    expect(response.retentionDays).toEqual(resolveRetentionDays({ auditLogs: 2000, readNotifications: 45 }));
    expect((await organization.collection('settings').doc('dataRetention').get()).data()?.updatedBy).toBe('user-a');
  });
});
