import { HttpsError } from 'firebase-functions/v2/https';
import type { DocumentReference, Timestamp, Transaction } from 'firebase-admin/firestore';

/**
 * Every event type a pedido's pós-venda timeline (TASK-201, EPIC-30) may ever
 * carry. The first six are only ever written by `registerPostSaleEvent`
 * (registro manual by vendedor/suporte); the remaining four are only ever
 * written by `createReturnRequest`/`resolveReturnRequest`/
 * `createExchangeRequest`/`resolveExchangeRequest` (TASK-199/TASK-200,
 * EPIC-30) themselves — reusing the very same devolução/troca models instead
 * of duplicating their own modelagem (`tasks.md`: "Vincular devoluções/
 * trocas... como eventos na mesma timeline, para visão única de pós-venda do
 * pedido"). Every event is immutable once written — no Cloud Function in this
 * codebase ever updates a `postSaleEvents` document, only creates new ones
 * (`tasks.md`: "histórico não é editado, apenas complementado com novos
 * eventos").
 */
export const MANUAL_POST_SALE_EVENT_TYPES = [
  'dispatched',
  'in_transit',
  'delivered',
  'problem_reported',
  'in_resolution',
  'resolved',
] as const;

export const SYSTEM_POST_SALE_EVENT_TYPES = [
  'return_requested',
  'return_resolved',
  'exchange_requested',
  'exchange_resolved',
] as const;

export const POST_SALE_EVENT_TYPES = [
  ...MANUAL_POST_SALE_EVENT_TYPES,
  ...SYSTEM_POST_SALE_EVENT_TYPES,
] as const;

export type ManualPostSaleEventType = (typeof MANUAL_POST_SALE_EVENT_TYPES)[number];
export type SystemPostSaleEventType = (typeof SYSTEM_POST_SALE_EVENT_TYPES)[number];
export type PostSaleEventType = ManualPostSaleEventType | SystemPostSaleEventType;

const MANUAL_TYPE_SET: ReadonlySet<string> = new Set<string>(MANUAL_POST_SALE_EVENT_TYPES);

/** Milestones relevant enough to notify the pedido's own vendedor
 * (`tasks.md`/TASK-201: "Notificações... para o vendedor a cada marco
 * relevante (entregue, problema reportado)") — `dispatched`/`in_transit`/
 * `in_resolution` are deliberately excluded, same "not every intermediate
 * status change deserves a push" precedent every other notification
 * generator in this codebase already follows (only terminal/urgent
 * milestones do, e.g. `enqueueApprovalNotifications`). A devolução/troca
 * solicitada ou decidida always notifies — both are always relevant to the
 * vendedor responsável, regardless of the decision's outcome. */
const SELLER_NOTIFIABLE_TYPES: ReadonlySet<string> = new Set<string>([
  'delivered',
  'problem_reported',
  'resolved',
  'return_requested',
  'return_resolved',
  'exchange_requested',
  'exchange_resolved',
]);

export const MAX_POST_SALE_DESCRIPTION_LENGTH = 1000;

export function requireManualPostSaleEventType(value: unknown): ManualPostSaleEventType {
  if (typeof value !== 'string' || !MANUAL_TYPE_SET.has(value)) {
    throw new HttpsError(
      'invalid-argument',
      'type deve ser um dos marcos manuais de pós-venda (despachado, em trânsito, ' +
        'entregue, problema reportado, em resolução ou resolvido).',
    );
  }
  return value as ManualPostSaleEventType;
}

/** Validates/normalizes [value] as this event's [type] own `description`
 * (`tasks.md`/TASK-201: "Registro manual de problema exige descrição mínima
 * obrigatória (nunca um evento vazio de 'problema')") — mandatory (non-empty
 * after trim) only for `problem_reported`; optional, but still bounded, for
 * every other manual type. Returns `null` (never an empty string) when no
 * description was provided for a type that does not require one. */
export function requirePostSaleDescription(
  type: PostSaleEventType,
  value: unknown,
): string | null {
  const normalized = typeof value === 'string' ? value.trim() : '';
  if (type === 'problem_reported' && normalized.length === 0) {
    throw new HttpsError(
      'invalid-argument',
      'Um problema reportado exige uma descrição — nunca um evento vazio.',
    );
  }
  if (normalized.length > MAX_POST_SALE_DESCRIPTION_LENGTH) {
    throw new HttpsError(
      'invalid-argument',
      `description must stay under ${MAX_POST_SALE_DESCRIPTION_LENGTH} characters.`,
    );
  }
  return normalized.length > 0 ? normalized : null;
}

/** Pedido statuses a pós-venda event may ever be registered against
 * (TASK-201) — a bit wider than `RETURN_ELIGIBLE_ORDER_STATUSES`
 * (`returns/return-shared.ts`): tracking "despachado"/"em trânsito" may
 * start as soon as separação/expedição begins (`processing`), before the
 * pedido is even faturado. A `draft`/`pendingSync`/`submitted`/
 * `underReview`/`approved`/`rejected`/`cancelled` pedido has no pós-venda
 * life yet (or ever, for a `cancelled` one). */
