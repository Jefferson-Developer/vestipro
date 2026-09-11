import { createHash } from 'node:crypto';

import { HttpsError } from 'firebase-functions/v2/https';
import { Timestamp, type DocumentData } from 'firebase-admin/firestore';

import { optionalString } from '../pricing/calculate-pricing';

/**
 * TASK-213 (EPIC-32) — contas a receber, faturas e lembretes de cobrança.
 *
 * Three entities, exactly as `tasks.md` requests: an [Invoice] (fatura, the
 * ERP/gateway-issued billing document tied to an `Order`), a [Receivable]
 * (parcela/título — one installment of an `Invoice`, the row aging/status is
 * actually tracked against) and a [PaymentAllocation] (one payment/estorno
 * applied to a `Receivable`, always an auditable event, never a silent
 * overwrite). Mirrors the exact shape TASK-212's `credit-shared.ts` already
 * established for this same "pure model + pure decision function, mapped
 * from/to Firestore by the callables" split.
 */

export type ReceivableStatus =
  | 'open'
  | 'overdue'
  | 'partially_paid'
  | 'paid'
  | 'cancelled';

export type InvoiceSource = 'erp' | 'gateway' | 'manual';

export type AgingBucket = 'current' | 'd1_30' | 'd31_60' | 'd61_90' | 'd90_plus';

export interface Invoice {
  id: string;
  organizationId: string;
  companyId: string;
  customerId: string;
  orderId: string | null;
  sellerId: string | null;
  externalId: string;
  source: InvoiceSource;
  currency: string;
  totalAmount: number;
  issueDate: Timestamp;
  status: ReceivableStatus;
  version: number;
}

export interface Receivable {
  id: string;
  organizationId: string;
  companyId: string;
  customerId: string;
  invoiceId: string;
  orderId: string | null;
  sellerId: string | null;
  externalId: string | null;
  installmentNumber: number;
  dueDate: Timestamp;
  amount: number;
  paidAmount: number;
  currency: string;
  status: ReceivableStatus;
  cancelledReason: string | null;
  version: number;
}

export interface PaymentAllocation {
  id: string;
  organizationId: string;
  receivableId: string;
  invoiceId: string;
  customerId: string;
  amount: number;
  source: InvoiceSource;
  externalReference: string;
  paymentTransactionId: string | null;
  note: string | null;
  registeredBy: string;
  registeredByName: string;
  registeredAt: Timestamp;
}

/** A receivable due within this many days (but not yet overdue) is
 * classified `dueSoon` by [classifyReceivableReminder] — advisory only, never
 * a stored [ReceivableStatus] value (`tasks.md` only enumerates the 5 above
 * for the persisted status; "vence em breve" is a reminder-only concept,
 * mirrors `CrmReminderSettings.dueSoonWindow`'s own "advisory, not a stored
 * state" precedent). */
export const RECEIVABLE_DUE_SOON_WINDOW_DAYS = 3;

const VALID_SOURCES: ReadonlySet<string> = new Set<string>(['erp', 'gateway', 'manual']);

export function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return value.trim();
}

