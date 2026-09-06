import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import {
  assertCanImportCustomers,
  buildCustomerDocumentFromFields,
  validateCustomerImportRow,
} from './customer-import-shared';

export interface ResolveCustomerImportDuplicateRowRequest extends RequestWithMeta {
  organizationId?: string;
  jobId?: string;
  rowNumber?: number;
  resolution?: string;
}

const VALID_RESOLUTIONS = new Set<string>(['ignore', 'merge', 'createAnyway']);

/**
 * Applies the gestor's decision (`ignore`/`merge`/`createAnyway`) for one
 * `duplicateExisting` row of a finished `CustomerImportJob` (TASK-167).
 *
 * `createAnyway` is only ever accepted when the row's duplicate match was
 * by e-mail alone (`matchedByEmailOnly: true`) — re-validated here from the
 * stored report, never from anything the client claims, since two
 * `Customer`s sharing one CNPJ/CPF inside the same organization would
 * violate `CustomerRepository.existsByDocument`'s invariant.
 *
 * `merge` only ever fills currently-empty fields on the existing
 * `Customer` from the row's values — it never overwrites a field that
 * already has a value, so re-importing a stale spreadsheet can never
 * clobber data entered manually since.
 */
export const resolveCustomerImportDuplicateRow = onCall<
  ResolveCustomerImportDuplicateRowRequest,
  Promise<{ correlationId: string }>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const jobId = requireNonEmptyString(request.data?.jobId, 'jobId');
  const rowNumber = request.data?.rowNumber;
  const resolution = request.data?.resolution;
  if (typeof rowNumber !== 'number') {
    throw new HttpsError('invalid-argument', 'rowNumber é obrigatório.');
  }
  if (typeof resolution !== 'string' || !VALID_RESOLUTIONS.has(resolution)) {
    throw new HttpsError('invalid-argument', 'resolution inválida.');
  }

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  assertCanImportCustomers(membership.roleName);

  const jobRef = db
    .collection('organizations')
    .doc(organizationId)
    .collection('customerImportJobs')
    .doc(jobId);
  const jobSnapshot = await jobRef.get();
  const job = jobSnapshot.data();
  if (!jobSnapshot.exists || !job) {
    throw new HttpsError('not-found', 'Importação não encontrada.');
  }
  if (job.status !== 'completed' || typeof job.reportStoragePath !== 'string') {
    throw new HttpsError('failed-precondition', 'A importação ainda não foi concluída.');
  }

  const bucket = getStorage().bucket();
  const reportFile = bucket.file(job.reportStoragePath as string);
  const [reportBytes] = await reportFile.download();
  const report = JSON.parse(reportBytes.toString('utf8')) as {
    rows: Array<Record<string, unknown>>;
  };

  const row = report.rows.find((candidate) => candidate.rowNumber === rowNumber);
  if (!row || row.outcome !== 'duplicateExisting') {
    throw new HttpsError('not-found', 'Linha duplicada não encontrada neste relatório.');
  }
  if (row.resolution != null) {
    throw new HttpsError('failed-precondition', 'Esta duplicidade já foi resolvida.');
  }

  const rawValues = (row.rawValues ?? {}) as Record<string, string>;
  const now = Timestamp.now();

  if (resolution === 'createAnyway') {
    if (row.matchedByEmailOnly !== true) {
      throw new HttpsError(
        'failed-precondition',
        'Só é possível criar mesmo assim quando a duplicidade é apenas por e-mail.',
      );
    }
    const validation = validateCustomerImportRow(rawValues);
    if (!validation.ok) {
      throw new HttpsError('failed-precondition', validation.reason);
    }
    const customerRef = db
      .collection('organizations')
      .doc(organizationId)
      .collection('customers')
      .doc();
    await customerRef.set(
      buildCustomerDocumentFromFields({
        organizationId,
        companyId: job.companyId as string,
        fields: validation.fields,
        createdBy: uid,
        now,
      }),
    );
    row.createdCustomerId = customerRef.id;
  } else if (resolution === 'merge') {
    const existingCustomerId = row.matchedExistingCustomerId as string | undefined;
    if (!existingCustomerId) {
      throw new HttpsError('failed-precondition', 'Cliente correspondente não encontrado.');
    }
    const validation = validateCustomerImportRow(rawValues);
    if (!validation.ok) {
      throw new HttpsError('failed-precondition', validation.reason);
    }
    const customerRef = db
      .collection('organizations')
      .doc(organizationId)
      .collection('customers')
      .doc(existingCustomerId);
    const existingSnapshot = await customerRef.get();
    const existing = existingSnapshot.data();
    if (!existingSnapshot.exists || !existing) {
      throw new HttpsError('not-found', 'Cliente correspondente não encontrado.');
    }
    const fields = validation.fields;
    const patch: Record<string, unknown> = {};
    if (!existing.primaryEmail && fields.primaryEmail) patch.primaryEmail = fields.primaryEmail;
    if (!existing.primaryPhone && fields.primaryPhone) patch.primaryPhone = fields.primaryPhone;
    if (!existing.tradeName && fields.tradeName) patch.tradeName = fields.tradeName;
    if (!existing.legalName && fields.legalName) patch.legalName = fields.legalName;
    if (!existing.segment && fields.segment) patch.segment = fields.segment;
    if (!existing.classification && fields.classification) patch.classification = fields.classification;
    if (!existing.potential && fields.potential) patch.potential = fields.potential;
    if (!existing.stateRegistration && fields.stateRegistration) {
      patch.stateRegistration = fields.stateRegistration;
    }
    if (Object.keys(patch).length > 0) {
      patch.updatedAt = now;
      patch.updatedBy = uid;
      patch.version = (typeof existing.version === 'number' ? existing.version : 1) + 1;
      await customerRef.update(patch);
    }
  }

  row.resolution = resolution;
  await reportFile.save(Buffer.from(JSON.stringify(report)), {
    contentType: 'application/json',
  });

  logger.info('resolveCustomerImportDuplicateRow succeeded', {
    correlationId,
    uid,
    organizationId,
    jobId,
    rowNumber,
    resolution,
  });

  return { correlationId };
});