export const POST_SALE_EVENT_ELIGIBLE_ORDER_STATUSES: ReadonlySet<string> = new Set<string>([
  'processing',
  'invoiced',
  'partially_invoiced',
  'shipped',
  'delivered',
  'partially_returned',
  'returned',
]);

export function isPostSaleEventEligibleOrderStatus(status: string): boolean {
  return POST_SALE_EVENT_ELIGIBLE_ORDER_STATUSES.has(status);
}

export interface AppendPostSaleEventInput {
  eventRef: DocumentReference;
  organizationId: string;
  companyId: string;
  orderId: string;
  orderNumber: string | null;
  customerId: string;
  sellerId: string;
  type: PostSaleEventType;
  description: string | null;
  source: 'manual' | 'system';
  sourceRequestId: string | null;
  createdBy: string;
  createdByName: string;
  now: Timestamp;
}

/**
 * Writes one immutable `postSaleEvents` document (never updated afterwards,
 * TASK-201) and, when [AppendPostSaleEventInput.type] is one of the
 * milestones {@link SELLER_NOTIFIABLE_TYPES} tracks, an accompanying internal
 * notification (`organizations/{organizationId}/notifications/{id}`,
 * TASK-151) addressed to the pedido's own vendedor — same direct
 * "write inside this same transaction, `deliverAt: now`" shape
 * `enqueueApprovalNotifications` (`orders/approval-chain.ts`) already
 * establishes for a real-time user action, not the quiet-hours-aware shape
 * `daily-rep-summary-notification.ts` uses for its own *scheduled/
 * background* generator.
 *
 * Shared by `registerPostSaleEvent` (registro manual) and by
 * `createReturnRequest`/`resolveReturnRequest`/`createExchangeRequest`/
 * `resolveExchangeRequest` (TASK-199/TASK-200) themselves, so a devolução/
 * troca solicitada/decidida is automatically linked into this exact same
 * timeline instead of a second, independently-drifting integration.
 */
export function appendPostSaleEvent(
  transaction: Transaction,
  organizationRef: DocumentReference,
  input: AppendPostSaleEventInput,
): void {
  const notifySeller = SELLER_NOTIFIABLE_TYPES.has(input.type);
  transaction.set(input.eventRef, {
    organizationId: input.organizationId,
    companyId: input.companyId,
    orderId: input.orderId,
    orderNumber: input.orderNumber,
    customerId: input.customerId,
    sellerId: input.sellerId,
    type: input.type,
    description: input.description,
    source: input.source,
    sourceRequestId: input.sourceRequestId,
    createdBy: input.createdBy,
    createdByName: input.createdByName,
    createdAt: input.now,
    notifiedSeller: notifySeller,
  });

  if (!notifySeller) return;
  transaction.set(organizationRef.collection('notifications').doc(), {
    organizationId: input.organizationId,
    userId: input.sellerId,
    category: 'commercial',
    title: postSaleEventNotificationTitle(input.type),
    body: postSaleEventNotificationBody(input),
    // Mirrors `OrderHistoryRoute.location` (`lib/core/navigation/app_route_paths.dart`)
    // — the pós-venda timeline (TASK-201) lives embedded in that same
    // screen. Kept as a plain literal (this Cloud Function cannot import
    // Dart route classes); update both if that route's `pathPattern` ever
    // changes.
    deepLink:
      `/org/${input.organizationId}/companies/${input.companyId}` +
      `/orders/${input.orderId}/history`,
    metadata: {
      companyId: input.companyId,
      orderId: input.orderId,
      orderNumber: input.orderNumber,
      postSaleEventType: input.type,
    },
    readAt: null,
    deliverAt: input.now,
    createdAt: input.now,
    createdBy: input.createdBy,
  });
}

function postSaleEventNotificationTitle(type: PostSaleEventType): string {
  switch (type) {
    case 'delivered':
      return 'Pedido entregue';
    case 'problem_reported':
      return 'Problema reportado no pós-venda';
    case 'resolved':
      return 'Problema de pós-venda resolvido';
    case 'return_requested':
      return 'Devolução solicitada';
    case 'return_resolved':
      return 'Devolução decidida';
    case 'exchange_requested':
      return 'Troca solicitada';
    case 'exchange_resolved':
      return 'Troca decidida';
    default:
      return 'Atualização de pós-venda';
  }
}

function postSaleEventNotificationBody(input: AppendPostSaleEventInput): string {
  const orderLabel = input.orderNumber ? `Pedido ${input.orderNumber}` : 'O pedido';
  return input.description
    ? `${orderLabel}: ${input.description}`
    : `${orderLabel} teve uma atualização de pós-venda.`;
}