export function normalizeMoney(value: unknown, field: string): number {
  if (typeof value !== 'number' || Number.isNaN(value) || value < 0) {
    throw new HttpsError('invalid-argument', `${field} must be zero or greater.`);
  }
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

export function normalizePositiveMoney(value: unknown, field: string): number {
  const amount = normalizeMoney(value, field);
  if (amount <= 0) {
    throw new HttpsError('invalid-argument', `${field} must be greater than zero.`);
  }
  return amount;
}

export function normalizeCurrencyCode(value: unknown): string {
  const code = requireNonEmptyString(value, 'currency').toUpperCase();
  if (!/^[A-Z]{3}$/.test(code)) {
    throw new HttpsError('invalid-argument', 'currency must be an ISO 4217 code.');
  }
  return code;
}

export function requireInvoiceSource(value: unknown): InvoiceSource {
  const source = requireNonEmptyString(value, 'source');
  if (!VALID_SOURCES.has(source)) {
    throw new HttpsError('invalid-argument', 'source must be one of: erp, gateway, manual.');
  }
  return source as InvoiceSource;
}

/**
 * Deterministic Firestore document id for an externally-identified entity
 * (an `Invoice`/`Receivable` imported from an ERP/gateway) — the same
 * `externalId` (scoped by [namespace], so an invoice and one of its own
 * installments never collide even if an ERP happens to reuse the same raw
 * number) always resolves to the same doc id, which is what makes
 * `importReceivableInvoice` idempotent by construction: re-importing the
 * same fatura/parcela is a `set`/merge onto the exact same document, never a
 * duplicate. Mirrors `computePaymentTransactionId` (`payment-shared.ts`).
 */
export function computeExternalEntityId(
  organizationId: string,
  namespace: 'invoice' | 'receivable',
  externalId: string,
): string {
  return createHash('sha256').update(`${namespace}:${organizationId}:${externalId}`).digest('hex');
}

/**
 * Core, side-effect-free classification (TASK-213: "aberta, vencida,
 * parcialmente paga, paga, estornada/cancelada"). Checked in this exact
 * order — `cancelled` always wins (a cancelled título is never "paid" again
 * even if [paidAmount] happens to already cover it), then `paid`, then
 * `partially_paid` (even when also overdue: a título with money on it is
 * never shown as a plain `overdue` — the partial payment is exactly the
 * detail collections needs to see), then `overdue`, else `open`.
 */
export function computeReceivableStatus(params: {
  amount: number;
  paidAmount: number;
  dueDate: Timestamp;
  cancelled: boolean;
  now: Timestamp;
}): ReceivableStatus {
  if (params.cancelled) return 'cancelled';
  if (params.paidAmount >= params.amount) return 'paid';
  if (params.paidAmount > 0) return 'partially_paid';
  if (params.dueDate.toMillis() < params.now.toMillis()) return 'overdue';
  return 'open';
}

/** Never negative — a receivable can never owe less than nothing even if a
 * data-entry mistake let [Receivable.paidAmount] exceed [Receivable.amount]. */
export function computeOutstandingAmount(receivable: Pick<Receivable, 'amount' | 'paidAmount'>): number {
  return Math.max(receivable.amount - receivable.paidAmount, 0);
}

/**
 * Aging bucket (TASK-213's own "aging resumido") for a receivable that still
 * carries an outstanding balance — meaningless (always `current`) for a
 * `paid`/`cancelled` receivable, since there is nothing left to age.
 */
export function computeAgingBucket(
  receivable: Pick<Receivable, 'dueDate' | 'status'>,
  now: Timestamp,
): AgingBucket {
  if (receivable.status === 'paid' || receivable.status === 'cancelled') return 'current';
  const daysPastDue = Math.floor(
    (now.toMillis() - receivable.dueDate.toMillis()) / (24 * 60 * 60 * 1000),
  );
  if (daysPastDue <= 0) return 'current';
  if (daysPastDue <= 30) return 'd1_30';
  if (daysPastDue <= 60) return 'd31_60';
  if (daysPastDue <= 90) return 'd61_90';
  return 'd90_plus';
}

/**
 * Aggregates an `Invoice`'s own status from its `Receivable`s (installments):
 * `cancelled` only when every installment is cancelled, `paid` only when
 * every non-cancelled installment is paid, `overdue`/`partially_paid` when
 * any installment carries that status, `open` otherwise. An invoice with no
 * receivables at all (should not normally happen — `importReceivableInvoice`
 * always writes at least one) defaults to `open`.
 */
export function computeInvoiceStatus(receivables: readonly ReceivableStatus[]): ReceivableStatus {
  if (receivables.length === 0) return 'open';
  const relevant = receivables.filter((status) => status !== 'cancelled');
  if (relevant.length === 0) return 'cancelled';
  if (relevant.every((status) => status === 'paid')) return 'paid';
  if (relevant.some((status) => status === 'overdue')) return 'overdue';
  if (relevant.some((status) => status === 'partially_paid')) return 'partially_paid';
  return 'open';
}

/** Advisory-only reminder classification (never persisted) — see
 * [RECEIVABLE_DUE_SOON_WINDOW_DAYS]'s own doc. `cancelled`/`paid` receivables
 * never warrant a reminder. */
export type ReceivableReminderClassification = 'none' | 'dueSoon' | 'overdue';

export function classifyReceivableReminder(
  receivable: Pick<Receivable, 'status' | 'dueDate'>,
  now: Timestamp,
): ReceivableReminderClassification {
  if (receivable.status === 'paid' || receivable.status === 'cancelled') return 'none';
  if (receivable.status === 'overdue') return 'overdue';
  const daysUntilDue = Math.ceil(
    (receivable.dueDate.toMillis() - now.toMillis()) / (24 * 60 * 60 * 1000),
  );
  if (daysUntilDue >= 0 && daysUntilDue <= RECEIVABLE_DUE_SOON_WINDOW_DAYS) return 'dueSoon';
  return 'none';
}

/** Masked (no monetary figures) billing status — the exact same
 * "vendedor/gestor enxerga o status acionável sem acessar dado financeiro
 * sensível" split `credit-shared.ts`'s `CreditEvaluationStatus` already
 * established for TASK-212. */
export type BillingStatus = 'up_to_date' | 'has_open' | 'has_overdue';

export function computeBillingStatus(receivables: readonly ReceivableStatus[]): BillingStatus {
  if (receivables.some((status) => status === 'overdue')) return 'has_overdue';
  if (receivables.some((status) => status === 'open' || status === 'partially_paid')) {
    return 'has_open';
  }
  return 'up_to_date';
}

export function describeBillingStatus(status: BillingStatus): string {
  switch (status) {
    case 'up_to_date':
      return 'Nenhuma fatura em aberto para este cliente.';
    case 'has_open':
      return 'Este cliente possui fatura(s) em aberto, ainda dentro do prazo.';
    case 'has_overdue':
      return 'Este cliente possui fatura(s) vencida(s). Priorize o contato de cobrança.';
  }
}

export function mapInvoice(id: string, data: DocumentData | undefined): Invoice {
  if (!data) throw new HttpsError('failed-precondition', 'Invoice missing.');
  return {
    id,
    organizationId: optionalString(data.organizationId) ?? '',
    companyId: optionalString(data.companyId) ?? '',
    customerId: optionalString(data.customerId) ?? '',
    orderId: optionalString(data.orderId) ?? null,
    sellerId: optionalString(data.sellerId) ?? null,
    externalId: optionalString(data.externalId) ?? '',
    source: (optionalString(data.source) as InvoiceSource | undefined) ?? 'manual',
    currency: optionalString(data.currency) ?? 'BRL',
    totalAmount: asNumber(data.totalAmount),
    issueDate: data.issueDate instanceof Timestamp ? data.issueDate : Timestamp.now(),
    status: normalizeStatus(data.status),
    version: typeof data.version === 'number' ? data.version : 1,
  };
}

export function mapReceivable(id: string, data: DocumentData | undefined): Receivable {
  if (!data) throw new HttpsError('failed-precondition', 'Receivable missing.');
  return {
    id,
    organizationId: optionalString(data.organizationId) ?? '',
    companyId: optionalString(data.companyId) ?? '',
    customerId: optionalString(data.customerId) ?? '',
    invoiceId: optionalString(data.invoiceId) ?? '',
    orderId: optionalString(data.orderId) ?? null,
    sellerId: optionalString(data.sellerId) ?? null,
    externalId: optionalString(data.externalId) ?? null,
    installmentNumber: typeof data.installmentNumber === 'number' ? data.installmentNumber : 1,
    dueDate: data.dueDate instanceof Timestamp ? data.dueDate : Timestamp.now(),
    amount: asNumber(data.amount),
    paidAmount: asNumber(data.paidAmount),
    currency: optionalString(data.currency) ?? 'BRL',
    status: normalizeStatus(data.status),
    cancelledReason: optionalString(data.cancelledReason) ?? null,
    version: typeof data.version === 'number' ? data.version : 1,
  };
}

function normalizeStatus(value: unknown): ReceivableStatus {
  return value === 'overdue' ||
    value === 'partially_paid' ||
    value === 'paid' ||
    value === 'cancelled'
    ? value
    : 'open';
}

function asNumber(value: unknown): number {
  return typeof value === 'number' && !Number.isNaN(value) ? value : 0;
}
