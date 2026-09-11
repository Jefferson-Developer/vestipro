import { HttpsError } from 'firebase-functions/v2/https';
import type { DocumentData, DocumentReference, Transaction } from 'firebase-admin/firestore';

import {
  ensureRequesterMayActOnOrder,
  mapReturnRequestOrder,
  normalizeTeamIds,
  optionalString,
  requireString,
  type ReturnRequestOrder,
} from '../returns/return-shared';
import { computeSellableQuantity, type InventoryBalanceSnapshot } from '../inventory/stock-reservation-shared';

export { ensureRequesterMayActOnOrder, mapReturnRequestOrder, normalizeTeamIds, optionalString, requireString };

// ---------------------------------------------------------------------------
// Enumerations (TASK-215, EPIC-32 — backorder e solicitação de estoque
// futuro). Every code below is the exact string persisted in Firestore and
// mirrored 1:1 by the Dart value objects under
// `lib/features/backorder/domain/value_objects/`.
// ---------------------------------------------------------------------------

export type BackorderOrigin = 'catalog' | 'order' | 'pre_book' | 'manual';

const BACKORDER_ORIGINS: ReadonlySet<string> = new Set<string>([
  'catalog',
  'order',
  'pre_book',
  'manual',
]);

export type BackorderPriority = 'low' | 'normal' | 'high' | 'urgent';

const BACKORDER_PRIORITIES: ReadonlySet<string> = new Set<string>([
  'low',
  'normal',
  'high',
  'urgent',
]);

/** Ordering weight used to build the atendimento queue (`priorityWeight`,
 * persisted alongside `status`/`createdAt` so the Dart `BackorderQueueCubit`
 * can sort with a single Firestore `orderBy` per field, no client-only
 * comparator needed — TASK-215: "fila... priorizada por cliente, data, valor
 * potencial, segmento ou política comercial"). Deliberately a small, dense
 * integer table (not `estimatedTotalValue` itself): a manually-escalated
 * `urgent` request must always outrank a merely bigger-ticket `normal` one. */
export function priorityWeight(priority: BackorderPriority): number {
  switch (priority) {
    case 'urgent':
      return 3;
    case 'high':
      return 2;
    case 'normal':
      return 1;
    case 'low':
      return 0;
  }
}

/** Every status a `BackorderRequest` document may carry (TASK-215). `queued`
 * is the only status the stock-availability watcher
 * (`notifyBackordersOnStockAvailable`) ever promotes into `ready_to_fulfill`
 * — `awaiting_approval` must clear `decideBackorderApproval` first. Every
 * other terminal value (`converted`/`rejected`/`cancelled`) is final: no
 * Function in this feature ever writes a transition out of one of them. */
export type BackorderStatus =
  | 'requested'
  | 'awaiting_approval'
  | 'queued'
  | 'ready_to_fulfill'
  | 'converted'
  | 'rejected'
  | 'cancelled';

/** Statuses still "in flight" — never yet converted/rejected/cancelled — the
 * only ones `cancelBackorderRequest`/`notifyBackordersOnStockAvailable` ever
 * act upon. */
export const OPEN_BACKORDER_STATUSES: ReadonlySet<BackorderStatus> = new Set<BackorderStatus>([
  'requested',
  'awaiting_approval',
  'queued',
  'ready_to_fulfill',
]);

/** Statuses eligible for the atendimento queue proper (already cleared any
 * required approval) — `awaiting_approval` is deliberately excluded: it only
 * ever shows up in a separate "aguardando aprovação" inbox
 * (`BackorderQueueCubit`, Dart side), never mixed into the priorized
 * fulfillment queue itself. */
export const QUEUEABLE_BACKORDER_STATUSES: ReadonlySet<BackorderStatus> = new Set<BackorderStatus>([
  'queued',
  'ready_to_fulfill',
]);

export function requireBackorderOrigin(value: unknown): BackorderOrigin {
  if (typeof value !== 'string' || !BACKORDER_ORIGINS.has(value)) {
    throw new HttpsError('invalid-argument', 'origin deve ser uma origem de backorder válida.');
  }
  return value as BackorderOrigin;
}

