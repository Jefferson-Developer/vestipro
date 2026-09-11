import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp, getFirestore, type DocumentData } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString as requireNonEmptyStringShared } from '../invites/invite-shared';
import { optionalString } from '../pricing/calculate-pricing';
import {
  computeExternalEntityId,
  computeInvoiceStatus,
  computeReceivableStatus,
  normalizeCurrencyCode,
  normalizePositiveMoney,
  requireInvoiceSource,
  requireNonEmptyString,
  type Receivable,
} from './receivables-shared';

/**
 * Only these roles may ever import/sync a fatura or edit its parcelas
 * (TASK-213) — mirrors exactly `Capability.financeManage`'s grant list
 * (OWNER/ADMIN/FINANCE, `role_permission_matrix.dart`), same boundary
 * TASK-212's `updateCreditProfile` already enforces for this same "gestão
 * financeira" domain. An ERP/gateway integration authenticates as a member
 * holding this role (there is no separate machine-to-machine auth path in
 * this codebase yet — `apiKeyManage`, TASK-171, issues API keys but no
 * Function here validates one; deliberately out of this task's scope, see
 * the completion doc's "Decisões técnicas").
 */
const ROLES_ALLOWED_TO_IMPORT_INVOICE: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'FINANCE',
]);

export interface ImportReceivableInstallmentInput {
  externalId?: string;
  installmentNumber: number;
  dueDate: string;
  amount: number;
}

export interface ImportReceivableInvoiceRequest extends RequestWithMeta {
  organizationId?: string;
  companyId?: string;
  customerId?: string;
  orderId?: string;
  sellerId?: string;
  externalId?: string;
  source?: string;
  currency?: string;
  issueDate?: string;
  installments?: ImportReceivableInstallmentInput[];
}

export interface ImportReceivableInvoiceResponse {
  correlationId: string;
  invoiceId: string;
  receivableIds: string[];
  status: string;
}

/**
 * Idempotent entry point for fatura/parcela sync from an ERP or a payment
 * gateway (TASK-213: "sincronização/entrada de faturas geradas por ERP/
 * gateway, com idempotência por identificador externo"). [externalId]
 * (the ERP/gateway's own invoice number) always resolves to the very same
 * `invoices/{invoiceId}` document via [computeExternalEntityId] — retrying
 * the same import (a webhook redelivery, a re-run batch) merges onto the
 * same document instead of creating a duplicate, and a parcela that already
 * received a payment (`paidAmount > 0`) never has that payment erased by a
 * later re-import: [paidAmount] is only ever advanced by
 * `registerPaymentAllocation`, never by this Function.
 */
