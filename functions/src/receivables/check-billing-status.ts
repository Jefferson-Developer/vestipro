import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import { optionalString } from '../pricing/calculate-pricing';
import {
  computeAgingBucket,
  computeOutstandingAmount,
  computeBillingStatus,
  describeBillingStatus,
  mapReceivable,
  type AgingBucket,
  type BillingStatus,
} from './receivables-shared';

/**
 * Same financial-visibility boundary as TASK-212's `validateOrderCredit`
 * (`ROLES_WITH_FINANCIAL_VISIBILITY`) — raw fatura amounts/aging only ever
 * reach OWNER/ADMIN/FINANCE; every other role (SALES_REP, SALES_MANAGER
 * included — `SALES_MANAGER` holds `report.viewSensitive` but not
 * `finance.view`, same precedent) only ever gets [status]/[message].
 */
const ROLES_WITH_FINANCIAL_VISIBILITY: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'FINANCE',
]);

export interface CheckBillingStatusRequest extends RequestWithMeta {
  organizationId?: string;
  customerId?: string;
  orderId?: string;
}

export interface CheckBillingStatusSensitiveReceivable {
  id: string;
  invoiceId: string;
  installmentNumber: number;
  dueDate: string;
  amount: number;
  paidAmount: number;
  outstandingAmount: number;
  currency: string;
  status: string;
  agingBucket: AgingBucket;
}

export interface CheckBillingStatusSensitiveDetail {
  openTotal: number;
  overdueTotal: number;
  receivables: CheckBillingStatusSensitiveReceivable[];
}

export interface CheckBillingStatusResponse {
  correlationId: string;
  status: BillingStatus;
  message: string;
  sensitive: CheckBillingStatusSensitiveDetail | null;
}

/**
 * Read-only preview of a customer's (optionally, one order's) situação
 * financeira — callable by any active member, mirrors `validateOrderCredit`'s
 * "single endpoint, server decides how much detail this caller gets" shape.
 * When [orderId] is provided, both the masked status and the sensitive
 * detail are scoped to that pedido's own receivables only; omitted, they
 * cover every receivable the customer has (TASK-213's cliente 360º view).
 */
export const checkBillingStatus = onCall<
  CheckBillingStatusRequest,
  Promise<CheckBillingStatusResponse>
>(async (request) => {
  const startedAt = Date.now();
  const correlationId = resolveCorrelationId(request.data?._meta);

  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const customerId = requireNonEmptyString(request.data?.customerId, 'customerId');
  const orderId = optionalString(request.data?.orderId);

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);

  let query = db
    .collection('organizations')
    .doc(organizationId)
    .collection('receivables')
    .where('customerId', '==', customerId);
  if (orderId) {
    query = query.where('orderId', '==', orderId);
  }
  const snapshot = await query.get();
  const receivables = snapshot.docs.map((doc) => mapReceivable(doc.id, doc.data()));
  const relevant = receivables.filter((receivable) => receivable.status !== 'cancelled');

  const status = computeBillingStatus(relevant.map((receivable) => receivable.status));
  const message = describeBillingStatus(status);

  const now = Timestamp.now();
  const sensitive = ROLES_WITH_FINANCIAL_VISIBILITY.has(membership.roleName)
    ? buildSensitiveDetail(relevant, now)
    : null;

  logger.info('checkBillingStatus resolved', {
    correlationId,
    organizationId,
    customerId,
    orderId: orderId ?? null,
    uid,
    status,
    durationMs: Date.now() - startedAt,
  });

  return { correlationId, status, message, sensitive };
});

function buildSensitiveDetail(
  receivables: ReturnType<typeof mapReceivable>[],
  now: Timestamp,
): CheckBillingStatusSensitiveDetail {
  let openTotal = 0;
  let overdueTotal = 0;
  const rows: CheckBillingStatusSensitiveReceivable[] = receivables
    .filter((receivable) => receivable.status !== 'paid')
    .map((receivable) => {
      const outstanding = computeOutstandingAmount(receivable);
      openTotal += outstanding;
      if (receivable.status === 'overdue') overdueTotal += outstanding;
      return {
        id: receivable.id,
        invoiceId: receivable.invoiceId,
        installmentNumber: receivable.installmentNumber,
        dueDate: receivable.dueDate.toDate().toISOString(),
        amount: receivable.amount,
        paidAmount: receivable.paidAmount,
        outstandingAmount: outstanding,
        currency: receivable.currency,
        status: receivable.status,
        agingBucket: computeAgingBucket(receivable, now),
      };
    })
    .sort((left, right) => left.dueDate.localeCompare(right.dueDate));

  return {
    openTotal: round2(openTotal),
    overdueTotal: round2(overdueTotal),
    receivables: rows,
  };
}

function round2(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}
