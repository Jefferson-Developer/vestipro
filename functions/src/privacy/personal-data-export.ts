import { randomUUID } from 'node:crypto';

import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { requireNonEmptyString } from '../invites/invite-shared';

export const PERSONAL_DATA_EXPORT_TTL_MS = 24 * 60 * 60 * 1000;

export interface PersonalDataExportFileStore {
  save(path: string, contents: Buffer, metadata: Record<string, unknown>): Promise<void>;
}

function firebaseFileStore(): PersonalDataExportFileStore {
  const bucket = getStorage().bucket();
  return {
    async save(path, contents, metadata) {
      await bucket.file(path).save(contents, metadata);
    },
  };
}

type JsonValue = string | number | boolean | null | JsonValue[] | { [key: string]: JsonValue };

function jsonValue(value: unknown): JsonValue {
  if (value === null || typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
    return value;
  }
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (Array.isArray(value)) return value.map(jsonValue);
  if (typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>).map(([key, nested]) => [key, jsonValue(nested)]),
    );
  }
  return String(value);
}

function pick(data: Record<string, unknown> | undefined, fields: readonly string[]): Record<string, JsonValue> {
  if (!data) return {};
  return Object.fromEntries(
    fields.filter((field) => data[field] !== undefined).map((field) => [field, jsonValue(data[field])]),
  );
}

async function requireActiveMembership(db: Firestore, organizationId: string, uid: string) {
  const membership = await db.collection('organizations').doc(organizationId).collection('members').doc(uid).get();
  if (!membership.exists || membership.data()?.status !== 'active') {
    throw new HttpsError('permission-denied', 'Você não possui vínculo ativo com esta organização.');
  }
  return membership;
}

export const requestPersonalDataExport = onCall<{ organizationId?: unknown }>(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const db = getFirestore();
  const membership = await requireActiveMembership(db, organizationId, request.auth.uid);
  const requestedAt = Timestamp.now();
  const exportId = randomUUID();
  const exportRef = db.collection('users').doc(request.auth.uid).collection('personalDataExports').doc(exportId);
  const auditRef = db.collection('organizations').doc(organizationId).collection('auditLogs').doc();

  await db.runTransaction(async (transaction) => {
    transaction.create(exportRef, {
      organizationId,
      userId: request.auth!.uid,
      status: 'requested',
      requestedAt,
      expiresAt: null,
      fileName: null,
      storagePath: null,
    });
    transaction.create(auditRef, {
      organizationId,
      actorUserId: request.auth!.uid,
      actorName: membership.data()?.displayName ?? request.auth!.token.name ?? request.auth!.token.email ?? request.auth!.uid,
      action: 'privacy.personalDataExportRequested',
      entityType: 'personalDataExport',
      entityId: exportId,
      timestamp: requestedAt,
      metadata: { exportId },
    });
  });
  return { exportId };
});

