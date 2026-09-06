import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import { assertCanImportCustomers, assertValidMapping } from './customer-import-shared';

export interface StartCustomerImportJobRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  fileName?: string;
  storagePath?: string;
  mapping?: unknown;
  templateId?: string;
}

export interface StartCustomerImportJobResponse {
  jobId: string;
  correlationId: string;
}

/**
 * Creates a queued `CustomerImportJob` (TASK-167, EPIC-22) from an already
 * uploaded CSV/XLSX file — never parses the file itself (that is
 * `processCustomerImportJob`'s job, triggered by this document's own
 * creation): a callable must answer quickly, so the potentially slow
 * parse/validate/write work always happens in the background trigger
 * instead of inside this request/response cycle.
 *
 * RBAC (`assertCanImportCustomers`) and the mapping shape
 * (`assertValidMapping`) are both re-validated here from the caller's real
 * Membership/request, independent of anything the client claims — same
 * "never trust the client" rule every other Cloud Function in this
 * codebase follows.
 */
export const startCustomerImportJob = onCall<
  StartCustomerImportJobRequest,
  Promise<StartCustomerImportJobResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(
    request.data?.organizationId,
    'organizationId',
  );
  const companyId = requireNonEmptyString(request.data?.companyId, 'companyId');
  const fileName = requireNonEmptyString(request.data?.fileName, 'fileName');
  const storagePath = requireNonEmptyString(request.data?.storagePath, 'storagePath');
  const mapping = assertValidMapping(request.data?.mapping);
  const rawTemplateId = request.data?.templateId;
  const templateId =
    typeof rawTemplateId === 'string' && rawTemplateId.trim().length > 0
      ? rawTemplateId.trim()
      : null;

  const expectedPrefix = `organizations/${organizationId}/customerImports/`;
  if (!storagePath.startsWith(expectedPrefix)) {
    throw new HttpsError(
      'invalid-argument',
      'storagePath não pertence a esta organização.',
    );
  }

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  assertCanImportCustomers(membership.roleName);

  const organizationRef = db.collection('organizations').doc(organizationId);
  const companySnapshot = await organizationRef
    .collection('companies')
    .doc(companyId)
    .get();
  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Empresa não encontrada nesta organização.');
  }

  const jobRef = organizationRef.collection('customerImportJobs').doc();
  const now = Timestamp.now();
  await jobRef.set({
    organizationId,
    companyId,
    fileName,
    storagePath,
    reportStoragePath: null,
    templateId,
    mapping,
    status: 'queued',
    totalRows: null,
    processedRows: 0,
    importedCount: 0,
    rejectedCount: 0,
    duplicateCount: 0,
    errorMessage: null,
    createdAt: now,
    createdBy: uid,
    startedAt: null,
    completedAt: null,
  });

  logger.info('startCustomerImportJob succeeded', {
    correlationId,
    uid,
    organizationId,
    jobId: jobRef.id,
  });

  return { jobId: jobRef.id, correlationId };
});
