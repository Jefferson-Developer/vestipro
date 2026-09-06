import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import {
  assertCanImportProducts,
  assertValidLookup,
  assertValidMapping,
} from './product-import-shared';

export interface StartProductImportJobRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  fileName?: string;
  storagePath?: string;
  imagesFolderPath?: string;
  mapping?: unknown;
  lookup?: unknown;
  createMissingCategories?: boolean;
  createMissingCollections?: boolean;
  templateId?: string;
}

export interface StartProductImportJobResponse {
  jobId: string;
  correlationId: string;
}

/**
 * Creates a queued `ProductImportJob` (TASK-168, EPIC-22) from an already
 * uploaded CSV/XLSX file (and, optionally, an already uploaded image
 * package) — never parses the file itself, mirroring
 * `startCustomerImportJob` (TASK-167): a callable must answer quickly, so
 * the parse/validate/write work always happens in `processProductImportJob`
 * (the trigger this job document's own creation fires).
 *
 * RBAC (`assertCanImportProducts`), the mapping shape
 * (`assertValidMapping`) and the lookup shape (`assertValidLookup`) are all
 * re-validated here from the caller's real Membership/request, independent
 * of anything the client claims.
 */
export const startProductImportJob = onCall<
  StartProductImportJobRequest,
  Promise<StartProductImportJobResponse>
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
  const rawImagesFolderPath = request.data?.imagesFolderPath;
  const imagesFolderPath =
    typeof rawImagesFolderPath === 'string' && rawImagesFolderPath.trim().length > 0
      ? rawImagesFolderPath.trim()
      : null;
  const mapping = assertValidMapping(request.data?.mapping);
  const lookup = assertValidLookup(request.data?.lookup);
  const createMissingCategories = request.data?.createMissingCategories === true;
  const createMissingCollections = request.data?.createMissingCollections === true;
  const rawTemplateId = request.data?.templateId;
  const templateId =
    typeof rawTemplateId === 'string' && rawTemplateId.trim().length > 0
      ? rawTemplateId.trim()
      : null;

  const expectedPrefix = `organizations/${organizationId}/productImports/`;
  if (!storagePath.startsWith(expectedPrefix)) {
    throw new HttpsError(
      'invalid-argument',
      'storagePath não pertence a esta organização.',
    );
  }
  if (imagesFolderPath && !imagesFolderPath.startsWith(expectedPrefix)) {
    throw new HttpsError(
      'invalid-argument',
      'imagesFolderPath não pertence a esta organização.',
    );
  }

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  assertCanImportProducts(membership.roleName);

  const organizationRef = db.collection('organizations').doc(organizationId);
  const companySnapshot = await organizationRef
    .collection('companies')
    .doc(companyId)
    .get();
  if (!companySnapshot.exists) {
    throw new HttpsError('not-found', 'Empresa não encontrada nesta organização.');
  }

  const jobRef = organizationRef.collection('productImportJobs').doc();
  const now = Timestamp.now();
  await jobRef.set({
    organizationId,
    companyId,
    fileName,
    storagePath,
    imagesFolderPath,
    reportStoragePath: null,
    templateId,
    mapping,
    lookup,
    createMissingCategories,
    createMissingCollections,
    status: 'queued',
    totalRows: null,
    processedRows: 0,
    createdProductsCount: 0,
    createdVariantsCount: 0,
    imagesAssociatedCount: 0,
    imagesOrphanCount: 0,
    rejectedCount: 0,
    errorMessage: null,
    createdAt: now,
    createdBy: uid,
    startedAt: null,
    completedAt: null,
  });

  logger.info('startProductImportJob succeeded', {
    correlationId,
    uid,
    organizationId,
    jobId: jobRef.id,
  });

  return { jobId: jobRef.id, correlationId };
});
