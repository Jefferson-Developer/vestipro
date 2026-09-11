import { createHash } from 'node:crypto';

import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import {
  loadActiveMembership,
  requireNonEmptyString as requireNonEmptyStringShared,
  resolveActorName,
} from '../invites/invite-shared';
import { optionalString } from '../pricing/calculate-pricing';
import {
  computeOutstandingAmount,
  computeReceivableStatus,
  mapReceivable,
  normalizePositiveMoney,
  requireInvoiceSource,
  requireNonEmptyString,
} from './receivables-shared';

/**
 * Same "quem pode gerir cobrança financeira" boundary as
 * `import-invoice.ts`'s `ROLES_ALLOWED_TO_IMPORT_INVOICE` — a payment
 * applied by anyone else (SALES_REP/SALES_MANAGER/SALES_ASSISTANT) would let
 * a seller unilaterally mark a customer's título as paid, exactly what
 * `tasks.md`'s "a UI nunca marca fatura como paga sem confirmação de
 * gateway, ERP ou usuário financeiro autorizado" forbids.
 */
const ROLES_ALLOWED_TO_REGISTER_PAYMENT: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'FINANCE',
]);

export interface RegisterPaymentAllocationRequest extends RequestWithMeta {
  organizationId?: string;
  receivableId?: string;
  amount?: number;
  source?: string;
  externalReference?: string;
  paymentTransactionId?: string;
  note?: string;
}

export interface RegisterPaymentAllocationResponse {
  correlationId: string;
  receivableId: string;
  allocationId: string;
  status: string;
  outstandingAmount: number;
  alreadyApplied: boolean;
}

/**
 * Applies one payment/estorno to a `Receivable`, always as an event — never
 * a blind overwrite of `paidAmount` — so a retried webhook/duplicate manual
 * submission is ignored idempotently (TASK-213: "parcela/fatura duplicada
 * por retry de webhook ou importação deve ser ignorada de forma
 * idempotente"). [externalReference] is the idempotency key: the gateway's
 * own transaction/event id for `source: 'gateway'|'erp'`, or a
 * caller-supplied reference (e.g. `manual:{uuid}`) for a FINANCE user
 * confirming a payment by hand. Mirrors `handlePaymentWebhook`'s own
 * "check-then-write inside the same transaction" idempotency shape
 * (`payments/handle-payment-webhook.ts`), applied here to a `Receivable`
 * instead of a checkout `PaymentTransaction`.
 */
export const registerPaymentAllocation = onCall<
  RegisterPaymentAllocationRequest,
  Promise<RegisterPaymentAllocationResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyStringShared(request.data?.organizationId, 'organizationId');
  const receivableId = requireNonEmptyStringShared(request.data?.receivableId, 'receivableId');
  const amount = normalizePositiveMoney(request.data?.amount, 'amount');
  const source = requireInvoiceSource(request.data?.source);
  const externalReference = requireNonEmptyString(request.data?.externalReference, 'externalReference');
  const paymentTransactionId = optionalString(request.data?.paymentTransactionId) ?? null;
  const note = optionalString(request.data?.note) ?? null;

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (!ROLES_ALLOWED_TO_REGISTER_PAYMENT.has(membership.roleName)) {
    throw new HttpsError('permission-denied', 'Seu perfil não pode registrar pagamentos.');
  }
  const actorName = await resolveActorName(db, uid, request.auth.token);

  const organizationRef = db.collection('organizations').doc(organizationId);
  const eventId = createHash('sha256').update(`${organizationId}:${externalReference}`).digest('hex');
  const eventRef = organizationRef.collection('paymentAllocationEvents').doc(eventId);
  const receivableRef = organizationRef.collection('receivables').doc(receivableId);

  const result = await db.runTransaction<RegisterPaymentAllocationResponse>(async (transaction) => {
    const eventSnapshot = await transaction.get(eventRef);
    if (eventSnapshot.exists) {
      const eventData = eventSnapshot.data();
      const receivableSnapshot = await transaction.get(receivableRef);
      const receivable = mapReceivable(receivableId, receivableSnapshot.data());
      return {
        correlationId,
        receivableId,
        allocationId: (eventData?.allocationId as string) ?? eventId,
        status: receivable.status,
        outstandingAmount: computeOutstandingAmount(receivable),
        alreadyApplied: true,
      };
    }

    const receivableSnapshot = await transaction.get(receivableRef);
    if (!receivableSnapshot.exists) {
      throw new HttpsError('not-found', 'Título a receber não encontrado.');
    }
    const receivable = mapReceivable(receivableId, receivableSnapshot.data());
    if (receivable.organizationId !== organizationId) {
      throw new HttpsError('not-found', 'Título a receber não encontrado.');
    }
    if (receivable.status === 'cancelled') {
      throw new HttpsError('failed-precondition', 'Este título foi cancelado/estornado.');
    }
    const outstanding = computeOutstandingAmount(receivable);
    if (amount - outstanding > 0.01) {
      throw new HttpsError(
        'failed-precondition',
        'O valor do pagamento excede o saldo em aberto deste título.',
      );
    }

    const now = Timestamp.now();
    const newPaidAmount = Math.min(receivable.paidAmount + amount, receivable.amount);
    const newStatus = computeReceivableStatus({
      amount: receivable.amount,
      paidAmount: newPaidAmount,
      dueDate: receivable.dueDate,
      cancelled: false,
      now,
    });

    const allocationRef = organizationRef.collection('paymentAllocations').doc();
    transaction.set(allocationRef, {
      organizationId,
      receivableId,
      invoiceId: receivable.invoiceId,
      customerId: receivable.customerId,
      amount,
      source,
      externalReference,
      paymentTransactionId,
      note,
      registeredBy: uid,
      registeredByName: actorName,
      registeredAt: now,
    });

    transaction.set(eventRef, {
      organizationId,
      receivableId,
      allocationId: allocationRef.id,
      externalReference,
      registeredAt: now,
    });

    transaction.set(
      receivableRef,
      {
        paidAmount: newPaidAmount,
        status: newStatus,
        updatedAt: now,
        updatedBy: uid,
        version: FieldValue.increment(1),
      },
      { merge: true },
    );

    return {
      correlationId,
      receivableId,
      allocationId: allocationRef.id,
      status: newStatus,
      outstandingAmount: computeOutstandingAmount({ amount: receivable.amount, paidAmount: newPaidAmount }),
      alreadyApplied: false,
    };
  });

  logger.info('registerPaymentAllocation succeeded', {
    correlationId,
    organizationId,
    receivableId,
    uid,
    alreadyApplied: result.alreadyApplied,
    durationMs: Date.now() - startedAt,
  });

  return result;
});