export function requireBackorderPriority(value: unknown): BackorderPriority {
  if (value === undefined || value === null) return 'normal';
  if (typeof value !== 'string' || !BACKORDER_PRIORITIES.has(value)) {
    throw new HttpsError('invalid-argument', 'priority deve ser uma prioridade de backorder válida.');
  }
  return value as BackorderPriority;
}

/** Only these roles may ever create/cancel a `BackorderRequest` (TASK-215)
 * — mirrors `fulfillment-shared.ts`'s own `ROLES_ALLOWED_TO_MANAGE_SHIPMENT`
 * shape: OWNER/ADMIN always; SALES_MANAGER/SALES_REP only for a customer/
 * pedido they may already act on; CUSTOMER_PORTAL only when the request is
 * tied to one of its own pedidos (`relatedOrderId`) — a standalone catálogo
 * backorder with no pedido behind it still requires an internal seller,
 * documented as this task's own "Pendências" scope decision. */
export const ROLES_ALLOWED_TO_REQUEST_BACKORDER: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
  'SALES_REP',
  'CUSTOMER_PORTAL',
]);

/** Only these roles may ever decide (approve/reject) a `BackorderRequest`
 * awaiting aprovação, or convert one into a pedido (TASK-215) — mirrors
 * `returnRequestApprove`'s own grant set: OWNER/ADMIN always;
 * SALES_MANAGER only for a customer/pedido their own team already carries. A
 * `SALES_REP` may request/cancel a backorder but never approve one for
 * itself, same asymmetry `orderApprove` already enforces for pedidos. */
export const ROLES_ALLOWED_TO_DECIDE_BACKORDER: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
]);

/** A `SALES_REP`/`SALES_MANAGER`/`OWNER`/`ADMIN` may also convert an already
 * `queued`/`ready_to_fulfill` backorder into a pedido once they have one
 * already submitted — same amplitude as [ROLES_ALLOWED_TO_REQUEST_BACKORDER]
 * minus the portal (a cliente never creates a pedido on its own behalf
 * through this callable). */
export const ROLES_ALLOWED_TO_CONVERT_BACKORDER: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
  'SALES_MANAGER',
  'SALES_REP',
]);

/** Quantity above which a new `BackorderRequest` may never auto-queue and
 * must instead wait for `decideBackorderApproval` (TASK-215: "Cliente/
 * vendedor não pode criar backorder acima de limites configurados sem
 * aprovação") — an organization may override this via its own
 * `backorderSettings.autoApproveMaxQuantity` field
 * (`resolveAutoApproveMaxQuantity`); this constant is only the fallback for
 * every organization that never configured one. There is no dedicated
 * settings screen yet to edit this value (documented as this task's
 * "Pendências"): today it is only ever changed by direct Firestore write
 * (OWNER/ADMIN via admin tooling), same bootstrap gap already accepted for a
 * handful of other organization-wide thresholds in this codebase (e.g.
 * `discountPolicies` before TASK-086 shipped its own UI). */
export const DEFAULT_BACKORDER_AUTO_APPROVE_MAX_QUANTITY = 20;

export function resolveAutoApproveMaxQuantity(organizationData: DocumentData | undefined): number {
  const configured = (organizationData?.backorderSettings as DocumentData | undefined)?.autoApproveMaxQuantity;
  if (typeof configured === 'number' && Number.isFinite(configured) && configured >= 0) {
    return configured;
  }
  return DEFAULT_BACKORDER_AUTO_APPROVE_MAX_QUANTITY;
}

export function requireOptionalBoundedString(
  value: unknown,
  field: string,
  maxLength: number,
): string | undefined {
  const normalized = optionalString(value);
  if (normalized && normalized.length > maxLength) {
    throw new HttpsError('invalid-argument', `${field} must stay under ${maxLength} characters.`);
  }
  return normalized;
}

export function requireBoundedString(value: unknown, field: string, maxLength: number): string {
  const normalized = requireString(value, field);
  if (normalized.length > maxLength) {
    throw new HttpsError('invalid-argument', `${field} must stay under ${maxLength} characters.`);
  }
  return normalized;
}