export const importReceivableInvoice = onCall<
  ImportReceivableInvoiceRequest,
  Promise<ImportReceivableInvoiceResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyStringShared(request.data?.organizationId, 'organizationId');
  const companyId = requireNonEmptyStringShared(request.data?.companyId, 'companyId');
  const customerId = requireNonEmptyStringShared(request.data?.customerId, 'customerId');
  const externalId = requireNonEmptyString(request.data?.externalId, 'externalId');
  const source = requireInvoiceSource(request.data?.source);
  const currency = normalizeCurrencyCode(request.data?.currency);
  const orderId = optionalString(request.data?.orderId) ?? null;
  const sellerId = optionalString(request.data?.sellerId) ?? null;
  const issueDate = parseRequiredDate(request.data?.issueDate, 'issueDate');
  const installmentsInput = request.data?.installments;
  if (!Array.isArray(installmentsInput) || installmentsInput.length === 0) {
    throw new HttpsError('invalid-argument', 'At least one installment is required.');
  }
  const installments = installmentsInput.map((installment, index) =>
    normalizeInstallment(installment, index),
  );

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_IMPORT_INVOICE.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Seu perfil não pode importar faturas.');
  }

  const organizationRef = db.collection('organizations').doc(organizationId);
  const customerSnapshot = await organizationRef.collection('customers').doc(customerId).get();
  if (!customerSnapshot.exists || customerSnapshot.data()?.companyId !== companyId) {
    throw new HttpsError('failed-precondition', 'Cliente não encontrado nesta empresa.');
  }

  const invoiceId = computeExternalEntityId(organizationId, 'invoice', externalId);
  const invoiceRef = organizationRef.collection('invoices').doc(invoiceId);
  const now = Timestamp.now();

  const receivableRefs = installments.map((installment) => {
    const receivableExternalId = installment.externalId ?? `${externalId}:${installment.installmentNumber}`;
    const receivableId = computeExternalEntityId(organizationId, 'receivable', receivableExternalId);
    return {
      ref: organizationRef.collection('receivables').doc(receivableId),
      externalId: receivableExternalId,
      installment,
    };
  });

  const totalAmount = installments.reduce((sum, installment) => sum + installment.amount, 0);

  const result = await db.runTransaction<ImportReceivableInvoiceResponse>(async (transaction) => {
    const [invoiceSnapshot, ...receivableSnapshots] = await Promise.all([
      transaction.get(invoiceRef),
      ...receivableRefs.map(({ ref }) => transaction.get(ref)),
    ]);

    const receivableStatuses: Receivable['status'][] = [];
    const receivableIds: string[] = [];

    receivableRefs.forEach(({ ref, externalId: installmentExternalId, installment }, index) => {
      const existing = receivableSnapshots[index];
      const existingData = existing.exists ? existing.data() : undefined;
      // Nunca regride um pagamento já registrado — um re-import/retry só
      // pode ajustar vencimento/valor/observações, jamais apagar
      // `paidAmount` já confirmado por `registerPaymentAllocation`.
      const paidAmount = typeof existingData?.paidAmount === 'number' ? existingData.paidAmount : 0;
      const cancelled = existingData?.status === 'cancelled';
      const status = computeReceivableStatus({
        amount: installment.amount,
        paidAmount,
        dueDate: installment.dueDate,
        cancelled,
        now,
      });
      receivableStatuses.push(status);
      receivableIds.push(ref.id);

      const data: DocumentData = {
        organizationId,
        companyId,
        customerId,
        invoiceId,
        orderId,
        sellerId,
        externalId: installmentExternalId,
        installmentNumber: installment.installmentNumber,
        dueDate: installment.dueDate,
        amount: installment.amount,
        paidAmount,
        currency,
        status,
        cancelledReason: cancelled ? (existingData?.cancelledReason ?? null) : null,
        updatedAt: now,
        updatedBy: uid,
        version: FieldValue.increment(1),
        createdAt: existing.exists ? undefined : now,
        createdBy: existing.exists ? undefined : uid,
      };
      if (existing.exists) {
        delete data.createdAt;
        delete data.createdBy;
      }
      transaction.set(ref, data, { merge: true });
    });

    const invoiceStatus = computeInvoiceStatus(receivableStatuses);
    const invoiceData: DocumentData = {
      organizationId,
      companyId,
      customerId,
      orderId,
      sellerId,
      externalId,
      source,
      currency,
      totalAmount,
      issueDate,
      status: invoiceStatus,
      updatedAt: now,
      updatedBy: uid,
      version: FieldValue.increment(1),
      createdAt: invoiceSnapshot.exists ? undefined : now,
      createdBy: invoiceSnapshot.exists ? undefined : uid,
    };
    if (invoiceSnapshot.exists) {
      delete invoiceData.createdAt;
      delete invoiceData.createdBy;
    }
    transaction.set(invoiceRef, invoiceData, { merge: true });

    return {
      correlationId,
      invoiceId,
      receivableIds,
      status: invoiceStatus,
    };
  });

  logger.info('importReceivableInvoice succeeded', {
    correlationId,
    organizationId,
    customerId,
    invoiceId: result.invoiceId,
    uid,
    durationMs: Date.now() - startedAt,
  });

  return result;
});

function normalizeInstallment(
  raw: unknown,
  index: number,
): { externalId: string | null; installmentNumber: number; dueDate: Timestamp; amount: number } {
  const data = raw as Record<string, unknown> | null;
  if (!data || typeof data !== 'object') {
    throw new HttpsError('invalid-argument', `installments[${index}] is invalid.`);
  }
  const installmentNumber =
    typeof data.installmentNumber === 'number' && Number.isInteger(data.installmentNumber)
      ? data.installmentNumber
      : index + 1;
  return {
    externalId: optionalString(data.externalId) ?? null,
    installmentNumber,
    dueDate: parseRequiredDate(data.dueDate, `installments[${index}].dueDate`),
    amount: normalizePositiveMoney(data.amount, `installments[${index}].amount`),
  };
}

function parseRequiredDate(value: unknown, field: string): Timestamp {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    throw new HttpsError('invalid-argument', `${field} must be a valid ISO date.`);
  }
  return Timestamp.fromDate(parsed);
}