export async function processPersonalDataExport(params: {
  db: Firestore;
  fileStore: PersonalDataExportFileStore;
  userId: string;
  exportId: string;
  now?: Date;
}): Promise<void> {
  const { db, fileStore, userId, exportId } = params;
  const exportRef = db.collection('users').doc(userId).collection('personalDataExports').doc(exportId);
  const initial = await exportRef.get();
  const request = initial.data();
  if (
    !initial.exists ||
    request?.userId !== userId ||
    (request.status !== 'requested' && request.status !== 'processing')
  ) return;
  const organizationId = requireNonEmptyString(request.organizationId, 'organizationId');
  const now = params.now ?? new Date();
  await exportRef.update({ status: 'processing', processingStartedAt: Timestamp.fromDate(now) });

  try {
    const organization = db.collection('organizations').doc(organizationId);
    const [profile, memberships, communicationPreferences, policies, consents, auditLogs, crmActivities] = await Promise.all([
      db.collection('users').doc(userId).get(),
      db.collectionGroup('members').where('userId', '==', userId).get(),
      organization.collection('communicationPreferences').doc(userId).get(),
      db.collection('users').doc(userId).collection('policyAcceptances').get(),
      db.collection('users').doc(userId).collection('consentRecords').where('organizationId', '==', organizationId).get(),
      organization.collection('auditLogs').where('actorUserId', '==', userId).get(),
      organization.collection('crmActivities').where('userId', '==', userId).get(),
    ]);
    const packageData = {
      schemaVersion: 1,
      generatedAt: now.toISOString(),
      subjectUserId: userId,
      organizationId,
      profile: pick(profile.data(), ['uid', 'name', 'displayName', 'email', 'createdAt', 'termsVersion']),
      organizationMemberships: memberships.docs.map((doc) => pick(doc.data(), ['organizationId', 'userId', 'roleId', 'roleName', 'status', 'teamIds', 'companyIds', 'createdAt', 'updatedAt'])),
      communicationPreferences: pick(communicationPreferences.data(), ['organizationId', 'userId', 'categories', 'quietHours', 'updatedAt']),
      policyAcceptances: policies.docs.map((doc) => ({ id: doc.id, ...pick(doc.data(), ['type', 'version', 'acceptedAt', 'device']) })),
      consentRecords: consents.docs.map((doc) => ({ id: doc.id, ...pick(doc.data(), ['organizationId', 'userId', 'purpose', 'granted', 'recordedAt']) })),
      activities: crmActivities.docs.map((doc) => ({ id: doc.id, ...pick(doc.data(), ['type', 'userId', 'createdBy', 'description', 'occurredAt', 'createdAt']) })),
      auditEvents: auditLogs.docs.map((doc) => ({ id: doc.id, ...pick(doc.data(), ['action', 'entityType', 'entityId', 'timestamp']) })),
    };
    const fileName = `dados-pessoais-${exportId}.json`;
    const storagePath = `personal-data-exports/${userId}/${fileName}`;
    const expiresAt = new Date(now.getTime() + PERSONAL_DATA_EXPORT_TTL_MS);
    await fileStore.save(storagePath, Buffer.from(JSON.stringify(packageData, null, 2), 'utf8'), {
      contentType: 'application/json; charset=utf-8',
      metadata: { cacheControl: 'private, max-age=0', metadata: { userId, exportId } },
    });

    const batch = db.batch();
    batch.update(exportRef, {
      status: 'ready', fileName, storagePath,
      completedAt: Timestamp.fromDate(now), expiresAt: Timestamp.fromDate(expiresAt),
    });
    batch.create(organization.collection('notifications').doc(), {
      organizationId, userId, category: 'system', priority: 'informative',
      title: 'Seus dados pessoais estão prontos',
      body: 'A exportação pode ser baixada por 24 horas.',
      deepLink: `/org/${organizationId}/settings/privacy`,
      createdAt: Timestamp.fromDate(now), readAt: null, deliverAt: null,
    });
    batch.create(organization.collection('auditLogs').doc(), {
      organizationId, actorUserId: userId, actorName: userId,
      action: 'privacy.personalDataExportCompleted', entityType: 'personalDataExport',
      entityId: exportId, timestamp: Timestamp.fromDate(now), metadata: { exportId },
    });
    await batch.commit();
  } catch (error) {
    await exportRef.update({
      status: 'failed',
      failureCode: error instanceof Error ? error.name : 'unknown',
      completedAt: Timestamp.fromDate(now),
    });
    throw error;
  }
}

export const processPersonalDataExportRequested = onDocumentCreated(
  'users/{userId}/personalDataExports/{exportId}',
  async (event) => processPersonalDataExport({
    db: getFirestore(), fileStore: firebaseFileStore(),
    userId: event.params.userId, exportId: event.params.exportId,
  }),
);

export const getPersonalDataExportDownloadUrl = onCall<{ exportId?: unknown }>(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  const exportId = requireNonEmptyString(request.data?.exportId, 'exportId');
  const snapshot = await getFirestore().collection('users').doc(request.auth.uid).collection('personalDataExports').doc(exportId).get();
  const data = snapshot.data();
  if (!snapshot.exists) throw new HttpsError('not-found', 'Exportação não encontrada.');
  let download;
  try {
    download = assertExportDownloadable(data ?? {}, request.auth.uid, new Date());
  } catch (error) {
    if (error instanceof HttpsError && error.code === 'deadline-exceeded') {
      await snapshot.ref.update({ status: 'expired' });
    }
    throw error;
  }
  const linkExpiresAt = new Date(Math.min(download.expiresAt.getTime(), Date.now() + 15 * 60 * 1000));
  const [downloadUrl] = await getStorage().bucket().file(download.storagePath).getSignedUrl({ action: 'read', expires: linkExpiresAt });
  return { downloadUrl, expiresAt: linkExpiresAt.toISOString(), fileName: download.fileName };
});

export function assertExportDownloadable(
  data: Record<string, unknown>,
  authenticatedUserId: string,
  now: Date,
): { storagePath: string; fileName: string; expiresAt: Date } {
  if (data.userId !== authenticatedUserId) {
    throw new HttpsError('not-found', 'Exportação não encontrada.');
  }
  if (data.status !== 'ready' || typeof data.storagePath !== 'string' || typeof data.fileName !== 'string' || !(data.expiresAt instanceof Timestamp)) {
    throw new HttpsError('failed-precondition', 'A exportação ainda não está disponível.');
  }
  const expiresAt = data.expiresAt.toDate();
  if (expiresAt.getTime() <= now.getTime()) {
    throw new HttpsError('deadline-exceeded', 'O link desta exportação expirou.');
  }
  return { storagePath: data.storagePath, fileName: data.fileName, expiresAt };
}
