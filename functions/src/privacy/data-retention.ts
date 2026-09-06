import { getFirestore, Timestamp, type DocumentData, type Firestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall, type CallableRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { requireNonEmptyString } from '../invites/invite-shared';

export type RetentionDataType =
  | 'auditLogs'
  | 'readNotifications'
  | 'checkInLocations'
  | 'temporaryExports';

export interface DataRetentionPolicy {
  organizationId: string;
  retentionDays: Record<RetentionDataType, number>;
  updatedAt: Timestamp;
  updatedBy: string;
}

export interface UpdateDataRetentionPolicyRequest {
  organizationId?: unknown;
  retentionDays?: unknown;
}

export interface RetentionRunSummary {
  organizationsProcessed: number;
  deletedRecords: number;
  anonymizedRecords: number;
  activeRecordsSkipped: number;
}

interface RetentionRule {
  collection: string;
  dateField: string;
  operation: 'delete' | 'anonymizeAudit' | 'anonymizeLocation';
}

/**
 * Personal-data minimization contract (reviewed for Auth, location, preferences
 * and analytics). Every persisted personal field must be listed here together
 * with its functional purpose; tests fail if retention starts handling a new
 * category without an explicit justification.
 *
 * - Auth profile: `name`, `email`, `phone`, `photoUrl` identify and contact the
 *   user. Passwords/tokens are never copied to Firestore or analytics.
 * - Check-in: `latitude`, `longitude`, `accuracyMeters`, `address` prove the
 *   visit only when the user explicitly checks in; continuous tracking is not
 *   collected.
 * - Communication preferences: `userId`, channel/topic flags and quiet-hours
 *   timezone are required to route or suppress messages; device locale,
 *   contacts and message contents are not collected.
 * - Analytics: stable internal IDs and coarse business event properties are
 *   permitted; name, email, phone, address, precise location and free text are
 *   forbidden.
 * - Audit logs: actor ID/name and administrative target are retained to prove
 *   access and changes, then actor name/IP/user-agent are anonymized after the
 *   legal period while the non-personal event remains immutable.
 */
export const PERSONAL_DATA_MINIMIZATION_CONTRACT: Readonly<
  Record<RetentionDataType, readonly string[]>
> = Object.freeze({
  auditLogs: ['actorUserId', 'actorName', 'ipAddress', 'userAgent'],
  readNotifications: ['userId', 'title', 'body', 'deepLink'],
  checkInLocations: ['userId', 'latitude', 'longitude', 'accuracyMeters', 'address'],
  temporaryExports: ['userId', 'storagePath', 'fileName'],
});

export const DEFAULT_RETENTION_DAYS: Readonly<Record<RetentionDataType, number>> =
  Object.freeze({
    auditLogs: 1825,
    readNotifications: 90,
    checkInLocations: 30,
    temporaryExports: 7,
  });

// Audit trails support legal claims and cannot be configured below five years.
export const MINIMUM_RETENTION_DAYS: Readonly<Record<RetentionDataType, number>> =
  Object.freeze({
    auditLogs: 1825,
    readNotifications: 1,
    checkInLocations: 1,
    temporaryExports: 1,
  });

const RULES: Readonly<Record<RetentionDataType, RetentionRule>> = Object.freeze({
  auditLogs: {
    collection: 'auditLogs', dateField: 'timestamp', operation: 'anonymizeAudit',
  },
  readNotifications: {
    collection: 'notifications', dateField: 'readAt', operation: 'delete',
  },
  checkInLocations: {
    collection: 'visitCheckIns', dateField: 'checkedInAt', operation: 'anonymizeLocation',
  },
  temporaryExports: {
    collection: 'temporaryExports', dateField: 'createdAt', operation: 'delete',
  },
});

const ACTIVE_PROCESS_STATUSES = new Set([
  'active', 'pending', 'processing', 'scheduled', 'in_progress',
]);

function integerDays(value: unknown, dataType: RetentionDataType): number {
  if (typeof value !== 'number' || !Number.isSafeInteger(value)) {
    throw new HttpsError('invalid-argument', `${dataType} deve ser um numero inteiro de dias.`);
  }
  const minimum = MINIMUM_RETENTION_DAYS[dataType];
  if (value < minimum || value > 3650) {
    throw new HttpsError(
      'invalid-argument',
      `${dataType} deve ficar entre ${minimum} e 3650 dias.`,
    );
  }
  return value;
}

export function resolveRetentionDays(value: unknown): Record<RetentionDataType, number> {
  if (value == null) return { ...DEFAULT_RETENTION_DAYS };
  if (typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpsError('invalid-argument', 'retentionDays deve ser um objeto.');
  }
  const source = value as Record<string, unknown>;
  const allowed = Object.keys(DEFAULT_RETENTION_DAYS);
  const unknown = Object.keys(source).find((key) => !allowed.includes(key));
  if (unknown) throw new HttpsError('invalid-argument', `Tipo de dado desconhecido: ${unknown}.`);
  return Object.fromEntries(
    allowed.map((key) => {
      const type = key as RetentionDataType;
      return [type, source[type] == null
        ? DEFAULT_RETENTION_DAYS[type]
        : integerDays(source[type], type)];
    }),
  ) as Record<RetentionDataType, number>;
}

function isReferencedByActiveProcess(data: DocumentData, now: Date): boolean {
  if (data.referencedByActiveProcess === true) return true;
  if (typeof data.activeReferenceCount === 'number' && data.activeReferenceCount > 0) return true;
  if (typeof data.processStatus === 'string' && ACTIVE_PROCESS_STATUSES.has(data.processStatus)) {
    return true;
  }
  const activeUntil = data.activeUntil;
  return activeUntil instanceof Timestamp && activeUntil.toDate().getTime() > now.getTime();
}

function anonymizedFields(operation: RetentionRule['operation'], now: Timestamp): DocumentData {
  if (operation === 'anonymizeAudit') {
    return {
      actorUserId: 'anonymized', actorName: 'Anonimizado', ipAddress: null,
      userAgent: null, personalDataAnonymizedAt: now,
    };
  }
  return {
    latitude: null, longitude: null, accuracyMeters: null, address: null,
    locationAnonymizedAt: now,
  };
}

async function applyRule(params: {
  db: Firestore;
  organizationId: string;
  dataType: RetentionDataType;
  days: number;
  now: Date;
  deleteStorageObject?: (path: string) => Promise<void>;
}): Promise<Omit<RetentionRunSummary, 'organizationsProcessed'>> {
  const { db, organizationId, dataType, days, now } = params;
  const rule = RULES[dataType];
  const collection = db.collection('organizations').doc(organizationId).collection(rule.collection);
  const cutoff = Timestamp.fromMillis(now.getTime() - days * 86_400_000);
  const snapshot = await collection.where(rule.dateField, '<=', cutoff).get();
  let deletedRecords = 0;
  let anonymizedRecords = 0;
  let activeRecordsSkipped = 0;
  for (const document of snapshot.docs) {
    const data = document.data();
    if (isReferencedByActiveProcess(data, now)) {
      activeRecordsSkipped += 1;
      continue;
    }
    if (rule.operation === 'anonymizeAudit' && data.personalDataAnonymizedAt != null) continue;
    if (rule.operation === 'anonymizeLocation' && data.locationAnonymizedAt != null) continue;
    if (rule.operation === 'delete') {
      if (dataType === 'temporaryExports' && typeof data.storagePath === 'string') {
        await params.deleteStorageObject?.(data.storagePath);
      }
      await document.ref.delete();
      deletedRecords += 1;
    } else {
      await document.ref.update(anonymizedFields(rule.operation, Timestamp.fromDate(now)));
      anonymizedRecords += 1;
    }
  }
  return { deletedRecords, anonymizedRecords, activeRecordsSkipped };
}

export async function applyRetentionForOrganization(params: {
  db: Firestore;
  organizationId: string;
  now?: Date;
  deleteStorageObject?: (path: string) => Promise<void>;
}): Promise<Omit<RetentionRunSummary, 'organizationsProcessed'>> {
  const { db, organizationId } = params;
  const now = params.now ?? new Date();
  const policySnapshot = await db.collection('organizations').doc(organizationId)
    .collection('settings').doc('dataRetention').get();
  const retentionDays = resolveRetentionDays(policySnapshot.data()?.retentionDays);
  const summary = { deletedRecords: 0, anonymizedRecords: 0, activeRecordsSkipped: 0 };
  for (const dataType of Object.keys(RULES) as RetentionDataType[]) {
    const result = await applyRule({
      db, organizationId, dataType, days: retentionDays[dataType], now,
      deleteStorageObject: params.deleteStorageObject,
    });
    summary.deletedRecords += result.deletedRecords;
    summary.anonymizedRecords += result.anonymizedRecords;
    summary.activeRecordsSkipped += result.activeRecordsSkipped;
  }
  return summary;
}

export async function applyDataRetentionPolicies(
  db: Firestore,
  now = new Date(),
  deleteStorageObject: (path: string) => Promise<void> = async (path) => {
    await getStorage().bucket().file(path).delete({ ignoreNotFound: true });
  },
): Promise<RetentionRunSummary> {
  const organizations = await db.collection('organizations').get();
  const summary: RetentionRunSummary = {
    organizationsProcessed: 0, deletedRecords: 0,
    anonymizedRecords: 0, activeRecordsSkipped: 0,
  };
  for (const organization of organizations.docs) {
    const data = organization.data();
    if (data.deletedAt != null || data.status === 'inactive') continue;
    const result = await applyRetentionForOrganization({
      db, organizationId: organization.id, now, deleteStorageObject,
    });
    summary.organizationsProcessed += 1;
    summary.deletedRecords += result.deletedRecords;
    summary.anonymizedRecords += result.anonymizedRecords;
    summary.activeRecordsSkipped += result.activeRecordsSkipped;
  }
  return summary;
}

export async function updateDataRetentionPolicyHandler(
  request: CallableRequest<UpdateDataRetentionPolicyRequest>,
  db: Firestore = getFirestore(),
): Promise<{ organizationId: string; retentionDays: Record<RetentionDataType, number> }> {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const organization = db.collection('organizations').doc(organizationId);
  const membership = await organization.collection('members').doc(request.auth.uid).get();
  const membershipData = membership.data();
  if (!membership.exists || membershipData?.status !== 'active' ||
      !['OWNER', 'ADMIN'].includes(membershipData.roleName as string)) {
    throw new HttpsError('permission-denied', 'Apenas OWNER/ADMIN podem alterar a retencao.');
  }
  const retentionDays = resolveRetentionDays(request.data?.retentionDays);
  const now = Timestamp.now();
  const policy: DataRetentionPolicy = {
    organizationId, retentionDays, updatedAt: now, updatedBy: request.auth.uid,
  };
  await organization.collection('settings').doc('dataRetention').set(policy);
  await organization.collection('auditLogs').add({
    organizationId, actorUserId: request.auth.uid,
    actorName: membershipData.displayName ?? membershipData.name ?? 'Administrador',
    action: 'privacy.dataRetentionPolicyUpdated', entityType: 'dataRetentionPolicy',
    entityId: 'dataRetention', timestamp: now, newValue: { retentionDays },
  });
  return { organizationId, retentionDays };
}

export const updateDataRetentionPolicy = onCall<UpdateDataRetentionPolicyRequest>(
  (request) => updateDataRetentionPolicyHandler(request),
);

export const applyDataRetentionPoliciesScheduled = onSchedule(
  { schedule: 'every day 03:30', timeZone: 'America/Sao_Paulo', region: 'southamerica-east1' },
  async () => {
    const summary = await applyDataRetentionPolicies(getFirestore());
    logger.info('Data retention policies applied', summary);
  },
);