export function requireNonNegativeNumber(value: unknown, field: string): number {
  if (typeof value !== 'number' || Number.isNaN(value) || value < 0) {
    throw new HttpsError('invalid-argument', `${field} must be zero or greater.`);
  }
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

/**
 * Guards who may act (solicitar/cancelar um `BackorderRequest`, TASK-215) on
 * behalf of the given [sellerId]/[customerId] pair — deliberately generic
 * over "is there an order behind this or not": whenever [relatedOrder] is
 * provided, delegates entirely to `ensureRequesterMayActOnOrder` (TASK-199)
 * so a request tied to a pedido always follows the exact same "quem pode
 * agir neste pedido" rule every other pós-venda action already does; when it
 * is not (a standalone catálogo backorder), falls back to comparing directly
 * against [sellerId]/[customerId] instead.
 */
export async function ensureRequesterMayActOnBackorder(
  transaction: Transaction,
  organizationRef: DocumentReference,
  input: {
    roleName: string;
    uid: string;
    sellerId: string;
    customerId: string;
    portalCustomerId?: string;
    requesterTeamIds: string[];
    relatedOrder?: ReturnRequestOrder;
  },
): Promise<void> {
  if (input.relatedOrder) {
    await ensureRequesterMayActOnOrder(transaction, organizationRef, {
      roleName: input.roleName,
      uid: input.uid,
      order: input.relatedOrder,
      portalCustomerId: input.portalCustomerId,
      requesterTeamIds: input.requesterTeamIds,
    });
    return;
  }

  if (input.roleName === 'OWNER' || input.roleName === 'ADMIN') return;

  if (input.roleName === 'CUSTOMER_PORTAL') {
    if (input.portalCustomerId !== input.customerId) {
      throw new HttpsError('permission-denied', 'O portal só pode agir sobre os próprios dados.');
    }
    return;
  }

  if (input.roleName === 'SALES_REP') {
    if (input.sellerId !== input.uid) {
      throw new HttpsError(
        'permission-denied',
        'Este backorder só pode ser gerenciado pelo próprio vendedor responsável.',
      );
    }
    return;
  }

  if (input.roleName === 'SALES_MANAGER') {
    const sellerSnapshot = await transaction.get(organizationRef.collection('members').doc(input.sellerId));
    const sellerTeamIds = normalizeTeamIds(sellerSnapshot.data()?.teamIds);
    const sharesTeam = sellerTeamIds.some((teamId) => input.requesterTeamIds.includes(teamId));
    if (!sharesTeam) {
      throw new HttpsError('permission-denied', 'Você só pode agir sobre backorders da sua própria equipe.');
    }
    return;
  }

  throw new HttpsError('permission-denied', 'Seu perfil não pode realizar esta ação.');
}

/**
 * Total sellable quantity (`computeSellableQuantity`, TASK-090) of
 * [variantId] across every warehouse balance already tracked for it — the
 * same aggregate `convertQuoteToOrder`'s own `canFulfillAllItems` reads, used
 * here both to snapshot "estoque no momento da solicitação" (informational
 * only, TASK-215: "Backorder não reduz saldo de estoque atual nem garante
 * entrega") and, in `notifyBackordersOnStockAvailable`, to decide which
 * `queued` requests may be flagged `ready_to_fulfill`.
 */
export async function readTotalSellableQuantity(
  organizationRef: DocumentReference,
  variantId: string,
): Promise<number> {
  const snapshots = await organizationRef.collection('inventory').where('variantId', '==', variantId).get();
  return snapshots.docs.reduce((total, doc) => {
    const data = doc.data() as Partial<InventoryBalanceSnapshot>;
    return (
      total +
      computeSellableQuantity({
        physicalQuantity: typeof data.physicalQuantity === 'number' ? data.physicalQuantity : 0,
        reservedQuantity: typeof data.reservedQuantity === 'number' ? data.reservedQuantity : 0,
        blockedQuantity: typeof data.blockedQuantity === 'number' ? data.blockedQuantity : 0,
      })
    );
  }, 0);
}
