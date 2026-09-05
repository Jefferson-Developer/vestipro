import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import functionsTest from 'firebase-functions-test';
import type { CallableRequest } from 'firebase-functions/v2/https';

import {
  assertExportDownloadable,
  processPersonalDataExport,
  requestPersonalDataExport,
  type PersonalDataExportFileStore,
} from '../../src/privacy/personal-data-export';

const PROJECT_ID = 'demo-vestipro-personal-data-export-test';
if (getApps().length === 0) initializeApp({ projectId: PROJECT_ID });
const db = getFirestore();
const testEnv = functionsTest({ projectId: PROJECT_ID });

function callableRequest(uid: string): CallableRequest<{ organizationId: string }> {
  return {
    data: { organizationId: 'org-a' },
    auth: { uid, token: { name: 'Ana' }, rawToken: 'token' } as unknown as CallableRequest<{ organizationId: string }>['auth'],
    rawRequest: {} as CallableRequest<{ organizationId: string }>['rawRequest'],
    acceptsStreaming: false,
  };
}

class MemoryFileStore implements PersonalDataExportFileStore {
  readonly files = new Map<string, Buffer>();
  async save(path: string, contents: Buffer): Promise<void> {
    this.files.set(path, contents);
  }
}

async function clearFirestore(): Promise<void> {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
}

describe('personal data export (Firestore Emulator)', () => {
  beforeEach(async () => {
    await clearFirestore();
    await db.collection('organizations').doc('org-a').set({ name: 'Org A' });
    await db.collection('organizations').doc('org-a').collection('members').doc('user-a').set({
      userId: 'user-a', roleName: 'SALES_REP', status: 'active', displayName: 'Ana',
    });
  });

  afterAll(async () => {
    await clearFirestore();
    testEnv.cleanup();
    await db.terminate();
  });

  it('registra solicitação e conclusão em auditoria e gera exatamente os dados do solicitante', async () => {
    await db.collection('users').doc('user-a').set({ uid: 'user-a', name: 'Ana', email: 'ana@example.test' });
    await db.collection('users').doc('user-b').set({ uid: 'user-b', name: 'Bia', email: 'bia@example.test' });
    await db.collection('users').doc('user-a').collection('consentRecords').doc('own').set({
      organizationId: 'org-a', userId: 'user-a', purpose: 'marketing', granted: true, recordedAt: Timestamp.now(),
    });
    await db.collection('users').doc('user-b').collection('consentRecords').doc('other').set({
      organizationId: 'org-a', userId: 'user-b', purpose: 'marketing', granted: true, recordedAt: Timestamp.now(),
    });
    await db.collection('organizations').doc('org-a').collection('communicationPreferences').doc('user-a').set({
      organizationId: 'org-a', userId: 'user-a', categories: { system: { inApp: 'instant' } },
    });
    await db.collection('organizations').doc('org-a').collection('crmActivities').doc('own').set({
      userId: 'user-a', createdBy: 'user-a', type: 'visit', description: 'Visita própria',
    });
    await db.collection('organizations').doc('org-a').collection('crmActivities').doc('other').set({
      userId: 'user-b', createdBy: 'user-b', type: 'visit', description: 'Atividade de terceiro',
    });

    const wrapped = testEnv.wrap(requestPersonalDataExport);
    const response = await wrapped(callableRequest('user-a')) as { exportId: string };
    const fileStore = new MemoryFileStore();
    await processPersonalDataExport({
      db, fileStore, userId: 'user-a', exportId: response.exportId,
      now: new Date('2026-02-20T12:00:00.000Z'),
    });

    const contents = [...fileStore.files.values()][0].toString('utf8');
    const packageData = JSON.parse(contents) as Record<string, unknown>;
    expect(packageData.subjectUserId).toBe('user-a');
    expect(contents).toContain('ana@example.test');
    expect(contents).toContain('Visita própria');
    expect(contents).toContain('communicationPreferences');
    expect(contents).toContain('instant');
    expect(contents).not.toContain('bia@example.test');
    expect(contents).not.toContain('Atividade de terceiro');
    expect(contents).not.toContain('user-b');

    const status = await db.collection('users').doc('user-a').collection('personalDataExports').doc(response.exportId).get();
    expect(status.data()?.status).toBe('ready');
    const audits = await db.collection('organizations').doc('org-a').collection('auditLogs').get();
    expect(audits.docs.map((doc) => doc.data().action).sort()).toEqual([
      'privacy.personalDataExportCompleted',
      'privacy.personalDataExportRequested',
    ]);
  });

  it('restringe o download ao titular e rejeita pacote expirado', () => {
    const ready = {
      userId: 'user-a', status: 'ready', storagePath: 'personal-data-exports/user-a/data.json',
      fileName: 'data.json', expiresAt: Timestamp.fromDate(new Date('2026-02-21T12:00:00.000Z')),
    };
    expect(() => assertExportDownloadable(ready, 'user-b', new Date('2026-02-20T12:00:00.000Z'))).toThrow('Exportação não encontrada');
    expect(() => assertExportDownloadable(ready, 'user-a', new Date('2026-02-22T12:00:00.000Z'))).toThrow('expirou');
  });
});
